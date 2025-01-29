/*
 * CMixer.c
 *
 * This is an extremely basic example showing how the mixer.h file works.
 * For more complete examples, see the assembly examples provided.
 * 
 * Note: mixer configuration has to be done via the mixer_config.i file and
 *       the mixer.asm file has to be assembled into a linkable object prior
 *       to use in C programs.
 *	   
 * Note: this program does not disable the OS. Keep in mind this can cause
 *       instabilities considering the way the mixer works.
 *
 * Author: Jeroen Knoester
 * Version: 1.1
 * Revision: 20250129
 *
 * TAB size = 4 spaces
 */

/* Includes */
#include <stdio.h>
#include <stdlib.h>
#include <dos/dos.h>
#include <proto/dos.h>
#include <exec/exec.h>
#include <proto/exec.h>
#include <hardware/dmabits.h>
#include "mixer/mixer.h"
#include "plugins/plugins.h"

/* REGARG define to call assembly routines */
#if defined(__VBCC__)
#define MIX_REGARG(arg, reg) __reg(reg) arg
#elif defined(__GNUC__) // Bebbo
#define MIX_REGARG(arg, reg) arg asm(reg)
#endif

/* Global variable */
volatile long callback_output = 0;
volatile long test_handler_counter = 0;

/* Support functions */
char *LoadSample(char *filename, ULONG *size)
{
	FILE *file;
	int counter;
	signed char byte;
	signed char *sample;
	int file_size;
	int alloc_size;
	
	/* Open file and get sample size */
	file = fopen(filename,"r");
	if (file==NULL)
	{		
		printf ("Opening file %s failed\n",filename);
		return NULL;
	}
	fseek(file, 0L, SEEK_END);
	file_size=ftell(file);
	fseek(file, 0L, SEEK_SET);
	alloc_size=file_size&0xffffffc;
	alloc_size=alloc_size+4;
	printf ("%s size: %d (%d)\n",filename,file_size,alloc_size);
	
	/* Allocate memory for sample */
	sample = AllocMem(alloc_size, MEMF_ANY);
	if (sample==NULL)
	{
		printf ("Allocation for file %s failed\n",filename);
		fclose (file);
		return NULL;
	}
	
	/* Read sample data */
	if (fread(sample,file_size,1,file)==0)
	{
		printf ("Reading file %s failed\n",filename);
		FreeMem(sample,alloc_size);
		fclose (file);
		return NULL;
	}
	
	/* Pad to alloc_size to prevent clicks or pops */
	counter = file_size;
	while (counter < alloc_size)
	{
		sample[counter]=(signed char)0;
		counter++;
	}
	
	*size = alloc_size;
	
	fclose (file);	
	return sample;
}

void ConvertSample(signed char *sample, ULONG size, int voices)
{
	int counter;
	
	counter = 0;

	/* 
	 * Conversion of samples is a simple divide by the number of channels.
	 * However, there is one exception: when using 3 voices, the division
	 * results in a slightly uneven result where positive values are slightly
	 * higher than negative values.
	 *
	 * To compensate for this, each positive sample value will be reduced by 1
	 * in the case of 3 voice conversion
	 */
	if (voices==3)
	{
		while (counter < size)
		{
			if (sample[counter]>0)
			{
				sample[counter]=sample[counter]-1;
			}
			sample[counter]=sample[counter]/voices;
			counter++;
		}
	}
	else
	{
		while (counter < size)
		{
			sample[counter]=sample[counter]/voices;
			counter++;
		}
	}
}

/* Callback function */
ULONG callback_function(MIX_REGARG(APTR sample_pointer,"a0"),
                        MIX_REGARG(UWORD mixer_channel,"d0"))
{
	callback_output = (long)sample_pointer;
	return 0;
}

/* Vector handler function */
void test_function()
{
	test_handler_counter++;
	return;
}

/* Main program */
int main()
{
	ULONG buffer_size;
	ULONG plugin_buffer_size;
	ULONG plugin_data_size;
	ULONG mixer_total_channels;
	ULONG plugin_total_data_size;
	void *vbr=0;
	void *buffer=NULL;
	void *plugin_buffer=NULL;
	void *plugin_data=NULL;
	void *sample1=NULL,*sample2=NULL,*sample3=NULL,*sample4=NULL;
	ULONG sample1_size,sample2_size,sample3_size,sample4_size;
	MXEffect effect1, effect2, effect3, effect4;
	MXPlugin plugin;
	MXPDPitchInitData pitch_init_data;
	LONG current_callback_output = 0;
	char input[255];
	
	printf ("CMixer - example in C for using the Audio Mixer\n");
	printf ("-----------------------------------------------\n");
	printf ("\n");
	printf ("Note: this example is very short and does not close down the OS\n");
	printf ("      properly. The Audio Mixer directly accesses custom chip\n");
	printf ("      registers, closing down the OS properly prior to using the\n");
	printf ("      mixer is required in real programs.\n");
	printf ("Note: this program assumes a VBR of 0\n");
	printf ("\n");
	printf ("Samples used are sourced from freesound.org. See the readme file in the data\n");
	printf ("subdirectory of the mixer 'example' directory.\n");
	printf ("\n");
	
	/* Get buffer size to use */
	buffer_size=MixerGetBufferSize();
	printf ("Buffer size: %d\n",(int)buffer_size);
	
	/* Allocate Chip RAM buffer */
	buffer = AllocMem(buffer_size, MEMF_CHIP);
	if (buffer==NULL)
	{
		printf ("Chip RAM buffer allocation failed\n");
		return 5;
	}
	
	/* Get plugin buffer size to use */
	plugin_buffer_size=MixerGetPluginsBufferSize();
	printf ("Plugin buffer size: %d\n",(int)plugin_buffer_size);
	
	/* Allocate plugin buffer in any RAM */
	plugin_buffer = AllocMem(plugin_buffer_size, MEMF_ANY);
	if (plugin_buffer==NULL)
	{
		FreeMem (buffer,buffer_size);
		printf ("Plugin buffer allocation failed\n");
		return 5;
	}
	
	/* Get plugin data size to use */
	mixer_total_channels=MixerGetTotalChannelCount();
	plugin_data_size=MixerPluginGetMaxDataSize();
	plugin_total_data_size=plugin_data_size*mixer_total_channels;
	printf ("Plugin data size: %d\n",(int)plugin_total_data_size);
	
	/* Allocate plugin data buffer in any RAM */
	plugin_data = AllocMem(plugin_total_data_size, MEMF_ANY);
	if (plugin_data==NULL)
	{
		FreeMem (buffer,buffer_size);
		FreeMem (plugin_buffer,plugin_buffer_size);
		printf ("Plugin data buffer allocation failed\n");
		return 5;
	}
	
	/* Load in and allocate RAM for samples */
	sample1 = LoadSample ("Data/zap.raw",&sample1_size);
	sample2 = LoadSample ("Data/laser.raw",&sample2_size);
	sample3 = LoadSample ("Data/power_up.raw",&sample3_size);
	sample4 = LoadSample ("Data/explosion.raw",&sample4_size);
	
	/* Handle file loading errors here */
	if (sample1 == NULL || sample2 == NULL || sample3 == NULL ||
	    sample4 == NULL)
	{
		if (sample1!=NULL){FreeMem(sample1,sample1_size);}
		if (sample2!=NULL){FreeMem(sample2,sample3_size);}
		if (sample3!=NULL){FreeMem(sample3,sample3_size);}
		if (sample4!=NULL){FreeMem(sample4,sample4_size);}
		printf ("Error during loading\n");
		return 5;
	}
	
	/* Convert all samples here */
	printf ("Pre-processing samples...\n");
	ConvertSample(sample1,sample1_size,4);
	ConvertSample(sample2,sample2_size,4);
	ConvertSample(sample3,sample3_size,4);
	ConvertSample(sample4,sample4_size,4);
	 
	/* Set up Mixer */
	MixerSetup(buffer, plugin_buffer, plugin_data, MIX_PAL, plugin_data_size);
	
	/* Set up Mixer interrupt handler */
	MixerInstallHandler(vbr,0);

	/* Set up vector handler */
	MixerSetReturnVector(test_function);
	test_handler_counter = 0;
	
	/* Start Mixer */
	MixerStart();
	
	/* Set up MXEffect structure for all four samples to play */
	effect1.mfx_length = sample1_size;
	effect1.mfx_sample_ptr = sample1;
	effect1.mfx_loop = MIX_FX_LOOP;
	effect1.mfx_priority = 1;
	effect1.mfx_loop_offset = 0;
	effect1.mfx_plugin = NULL;
	
	effect2.mfx_length = sample2_size;
	effect2.mfx_sample_ptr = sample2;
	effect2.mfx_loop = MIX_FX_LOOP;
	effect2.mfx_priority = 1;
	effect2.mfx_loop_offset = 0;
	effect2.mfx_plugin = NULL;
	
	effect3.mfx_length = sample3_size;
	effect3.mfx_sample_ptr = sample3;
	effect3.mfx_loop = MIX_FX_LOOP;
	effect3.mfx_priority = 1;
	effect3.mfx_loop_offset = 0;
	effect3.mfx_plugin = NULL;
	
	effect4.mfx_length = sample4_size;
	effect4.mfx_sample_ptr = sample4;
	effect4.mfx_loop = MIX_FX_LOOP;
	effect4.mfx_priority = 1;
	effect4.mfx_loop_offset = 0;
	effect4.mfx_plugin = NULL;
	
	/* Play four samples on loop
	 *
	 * Note: when in MIXER_SINGLE mode, the HW audio channel can be replaced
	 *       with a zero, but for the sake of completeness it's included here
	 *       anyway.
	 */
	MixerPlayFX(&effect1,DMAF_AUD2);
	MixerPlayFX(&effect2,DMAF_AUD2);
	MixerPlayFX(&effect3,DMAF_AUD2);
	MixerPlayFX(&effect4,DMAF_AUD2);
	
	/* Wait for keyboard input to continue program */
	printf ("Press enter to play samples with a plugin:");
	fgets(input, sizeof(input), stdin);
	
	/* Stop playback of all samples */
	MixerStopFX(DMAF_AUD2|MIX_CH0|MIX_CH1|MIX_CH2|MIX_CH3);
	Delay(5);
	
	/* Set up plugin init data structure */
	pitch_init_data.mpid_pit_mode = MXPLG_PITCH_STANDARD;
	pitch_init_data.mpid_pit_precalc = MXPLG_PITCH_NO_PRECALC;
	pitch_init_data.mpid_pit_ratio_fp8 = 1<<8|0x80;
	pitch_init_data.mpid_pit_length = 0;
	pitch_init_data.mpid_pit_loop_offset = 0;
	
	/* Set up plugin structure */
	plugin.mpl_plugin_type = MIX_PLUGIN_STD;
	plugin.mpl_init_ptr = MixPluginInitPitch;
	plugin.mpl_plugin_ptr = MixPluginPitch;
	plugin.mpl_init_data_ptr = &pitch_init_data;
	
	/* Set up MXEffect structure */
	effect1.mfx_plugin = &plugin;
	effect2.mfx_plugin = &plugin;
	effect3.mfx_plugin = &plugin;
	effect4.mfx_plugin = &plugin;
	
	/* play all four samples in loop */
	MixerPlayFX(&effect1,DMAF_AUD2);
	MixerPlayFX(&effect2,DMAF_AUD2);
	MixerPlayFX(&effect3,DMAF_AUD2);
	MixerPlayFX(&effect4,DMAF_AUD2);
	
	/* Wait for keyboard input to continue program */
	printf ("Press enter to play a sample using a callback function:");
	fgets(input, sizeof(input), stdin);
	
	/* Stop playback of all samples */
	MixerStopFX(DMAF_AUD2|MIX_CH0|MIX_CH1|MIX_CH2|MIX_CH3);
	Delay(5);
	
	/* Set up MXEffect structure for a single sample to play */\
	effect1.mfx_loop = MIX_FX_ONCE;
	effect1.mfx_plugin = NULL;
	
	/* Set up callback function */
	MixerEnableCallback(callback_function);
	
	/* Play sample while callback is active */
	MixerPlayFX(&effect1,DMAF_AUD2);
	
	/* Wait on callback result */
	/* Use the Amiga Dos call delay() for this 
	   The delay value is given in 50th of a second */
	while (callback_output==0)
	{
		Delay(5);
	}
	
	printf ("Callback occured, sample address found = $%x\n\n",(int)callback_output);
	
	/* Stop Mixer */
	MixerStop();
	
	/* Remove Mixer interrupt handler */
	MixerRemoveHandler();
	
	/* Deallocate Chip RAM buffer */
	FreeMem(buffer,buffer_size);
	
	/* Deallocate other buffers */
	FreeMem (plugin_buffer,plugin_buffer_size);
	FreeMem (plugin_data,plugin_total_data_size);
	
	/* Deallocate samples */
	FreeMem(sample1,sample1_size);
	FreeMem(sample2,sample2_size);
	FreeMem(sample3,sample3_size);
	FreeMem(sample4,sample4_size);
	
	printf ("Test handler counter value = %d\n\n",(int)test_handler_counter);

	/* Close DOS library */

	return 0;
}

#undef MIX_REGARG
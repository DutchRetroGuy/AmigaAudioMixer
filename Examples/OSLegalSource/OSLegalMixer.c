/*
 * OSLegalMixer.c
 *
 * This is an example showing how the mixer's MIXER_EXTERNAL_IRQ_DMA setting
 * can be used to run it in an OS legal manner. The same technique can be
 * applied to other code that needs or wants to take care of IRQ/DMA settings
 * itself, rather than letting the mixer do it.
 * 
 * Note: mixer configuration has to be done via the mixer_config.i file and
 *       the mixer.asm file has to be assembled into a linkable object prior
 *       to use in C programs.
 *
 * Note: the OS expects certain registers to be pushed to stack and restored
 *       when executing an interrupt through the interrupt server mechanism.
 *       To do this, two assembly instructions are needed in the C code.
 *
 *       This program uses the VBCC style for inline assembly, other compilers
 *       might require changes for the inline assembly code to work.
 *
 * Author: Jeroen Knoester
 * Version: 1.0
 * Revision: 20230319
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
#include <hardware/custom.h>
#include <hardware/dmabits.h>
#include "mixer/mixer.h"
#include "plugins/plugins.h"

/* REGARG define to call assembly routines */
#if defined(__VBCC__)
#define MIX_REGARG(arg, reg) __reg(reg) arg
#elif defined(__GNUC__) // Bebbo
#define MIX_REGARG(arg, reg) arg asm(reg)
#endif

/* Global variables */
extern struct Custom custom;
APTR mixer_interrupt_handler;

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

/* IRQ handler */
void InterruptHandler()
{
	// movem.l  d2-d7/a2-a4,-(sp)    ; required stack operation
	
	// movem.l  (sp)+,d2-d7/a2-a4
}

/* IRQ/DMA control functions */
void SetIRQVector(MIX_REGARG(void (*interrupt_handler)(),"a1"))
{
	// routine that sets the IRQ vector for audio interrupts
	mixer_interrupt_handler = (APTR) interrupt_handler;
	// TODO - set up actual interrupt value
}

void RemoveIRQVector()
{
	// routine that removes the IRQ vector for audio interrupts
}

void SetIRQBits(MIX_REGARG(UWORD intena_bits,"d1"))
{
	// routine that sets the correct bits in INTENA to enable
	// audio interrupts for the mixer
}

void ClearIRQBits()
{
	// routine that clears the audio interrupt bits
}

void DisableIRQ()
{
	// routine that disables audio interrupts
}

void EnableIRQ()
{
	// routine that enables audio interrupts
}

void AcknowledgeIRQ(MIX_REGARG(UWORD intreq_value,"d4"))
{
	// routine that acknowledges audio interrupt
	// Documentation suggests that this is not needed for OS legal interrupts.
}

void EnableDMA(MIX_REGARG(UWORD dmacon_value,"d0"))
{
	// routine that enables audio DMA
	custom.dmacon = dmacon_value;
}

void DisableDMA(MIX_REGARG(UWORD dmacon_value,"d6"))
{
	// routine that disables audio DMA
	custom.dmacon = dmacon_value;
}

/* Main program */
int main()
{
	ULONG buffer_size;
	ULONG mixer_total_channels;
	void *vbr=0;
	void *buffer=NULL;
	void *sample1=NULL,*sample2=NULL,*sample3=NULL,*sample4=NULL;
	ULONG sample1_size,sample2_size,sample3_size,sample4_size;
	MXEffect effect1, effect2, effect3, effect4;
	MXIRQDMACallbacks irq_dma_callbacks;
	LONG current_callback_output = 0;
	char input[255];
	
	printf ("OSLegalMixer - example in C for using the Audio Mixer in an OS Legal manner\n");
	printf ("---------------------------------------------------------------------------\n");
	printf ("\n");
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
	 
	/* Set up DMA/IRQ callbacks */
	irq_dma_callbacks.mxicb_set_irq_vector = SetIRQVector;
	irq_dma_callbacks.mxicb_remove_irq_vector = RemoveIRQVector;
	irq_dma_callbacks.mxicb_set_irq_bits = SetIRQBits;
	irq_dma_callbacks.mxicb_clear_irq_bits = ClearIRQBits;
	irq_dma_callbacks.mxicb_disable_irq = DisableIRQ;
	irq_dma_callbacks.mxicb_enable_irq = EnableIRQ;
	irq_dma_callbacks.mxicb_acknowledge_irq = AcknowledgeIRQ;
	irq_dma_callbacks.mxicb_enable_dma = EnableDMA;
	irq_dma_callbacks.mxicb_disable_dma = DisableDMA;
	
	MixerSetIRQDMACallbacks(&irq_dma_callbacks);
	 
	/* Set up Mixer */
	MixerSetup(buffer, NULL, NULL, MIX_PAL, 0);
	
	/* Set up Mixer interrupt handler */
	MixerInstallHandler(vbr,0);

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
	
	/* Stop Mixer */
	MixerStop();
	
	/* Remove Mixer interrupt handler */
	MixerRemoveHandler();
	
	/* Deallocate Chip RAM buffer */
	FreeMem(buffer,buffer_size);

	/* Deallocate samples */
	FreeMem(sample1,sample1_size);
	FreeMem(sample2,sample2_size);
	FreeMem(sample3,sample3_size);
	FreeMem(sample4,sample4_size);

	/* Close DOS library */

	return 0;
}

#undef MIX_REGARG
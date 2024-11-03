/*
 * SampleConverter.c
 *
 * This program pre-processes the given sample to be in the correct amplitude
 * to be used by the Audio Mixer. It also rounds the length of the sample up
 * to the nearest multiple of 4 bytes.
 *
 * Written using standard library function calls only, so this code should be
 * portable to other platforms fairly easily.
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
#include <string.h>

/* Support functions */
char *LoadSample(char *filename, int *size)
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
	sample = malloc(alloc_size);
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
		free(sample);
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

int SaveSample(char *filename, signed char *sample, int size)
{
	FILE *file;
	
	file = fopen(filename,"wb");
	if (file==NULL)
	{		
		printf ("Opening file %s failed\n",filename);
		return -1;
	}
	
	/* Write sample data */
	if(fwrite(sample,size,1,file)==0)
	{
		printf ("Writing file %s failed\n",filename);
		fclose (file);
		return -1;
	}
	
	fclose(file);
	return 0;
}

void ConvertSample(signed char *sample, int size, int voices)
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

/* Main program */
int main (int argc, char *argv[])
{
	void *sample=NULL;
	int sample_size;
	int arg_invalidated;
	int sw_channels;
	char *input_file=NULL;
	char *output_file=NULL;
	
	/* Check arguments */
	arg_invalidated = 0;
	if (argc<4 || argc>4){arg_invalidated = 1;}
	if (strspn(argv[1],"0123456789") != strlen(argv[1])){arg_invalidated = 1;}
	
	/* Early exit if arguments are not validated */
	if (arg_invalidated == 1)
	{
		printf ("Sample converter\n");
		printf ("----------------\n");
		printf ("Usage:\n");
		printf ("%s <number of software channels> <input file> <output file>\n",argv[0]);
		return 0;
	}
	
	sw_channels = atoi(argv[1]);
	input_file = argv[2];
	output_file = argv[3];
	
	/* Load in and allocate RAM for sample */
	sample = LoadSample (input_file,&sample_size);
	
	/* Handle file loading errors here */
	if (sample == NULL)
	{
		printf ("Error loading sample\n");
		return 5;
	}
	
	/* Convert the sample here */
	printf ("Pre-processing sample...\n");
	ConvertSample(sample,sample_size,sw_channels);
	
	/* Write sample */
	if (SaveSample(output_file,sample,sample_size)!=0)
	{
		printf ("Error saving sample\n");
		free(sample);
		return 5;
	}
	
	printf ("Conversion succesful\n");
	
	/* Deallocate sample */
	free(sample);

	return 0;
}
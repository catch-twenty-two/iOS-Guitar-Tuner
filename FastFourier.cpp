// Copyright (C) 2014 Jimmy Johnson
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// See the read me file for licensing information
/*
 * This file contains the implemetation of the classes needed to read a shared
 * buffer and analyze it using a FFT
 */

#include "FastFourier.h"
#include <stdlib.h>

using namespace std;

/*
 * Class		- SampleAnalyzer
 * Method		- GetFundamentalFreq 
 *
 * Parameters	- None
 * Returns		- int fundamentalFreq;
 *
 * Details	- Using the FFT data calculate the fundemental frequency and return
 * it's value
 * 
 */

int SampleAnalyzer::GetFundamentalFreq()
{
	Float32  highest_value = 0;
	int dominant_freq;
	Float32 first_fundamental;	
	Float32 second_fundamental;
	Float32 third_fundamental;
	Float32 forth_fundamental;
	Float32 buftosam_ratio = (Float32)44100/(Float32)AUDIO_BUF_SIZE;
	unsigned long x;
	
	/*
	 * Find the domininant frequency in the Audio buffer using the FFT data
	 * equation is sqrt((real)^2 + (imaginary)^2)
	*/
	
	for(x = 0; x < AUDIO_BUF_SIZE/2; x ++)
	{
		if(sqrt(pow(fabs(sample_ar[x]),2) +  pow(fabs(sample_ai[x]),2)) > highest_value)
		{
			highest_value = sqrt(pow(fabs(sample_ar[x]),2) +  pow(fabs(sample_ai[x]),2));
							
			dominant_freq = x;			
		}
	}
		
	/* See if there are other frequencies resonanting under the dominant (loudest) frequency */
	
	first_fundamental = sqrt(pow(fabs(sample_ar[dominant_freq]),2) +  pow(fabs(sample_ai[dominant_freq]),2));
	second_fundamental = sqrt(pow(fabs(sample_ar[dominant_freq/2]),2) +  pow(fabs(sample_ai[dominant_freq/2]),2));
	third_fundamental = sqrt(pow(fabs(sample_ar[dominant_freq/3]),2) +  pow(fabs(sample_ai[dominant_freq/3]),2));
	forth_fundamental = sqrt(pow(fabs(sample_ar[dominant_freq/4]),2) +  pow(fabs(sample_ai[dominant_freq/4]),2));

	dominant_freq++;
	
	/* If the frequecy has a strength that is greater than 15 then it is more than likely the fudemental is lower than the dominant fequency */ 
	
	fundamentalFreq = (float)dominant_freq*buftosam_ratio;
	if(second_fundamental > 1030421) fundamentalFreq =  (float)dominant_freq*buftosam_ratio/2;
	if(third_fundamental > 1030421) fundamentalFreq = (float)dominant_freq*buftosam_ratio/3;
	if(forth_fundamental > 1030421) fundamentalFreq =  (float)dominant_freq*buftosam_ratio/4;
	
//	printf("%d(%f) %d(%f) %d(%f) %d(%f)\n", (int)(dominant_freq*buftosam_ratio),first_fundamental,
//		   (int)(dominant_freq*buftosam_ratio/2),second_fundamental,
//		   (int)( dominant_freq*buftosam_ratio/3),third_fundamental,
//		   (int) (dominant_freq*buftosam_ratio/4),forth_fundamental);
	
	return fundamentalFreq;	
}

/*
 * Class		- SampleAnalyzer
 * Method		- GetPeakVolume 
 *
 * Parameters	- None
 * Returns		- int16_t  peak_volume;
 *
 * Details	- Using the audio buffer find the largest value
 * 
 */

int16_t  SampleAnalyzer::GetPeakVolume()
{	
	int x;
	Float32 peak_volume = 0;
	
	for(x = 0; x < sample_count; x ++)
	{
		if(peak_volume < fabs(sample_cp[x])) peak_volume = fabs(sample_cp[x]);
	}
	
	return (int16_t) peak_volume;	
}

/*
 * Class		- SampleAnalyzer
 * Method		- InitBuffers 
 *
 * Parameters	- void * buffer - A buffer to copy audio data from
 *				  int number_of_samples - the number of samples in the audio 
 *				  data
 *
 * Returns		- void
 *
 * Details	- Prepares a buffer for the FFT algorithmn to use
 * 
 */

void SampleAnalyzer::InitBuffers(void * buffer, int number_of_samples)
{
	unsigned int x;

	sample_count = number_of_samples;
	
	for(x = 0; x < sample_count; x++)
	{
		/* Init all buffers */
	
		sample_cp[x] = sample_ar[x] = (static_cast<int16_t  *> (buffer))[x];

		/* Imaginary starts out as all zeros */
		
		sample_ai[x] = 0;
	}
	
	/* Any leftover space zero out */
	
	for(; x < AUDIO_BUF_SIZE; x++) sample_cp[x] = sample_ai[x] = sample_ar[x] = 0;
}

/*
 * Class		- SampleAnalyzer
 * Method		- FFTransform 
 *
 * Parameters	- None
 * Returns		- void
 *
 * Details	- Analyzes an initalized audio buffer by:
 *
 * 1) First rearaging the buffer into a bit reversed order
 * 2) Running the reversed bit order data through the discrete transform modfied 
 *	for the new data set.
 *
 * 
*/

/*	The fast Fourier transform subroutine with N = 2**M.  
	Copyright (c) Tao Pang 1997. 
*/

void SampleAnalyzer::FFTransform()
{
	int m,i,j,k,l,n1,n2,l1,l2;
	Float32   PI,a1,a2,q,v,u;

	PI = 4*atan(1);
	n2 = AUDIO_BUF_SIZE/2;
	
	m = log2(AUDIO_BUF_SIZE);
	
	n1 = pow(2,m);
	
	/* Rearrange the data to the bit reversed order */
	
	l = 1;
	
	for (k = 0; k < AUDIO_BUF_SIZE - 1; ++k)
	{
		
		if (k < (l - 1))
		{
			/* Swap  sample n samples/2 with sample at begining */
			
			a1 = sample_ar[l - 1];  
			sample_ar[l - 1] = sample_ar[k];
			sample_ar[k] = a1;
			
			a2 = sample_ai[l - 1];
			sample_ai[l-1] = sample_ai[k];
			sample_ai[k] = a2;
		}
		
		j = n2;
		
		while (j < l)
		{
			l = l-j;
			j = j/2;
		}
		
		l = l + j;
		
	}
	
	/* Perform additions at all levels with reordered data */
	
	l2 = 1;
	
	for (l = 0; l < m; ++l)
	{
		q = 0;
		l1 = l2;
		l2 = 2*l1;
		
		for (k = 0; k < l1; ++k)
		{
			/* e^(it) = cos(t) + i sin (t) */
			
			u =  cos(q); 
			v = -sin(q);
			
			/* e^((-2πitk)/N) = cos((-2πitk)/N) + i sin ((-2πitk)/N)  */
			
			q = q + PI/l1;
			
			for (j = k; j < AUDIO_BUF_SIZE; j = j + l2)
			{
				i = j + l1;
				
				/* Perform the series summation */
				
				a1 = sample_ar[i]*u - sample_ai[i]*v;
				a2 = sample_ar[i]*v + sample_ai[i]*u; 
				sample_ar[i] = sample_ar[j] - a1;
				sample_ar[j] = sample_ar[j] + a1;
				sample_ai[i] = sample_ai[j] - a2;
				sample_ai[j] = sample_ai[j] + a2;
			}
		}
	}
}

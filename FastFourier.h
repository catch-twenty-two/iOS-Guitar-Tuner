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
 * This file contains the classes needed to read a shared buffer and analyze it
 * using a FFT. See the implmentations for method details.
 */

#ifndef FASTFOURIER_H
#define FASTFOURIER_H

#import <AudioUnit/AudioUnit.h>

#define AUDIO_BUF_SIZE 32768

class SampleAnalyzer
{
	
private:
	int sample_count;	
	int sampled_freqency;
	int16_t  peak_volume;
	
public:
	int fundamentalFreq;
	
	// FFT buffers 

	Float32  sample_ar[AUDIO_BUF_SIZE];
	Float32  sample_ai[AUDIO_BUF_SIZE];
	
	// Local Buffer Copy 
	
	Float32  sample_cp[AUDIO_BUF_SIZE];
	
	void InitBuffers(void * buffer, int buffer_size);
		
	int16_t  GetPeakVolume();
	
	void FFTransform ();
	int GetFundamentalFreq();

};
#endif
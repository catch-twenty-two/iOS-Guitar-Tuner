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
 * This file contains the classes needed to initalize and read audio data from
 * apple's Core Audio devices. See the method implementations for deatils.
 *
 */

#ifndef TUNERAUDIOINPUT_H
#define TUNERAUDIOINPUT_H

#include <pthread.h>
#include <string.h>
#include <unistd.h>
#include <semaphore.h>
#include "AudioToolbox/AudioToolbox.h"

#include "FastFourier.h"

static const int kNumberBuffers = 3;

typedef struct AudioStreamData
{
		AudioStreamBasicDescription dataFormat;
		AudioQueueRef queue;
		SInt64 currentPacket;
		AudioQueueBufferRef buffers[3];
		UInt32 bufferByteSize;
		bool mIsRunning;
}AudioStreamData;


class CTAudioBuffer
	{
private:
	bool write_flag;			// A read/write buffer flag
	pthread_mutex_t flag_lock;	// var lock for read/write
	pthread_mutex_t spin_lock;	// var lock for syncronization

	
protected:
		public:
	int16_t  * buffer;			// Shared buffer		
		int buf_index;			// Current shared buffer write index;

		AudioStreamData audioStreamData;
		

		
	void ReInit();
		public :	CTAudioBuffer();
	void SetWriteOkay(); 
	void SetReadOkay();  
	void Synchronize();  
	
	inline int16_t  * AudioBuffer(){ return buffer; };
	inline int AudioBufferSize(){ return (buf_index*sizeof(int16_t )); };
	inline int NumberofSamples(){ return (buf_index); };
	inline bool WriteStatus(){ return write_flag; };
	
};

void DeriveBufferSize (AudioQueueRef                audioQueue,                  // 1
					   AudioStreamBasicDescription   * ASBDescription,             // 2
					   Float64                      seconds,                     // 3
					   UInt32                       *outBufferSize);             // 4

static void HandleInputBuffer (void *userData,
							   AudioQueueRef inAQ,
							   AudioQueueBufferRef inBuffer,
							   const AudioTimeStamp *inStartTime,
							   UInt32 inNumPackets,
							   AudioStreamPacketDescription *inPacketDesc);

CTAudioBuffer * InitAudio(void);

#endif
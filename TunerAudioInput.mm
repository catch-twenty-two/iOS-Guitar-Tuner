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

#include "TunerAudioInput.h"

#include <iostream>
#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>

/* Check for initalization errors and notify user */

#define checkStatus( err ) \
if(err) { cout << "CoreAudio Error " << __func__ << " " << err << " line "<< __LINE__ ; return (-1);}\

using namespace std;

/*
* Class			- CTAudioBuffer
* Method		- Constructor 
*
* Parameters	- None
* Returns		- void
*
* Details	- Creates an audio buffer at start up to write audio data to 
*			analyze.  Also inits pthread locks and variables
*
*/

CTAudioBuffer::CTAudioBuffer()
{
	
	pthread_mutex_init(&flag_lock,NULL);
	pthread_mutex_init(&spin_lock,NULL);
	pthread_mutex_lock(&spin_lock);
	
	buffer = (int16_t  *) calloc(AUDIO_BUF_SIZE, sizeof(int16_t ));
	
	write_flag = TRUE;
	
	ReInit();
}

/*
 * Class		- CTAudioBuffer
 * Method		- ReInit 
 *
 * Parameters	- None
 * Returns		- void
 *
 * Details		- Zeros out the Audio Buffer
 *
 */

void CTAudioBuffer::ReInit()
{	
	memset(buffer, 0, sizeof(int16_t )*AUDIO_BUF_SIZE);
	buf_index = 0;
}

/*
 * Class		- CTAudioBuffer
 * Method		- SetWriteOkay 
 *
 * Parameters	- None
 * Returns		- void
 *
 * Details		This sets the write flags causing the AudioInputProc() method to
 * bypass writing data to the shared buffer 
 *
 */

void CTAudioBuffer::SetWriteOkay()
{
	/* Take control of buffer write flag */
	
	pthread_mutex_lock(&flag_lock);
	
	write_flag = TRUE;
	
	/* Lock the FFT thread spin lock */
	
	pthread_mutex_lock(&spin_lock);
	
	pthread_mutex_unlock(&flag_lock);
}

/*
 * Class		- CTAudioBuffer
 * Method		- SetWriteOkay 
 *
 * Parameters	- None
 * Returns		- void
 *
 * Details		- This causes the FFT analyzation thread to spin lock and wait
 * for the shared audio buffer to be ready to have a full second of audio data
 * points to be read
 *
 */

void CTAudioBuffer::Synchronize()
{
	pthread_mutex_lock(&spin_lock);
	pthread_mutex_unlock(&spin_lock);
}


/*
 * Class		- CTAudioBuffer
 * Method		- SetReadOkay 
 *
 * Parameters	- None
 * Returns		- void
 *
 * Details		- Unlocks the spin lock syncronization lock (See above) and
 * clears the FFT thread to analyze the data. Also causes the AudioInputProc() 
 * method to bypass writing data to the shared buffer 
 *
 */

void CTAudioBuffer::SetReadOkay()
{
	/* Take control of buffer write flag */
	
	pthread_mutex_lock(&flag_lock);
	
	write_flag = FALSE;
	
	/* unlock the FFT thread spin lock */
	
	pthread_mutex_unlock(&spin_lock);
	
	pthread_mutex_unlock(&flag_lock);
}

// once an audio queue buffer fills up this call back is called and the buffer is sent to it
// while this is processing the queue, another qudio queu buffer is filling up
// this keeps the same buffer from being written to that is being processed by the app
// once this callback is done processing the buffer, is needs to re-ad the buffer back
// to the processing queue

// an audio packet looks like: |packetDescription|packetdata|packetDescription|packetdata|

static void HandleInputBuffer (void *userData,									// my data
							   AudioQueueRef inAQ,								// the qudio queue that owns this callback
							   AudioQueueBufferRef inBuffer,					// defined buffer with the incoming data
							   const AudioTimeStamp *inStartTime,				// time of the first sample in the audio queue
							   UInt32 inNumPackets,								// Number of packets in the buffer
							   const AudioStreamPacketDescription *inPacketDesc)// The compressed packet data description if applicable
{
	CTAudioBuffer * ctAudioBuffer = (CTAudioBuffer *) userData;
	int x;

	// if there is no packet data, that means we are using CBR (constant bit rate) and can calculate the number of packets
	// based on the size of the incoming data buffer divided by the number of bytes per packet (2 bytes)
	// ex 32768 (size of incoming data buffer)/2 (bytes per packet) = 16034 points of data

    if (inNumPackets == 0 && ctAudioBuffer->audioStreamData.dataFormat.mBytesPerPacket != 0)
	{
        inNumPackets = inBuffer->mAudioDataByteSize / ctAudioBuffer->audioStreamData.dataFormat.mBytesPerPacket;
			
		ctAudioBuffer->audioStreamData.currentPacket += inNumPackets;
	}
	
	// 44100.0 samples per second, 44100 ints per second (327k buffer)
	
	// Its okay so write the next set of data that has been aquired by Coreaudio 
	
	// See if its okay to write to the shared buffer 
		
	if(!ctAudioBuffer->WriteStatus())
	{
		AudioQueueEnqueueBuffer(ctAudioBuffer->audioStreamData.queue, inBuffer,0, NULL);
		return; 
	}


	for(x = 0;(ctAudioBuffer->buf_index < AUDIO_BUF_SIZE) && (x < inNumPackets); ctAudioBuffer->buf_index += 1, x++)
	{
		ctAudioBuffer->buffer[ctAudioBuffer->buf_index] = ((int16_t *)inBuffer->mAudioData)[x];
	}

	if(ctAudioBuffer->buf_index == AUDIO_BUF_SIZE)
	{
		// Buffer was filled so set a FFT read to be okay 
		
		ctAudioBuffer->SetReadOkay();
	}
	
	AudioQueueEnqueueBuffer(ctAudioBuffer->audioStreamData.queue, inBuffer,0, NULL);	
		 
}

/*
 * Class		- CTAudioInput
 * Method		- InitAudio 
 *
 * Parameters	- None
 * Returns		- OSStatus err - The initalization error status
 *
 * Details		- Sets up an AudioUnit and creates a thread that reads from the
 * default input device
 *
 */

CTAudioBuffer * InitAudio(void)
{
	CTAudioBuffer * myBuffer = new CTAudioBuffer();
	
	myBuffer->audioStreamData.dataFormat.mSampleRate = 44100.0;
    myBuffer->audioStreamData.dataFormat.mFormatID = kAudioFormatLinearPCM;

    myBuffer->audioStreamData.dataFormat.mChannelsPerFrame = 1; // mono
    myBuffer->audioStreamData.dataFormat.mBitsPerChannel = 16;
    myBuffer->audioStreamData.dataFormat.mFramesPerPacket = 1;
    myBuffer->audioStreamData.dataFormat.mBytesPerPacket = 2;
    myBuffer->audioStreamData.dataFormat.mBytesPerFrame = 2;
    myBuffer->audioStreamData.dataFormat.mReserved = 0;
	 
	myBuffer->audioStreamData.dataFormat.mFormatFlags 	= 
											kLinearPCMFormatFlagIsSignedInteger |
											kLinearPCMFormatFlagIsPacked;
	
	DeriveBufferSize(myBuffer->audioStreamData.queue, 
					 &myBuffer->audioStreamData.dataFormat,
					 0.5,
					 &myBuffer->audioStreamData.bufferByteSize);
	
	OSStatus status;
	
    status = AudioQueueNewInput(&myBuffer->audioStreamData.dataFormat,
								HandleInputBuffer,
								(void *) myBuffer,
								NULL,
								kCFRunLoopCommonModes,
								0,
								&myBuffer->audioStreamData.queue);
	
	if (status) { printf("Could not establish new queue\n"); return NULL;}
	
	for (int i = 0; i < kNumberBuffers; ++i) {           // 1
		
		AudioQueueAllocateBuffer (myBuffer->audioStreamData.queue,
								  myBuffer->audioStreamData.bufferByteSize,
								  &myBuffer->audioStreamData.buffers[i]);
		
		AudioQueueEnqueueBuffer (myBuffer->audioStreamData.queue,
								 myBuffer->audioStreamData.buffers[i],
								 0,
								 NULL);
		
		myBuffer->audioStreamData.currentPacket = 0;
		myBuffer->audioStreamData.mIsRunning = true;
		
		AudioQueueStart(myBuffer->audioStreamData.queue, NULL);
		
	}
	
	
	return myBuffer;
}

void DeriveBufferSize (AudioQueueRef                audioQueue,                  // 1
					   AudioStreamBasicDescription  * ASBDescription,             // 2
					   Float64                      seconds,                     // 3
					   UInt32                       *outBufferSize)				//4
{
	
    static const int maxBufferSize = 0x50000;					//327k
	
	
	
    int maxPacketSize = ASBDescription->mBytesPerPacket;       // 6
	
    if (maxPacketSize == 0) {                                 // 7
		
	UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
		
	AudioQueueGetProperty (audioQueue,
						   kAudioQueueProperty_MaximumOutputPacketSize,
							   // in Mac OS X v10.5, instead use
							   //   kAudioConverterPropertyMaximumOutputPacketSize
							   &maxPacketSize,
							   &maxVBRPacketSize);
    }
	
	
	
    Float64 numBytesForTime =
	
	ASBDescription->mSampleRate * maxPacketSize * seconds; // 327k * .5 
	
    *outBufferSize =
	
    UInt32 (numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize);                     // 9
	
}


/*
 * Class		- CTAudioBuffer
 * Method		- AudioInputProc 
 *
 * Parameters	- None
 * Returns		- OSStatus buffer read/write error status
 *
 * Details		- Automatically called when core audio's internal audio buffer
 * is filled
 *
 */
/*
OSStatus CTAudioInput::AudioInputProc(void)
{
	void * inRefCon;
	AudioUnitRenderActionFlags *ioActionFlags;
	const AudioTimeStamp *inTimeStamp;
	UInt32 inBusNumber;
	UInt32 inNumberFrames;
	AudioBufferList * ioData;
	int x, buffer_data_size;
	OSStatus err = noErr;
	
	CTAudioInput * cta_data_ptr = static_cast<CTAudioInput *>(inRefCon);	
	int16_t  * audio_buffer = (int16_t  *) cta_data_ptr->AudioBuffer();
	buffer_data_size = cta_data_ptr->bufferList.mBuffers[0].mDataByteSize;
	
	err = AudioUnitRender(cta_data_ptr->audioInputUnit,
						 ioActionFlags,
						 inTimeStamp,
						 inBusNumber,     //will be '1' for input data
						 inNumberFrames, //# of frames requested
						 &cta_data_ptr->bufferList);
	
	
	checkStatus( err );
	
	// See if its okay to write to the shared buffer 
	
	if(!cta_data_ptr->WriteStatus()) return err;
	
	// Its okay so write the next set of data that has been aquired by Coreaudio 
	
	if(cta_data_ptr->buf_index + buffer_data_size <= AUDIO_BUF_SIZE) // check if buffer has 1 sec worth of data
	{
		for(x = 0; x < inNumberFrames; x++)
		{
			audio_buffer[x + cta_data_ptr->buf_index] = ((int16_t *)cta_data_ptr->bufferList.mBuffers[0].mData)[x];			
		}
		
		cta_data_ptr->buf_index += x; // Increment the audio buffer array index for the next entry
	}
	else
	{
			// Buffer was filled so set a FFT read to be okay 
		
		cta_data_ptr->SetReadOkay();
	}
	
	return err;
}
*/

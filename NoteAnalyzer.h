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
 * This file contains the implemetation of the classes needed to set up and
 * turn a frequency to a corresponding Note value and also to animate the 
 * display. See the method implementations for details.
 */

#import <UIKit/UIKit.h>
#include "TunerAudioInput.h"
#include "FastFourier.h"

@interface Note : NSObject
{
	@public
	NSString * keyName; // Note name
	int frequency;		// Note in HZ
	int cents;			// cents +/-
}

@end

@interface NoteAnalyzer : NSObject
{	
	NSMutableDictionary * frequencyTable;
}


+ (Note *) calculateNote : (int) freq;
+ (NSMutableDictionary *) getGuitarTonalFrequences;
- (NSMutableDictionary *) getBassTonalFrequences;
+ (Note *) createKeyName: (NSString *) noteName frequency: (int) freq;
- (void) initAnalyzer;
@end



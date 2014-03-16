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
 * display.
 */

#import <Foundation/NSTimer.h>
#import "NoteAnalyzer.h"
#include <iostream>

using namespace std;

@implementation Note

@end

@implementation NoteAnalyzer

/*
 * Class		- NoteAnalyzer
 * Method		- + createKeyName 
 *
 * Parameters	- (NSString *) note frequency - The name of the note
 *				- (int) freq - The frequency of the note in Hz 
 *
 * Returns		- NoteAnalyzer * name - A note name/key freq 
 *
 * Details	- This function pairs a freq. with a note and stores it in a FeqKeyName
 * storage class
 *
 */

+ (Note *) createKeyName: (NSString *) noteName frequency: (int) freq
{
	Note * note = [[Note alloc] init];
	
	note->frequency = freq;
	
	note->keyName = [[NSString stringWithString: noteName] retain]; 	
	return note;
}

/*
 * Class		- NoteAnalyzer
 * Method		- getGuitarTonalFrequences 
 *
 * Parameters	- None
 * Returns		- NSMutableDictionary * freqTable - A diction with Notes as
 *				key values.
 *
 * Details	- Creates a frequency to note value table using given values
 * corresponding to a guitar
 *
 */

+ (NSMutableDictionary *) getGuitarTonalFrequences
{
	NSMutableDictionary * noteTable = [[[NSMutableDictionary alloc] init] retain];

	[noteTable setObject: [NoteAnalyzer createKeyName: @"E2" frequency: 82] forKey: @"E2"];

	[noteTable setObject: [NoteAnalyzer createKeyName: @"A2" frequency: 110] forKey: @"A2"];
	
	[noteTable setObject: [NoteAnalyzer createKeyName: @"D3" frequency: 146] forKey: @"D"];
	
	[noteTable setObject: [NoteAnalyzer createKeyName: @"G3" frequency: 196] forKey: @"G"];
	
	[noteTable setObject: [NoteAnalyzer createKeyName: @"B3" frequency: 247] forKey: @"B"];

	[noteTable setObject: [NoteAnalyzer createKeyName: @"E4" frequency: 329] forKey: @"E4"];
	
	return noteTable;
}

/*
 * Class		- NoteAnalyzer
 * Method		- + getBassTonalFrequences
 *
 * Parameters	- None
 * Returns		- NSMutableDictionary * freqTable - A diction with Notes as
 *				key values.
 *
 * Details	- Creates a frequency to note value table using given values
 * corresponding to a bass (not implemented yet)
 *
 */

- (NSMutableDictionary *) getBassTonalFrequences
{
	NSMutableDictionary * freqTable = [[[NSMutableDictionary alloc] init] retain];
	
	/* Stub */
	
	return freqTable;
}

- (void) initAnalyzer
{
//	frequencyTable =  self.getGuitarTonalFrequences;
}

/*
 * Class		- NoteAnalyzer
 * Method		- + getGuitarAllFrequences
 *
 * Parameters	- None
 * Returns		- NSMutableDictionary * freqTable - A diction with Notes as
 *				key values.
 *
 * Details	- The following creates a full cromatic tuning scale
 * through all values of sharp and flat notes.  It works (kinda) but there 
 * is overlap, frequency problems, ect.. Fix in the future?
 */

/*
- (NSMutableDictionary *) getAllTonalFrequences
{
	Float32  well_tempered_ratio = powf(2, (1.0/12.0));
	int octave;
	NSString * note_name;
	Float32  note_frequency = 32.703;
	NSMutableDictionary * freqTable = [[[NSMutableDictionary alloc] init] retain];

	// Create tuning table using logarithmic western scale 
	
	for(octave = 1; octave < 7; octave ++)
	{

			note_name = [NSString stringWithFormat: @"C%i",octave];
			
			[freqTable setObject: [NoteAnalyzer createKeyName: note_name frequency: (int) note_frequency] forKey: note_name];
			
			note_frequency *= well_tempered_ratio;
			note_frequency *= well_tempered_ratio;
			
			note_name = [NSString stringWithFormat: @"D%i",  octave];
			
			[freqTable setObject: [NoteAnalyzer createKeyName: note_name frequency: (int) note_frequency] forKey: note_name];
	
			note_frequency *= well_tempered_ratio;
			note_frequency *= well_tempered_ratio;
			
			note_name = [NSString stringWithFormat: @"E%i",  octave];
			
			[freqTable setObject: [NoteAnalyzer createKeyName: note_name frequency: (int) note_frequency] forKey: note_name];
			
			note_frequency *= well_tempered_ratio;
			
			note_name = [NSString stringWithFormat: @"F%i",  octave];
			
			[freqTable setObject: [NoteAnalyzer createKeyName: note_name frequency: (int) note_frequency] forKey: note_name];
			
			note_frequency *= well_tempered_ratio;
			note_frequency *= well_tempered_ratio;
			
			note_name = [NSString stringWithFormat: @"G%i",  octave];
			
			[freqTable setObject: [NoteAnalyzer createKeyName: note_name frequency: (int) note_frequency] forKey: note_name];
			
			note_frequency *= well_tempered_ratio;
			note_frequency *= well_tempered_ratio;
			
			note_name = [NSString stringWithFormat: @"A%i",  octave];
			
			[freqTable setObject: [NoteAnalyzer createKeyName: note_name frequency: (int) note_frequency] forKey: note_name];
			
			note_frequency *= well_tempered_ratio;
			note_frequency *= well_tempered_ratio;
			
			note_name = [NSString stringWithFormat: @"B%i",  octave];
			
			[freqTable setObject: [NoteAnalyzer createKeyName: note_name frequency: (int) note_frequency] forKey: note_name];
			
			note_frequency *= well_tempered_ratio;

	}
 
	return freqTable;
}
*/



/*
 * Class		- ChromaTuner
 * Method		- + updateCTDisplay 
 *
 * Parameters	- (id) displayItems - Contains the bundle of display items to update
 *
 * Returns		- void
 *
 * Details	- Inifinite loop thread for comparing heard freqs. and the display
 */

+ (Note *) calculateNote : (int) freq	
{
	Note * note = [[Note alloc] init];
	Note * freqAtKey;
	NSArray * freqNoteArray = [[NoteAnalyzer getGuitarTonalFrequences] allValues];
	int note_index;
	int note_freq;	// The acual target frequency and the fundamental frequency heard
	int sharp_note, flat_note;
	
	Float32  well_tempered_ratio = powf(2, (1.0/12.0));  // Well tempered western ratio
	
	/* iterate through the hash table and see what frequencies seem to be closest */
	
	for(note_index = 0; note_index < [freqNoteArray count]; note_index++)
	{
		freqAtKey = [freqNoteArray objectAtIndex:note_index];
		
		note_freq = freqAtKey->frequency;
		
		/* convert Hz to cents */
		
		sharp_note = (float)note_freq*well_tempered_ratio;
		flat_note = (float)note_freq/well_tempered_ratio;
		
		/* use the well tempered ratio to find out if the freq. heard is within a flat or sharp tone of the target note */
		
		if ((freq >= (flat_note)) && (freq <= (sharp_note)))
		{
			/* If its higher its sharp */
			
			if(freq > note_freq)
			{	
				note->cents = log2((note_freq + fabs(note_freq - freq))/note_freq)*1200/2;
				note->keyName = [NSString stringWithString:freqAtKey->keyName];
				note->frequency = freqAtKey->frequency;
				
				return note;
			}
			
			/* If its lower its flat */
			
			if(freq < note_freq)
			{
				note->cents = -1*log2((note_freq + fabs(note_freq - freq))/note_freq)*1200/2;
				note->keyName = [NSString stringWithString:freqAtKey->keyName];
				note->frequency = freqAtKey->frequency;
				
				return note;
			}
			
			/* If its equal its tuned */
			if (freq == note_freq) 
			{
				note->cents = 0;
				note->keyName = [NSString stringWithString:freqAtKey->keyName];
				note->frequency = freqAtKey->frequency;
				
				return note;
			}
		}
	}
	
	return nil;
}

@end // NoteAnalyzer



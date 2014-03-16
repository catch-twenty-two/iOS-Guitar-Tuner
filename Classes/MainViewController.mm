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

#import "MainViewController.h"
#import "TunerAudioInput.h"	

#define REDRAW_TIMER 1.0f

@implementation MainViewController

SampleAnalyzer sampleAnalyzer;
int frequency = 0;
float blankDisplayTimer = 0;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void) viewDidLoad 
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	pthread_t buf_update_thread;
	
	// Setup audio input
	
	CTAudioBuffer * audioInput = InitAudio();
	
	// setup animation class
	
	animation = [[Animation alloc] init];
	
	[animation init:(UIView *) self.view];
	
	// start analyzing samples
	
	pthread_create(&buf_update_thread, NULL, &analyzeData, audioInput);
	
	[NSTimer scheduledTimerWithTimeInterval:REDRAW_TIMER target:self selector:@selector(updateCTDisplay:) userInfo: nil repeats:YES];
	
	[super viewDidLoad];
	[pool release];
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void) updateCTDisplay: (id) none
{
	Note * currentNote = [NoteAnalyzer calculateNote:frequency];
	
	if(currentNote != nil)
	{
		[field1 setTitle:currentNote->keyName forState:UIControlStateNormal];
		[field1 setTitle:currentNote->keyName forState:UIControlStateHighlighted];
		[animation setNeedleTarget:currentNote->cents];
	}
	else
	{
		blankDisplayTimer += REDRAW_TIMER;
		
		if(blankDisplayTimer > 3) 
		{
			[field1 setTitle:@"" forState:UIControlStateNormal];
			[field1 setTitle:@"" forState:UIControlStateHighlighted];

			[animation clearDisplay];
			blankDisplayTimer = 0;
		}
			
	}
}

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo {    
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}


/*
 * Class		- ChromaTuner
 * Method		- analyzeData(void * thread_data) 
 *
 * Parameters	- void * thread_data - The Audio buffer data
 *
 * Returns		- void * NULL
 *
 * Details	- THe method for analyzing the incoming audio data
 */

void * analyzeData(void * thread_data)
{
	CTAudioBuffer * audiobuffer_data = static_cast<CTAudioBuffer *> (thread_data);

	while(1) // Do forever
	{
		// Protect critical section until data is availible 
		
		audiobuffer_data->Synchronize();
		
		// Syncronize FFT buffers 
		
		sampleAnalyzer.InitBuffers(audiobuffer_data->AudioBuffer(),audiobuffer_data->NumberofSamples());
		
		// Apply FFT 
		
		sampleAnalyzer.FFTransform();
		
		// Use new Data to find fundamental frequency
		
		frequency = sampleAnalyzer.GetFundamentalFreq();

		audiobuffer_data->ReInit();
		audiobuffer_data->SetWriteOkay();
	}
	
	return NULL;
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

/*
 * Class		- ChromaTuner
 * Method		- - catchAudioError 
 *
 * Parameters	- None
 * Returns		- void
 *
 * Details	- Returns an error to the user if app. did not properly initalize
 *
 */

- (void) catchAudioError
{
	exit(-1);
}

@end

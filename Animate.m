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

#import "Animate.h"
// This is defined in Math.h
#define M_PI   3.14159265358979323846264338327950288   /* pi */

// Our conversion definition
#define DEGREES_TO_RADIANS(angle) ((angle / 180.0) * M_PI)
#define DEFAULT_D 36
#define DEFAULT_X 56

@implementation Animation

int previousNeedleTarget;
int currentNeedleTarget;

-(void)init:(UIView *) view
{
	mainView = view;
	
	led =
	[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"led.png"]];
	
	needle =
	[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"needle.png"]];
	
	UIImageView * bottomImg =
	[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bottomedge.png"]];
	
	needle.center = CGPointMake(160.0, 120);
	[view addSubview: needle];
	bottomImg.center = CGPointMake(163,189);
	bottomImg.opaque = TRUE;
	
	[view addSubview: bottomImg];	
	[view bringSubviewToFront: bottomImg];
	bottomImg.opaque = TRUE;
	
	led.center = CGPointMake(271.0,93);
	[view addSubview: led];
	[view bringSubviewToFront: led];
	led.opaque = TRUE;
	led.hidden = TRUE;
	
	[NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(animateNeedle) userInfo: nil repeats:YES];
}

-(void) clearDisplay
{
	[self lightButtons: NONE];
	currentNeedleTarget = 0;
}

- (void) setNeedleTarget:(int) nTarget
{
	currentNeedleTarget = nTarget;
	
	if(nTarget == 0)
	{
		[self lightButtons: TUNED];
		return;
	}
	
	if(nTarget > 0)
	{
		[self lightButtons: SHARP];
		return;
	}
	
	if(nTarget < 0)
	{
		[self lightButtons: FLAT];
		return;
	}
}

- (void)animateNeedle
{	
	float ratio = (float)currentNeedleTarget*.02;
	float comp_x = DEFAULT_X * ratio;
	float comp_r = DEFAULT_D * ratio; 
	
	if(previousNeedleTarget != currentNeedleTarget) previousNeedleTarget = currentNeedleTarget;
	else return;
	
	[self rotateImage:needle duration:.2
				curve:UIViewAnimationCurveEaseIn degrees:(int)comp_r sidemovement: (int)comp_x];
}

- (void)rotateImage:(UIImageView *)image duration:(NSTimeInterval)duration 
			  curve:(int)curve degrees:(CGFloat)degrees sidemovement: (int) sidemovement
{				
	// Setup the animation
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationCurve:curve];
	[UIView setAnimationBeginsFromCurrentState:YES];
	
	
	image.transform = CGAffineTransformIdentity;
	image.transform = CGAffineTransformTranslate(image.transform, sidemovement, 0);
	image.transform = CGAffineTransformRotate(image.transform, DEGREES_TO_RADIANS(degrees));
	
	
	// Commit the changes
	[UIView commitAnimations];
	
}

/*
 * Class		- ChromaTuner
 * Method		- + lightButtons 
 *
 */

- (void) lightButtons: (int) activeButton
{
	UIButton * noteName = (UIButton *) [mainView viewWithTag:103];
	UIButton * sharp = (UIButton *) [mainView viewWithTag:102];
	UIButton * flat = (UIButton *) [mainView viewWithTag:101];
	
	/* Depending on the status passed in change the button status to reflect it */
	
	switch (activeButton)
	{
		case FLAT:
			noteName.highlighted = NO;
			sharp.highlighted = YES;
			flat.highlighted = NO;
			led.hidden = TRUE;
			break;
			
		case SHARP:
			noteName.highlighted = NO;
			sharp.highlighted = NO;
			flat.highlighted = YES;
			led.hidden = TRUE;
			break;
		
		case TUNED:
			
			sharp.highlighted = YES;
			flat.highlighted = YES;
			led.hidden = FALSE;
			//noteName.highlighted = YES;
			break;
		
		case NONE:
			
			sharp.highlighted = YES;
			flat.highlighted = YES;
			led.hidden = TRUE;
			noteName.highlighted = NO;
			break;
	}
	
}

@end

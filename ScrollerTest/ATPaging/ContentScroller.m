//
//  ContentScroller.m
//
//  Created by Omid Hashemi on 1/12/12.
//  Copyright (c) 2012 42dp. All rights reserved.
//

#import "ContentScroller.h"

@implementation ContentScroller

@synthesize activeIndex = _activeIndex;
@synthesize shouldScroll = _shouldScroll;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    
//    [super touchesBegan:touches withEvent:event];
//    NSLog(@"--- touchesBegan on %@", NSStringFromClass([self class]));
//}
//
//-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    
//    [super touchesMoved:touches withEvent:event];
//    NSLog(@"--- touchesMoved on %@", NSStringFromClass([self class]));
//}

-(void) scrollToPage:(int) index{}

@end

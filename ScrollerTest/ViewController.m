//
//  ViewController.m
//  ScrollerTest
//
//  Created by Omid Hashemi on 5/21/12.
//  Copyright (c) 2012 42dp. All rights reserved.
//

#import "ViewController.h"
#import "ATScroller.h"
#import "NodeViewController.h"

@interface ViewController (){

    ATScroller *root;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	root = [[ATScroller alloc] init];
    root.view.frame = self.view.bounds;
    [self.view addSubview:root.view];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
        return YES;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [root willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [root didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}
@end

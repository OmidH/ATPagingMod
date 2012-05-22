//
//  NodeViewController.m
//  ScrollerTest
//
//  Created by Omid Hashemi on 5/21/12.
//  Copyright (c) 2012 42dp. All rights reserved.
//

#import "NodeViewController.h"

@interface NodeViewController () {
    NSMutableDictionary *dictNodes;
}

@end

@implementation NodeViewController

@synthesize idx = _idx;
//@synthesize parentScroller = _parentScroller;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	dictNodes = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.pagingView.currentPageIndex = 0;
    self.pagingView.horizontal = YES;
    self.pagingView.recyclingEnabled = NO;
    self.pagingView.pagesToPreload = 0;
    self.pagingView.shouldScrollVertical = YES;
    self.pagingView.isRootScroller = NO;
    self.pagingView.delegate = self;
    
    self.view.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.pagingView.currentPageIndex = 0;
    [self currentPageDidChangeInPagingView:self.pagingView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

+ (UIColor *) randomColor {
    CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
   
//    return [[dictNodes objectForKey:[NSString stringWithFormat:@"%d", root.pagingView.currentPageIndex]] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    return YES;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    NSLog(@"(node) currentpageindex = %d", self.pagingView.currentPageIndex);
//    if(self.pagingView.currentPageIndex > 0) 
//        self.parentScroller.pagingView.shouldScrollVertical = NO;
//    else 
//        self.parentScroller.pagingView.shouldScrollVertical = YES;
    
//    [self currentPageDidChangeInPagingView:self.pagingView];

}

- (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView {
    return 10;
}

- (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index {
    UIView *view = [pagingView dequeueReusablePage];
    if (view == nil) {
               
        UIView *n_view = [[UIView alloc] initWithFrame:self.view.bounds];
        n_view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        n_view.backgroundColor = [NodeViewController randomColor];
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(200, 200, 200, 100)];
        lbl.backgroundColor = [UIColor greenColor];
        lbl.text = [NSString stringWithFormat:@"index: %d.%d", _idx, index];
        lbl.font = [UIFont systemFontOfSize:18];
        [n_view addSubview:lbl];
                
        view = n_view;
        
    }
    
    return view;
}

- (void)currentPageDidChangeInPagingView:(ATPagingView *)pagingView {
    NSLog(@"node %@",[NSString stringWithFormat:@"%d of %d", pagingView.currentPageIndex+1, pagingView.pageCount]);
    
//    if(self.pagingView.currentPageIndex > 0) 
//        self.parentScroller.pagingView.shouldScrollVertical = NO;
//    else 
//        self.parentScroller.pagingView.shouldScrollVertical = YES;
}

@end

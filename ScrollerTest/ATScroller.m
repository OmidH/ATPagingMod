//
//  ATScroller.m
//  ScrollerTest
//
//  Created by Omid Hashemi on 5/21/12.
//  Copyright (c) 2012 42dp. All rights reserved.
//

#import "ATScroller.h"
#import "NodeViewController.h"

@interface ATScroller (){
    NSMutableDictionary *dictNodes;
}


@end

@implementation ATScroller

@synthesize idx = _idx;

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
    self.pagingView.horizontal = NO;
    self.pagingView.recyclingEnabled = NO;
    self.pagingView.pagesToPreload = 0;
    self.pagingView.shouldScrollVertical = YES;
    self.pagingView.isRootScroller = YES;
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    
    //    return [[dictNodes objectForKey:[NSString stringWithFormat:@"%d", root.pagingView.currentPageIndex]] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    return YES;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    for (NodeViewController *node in [dictNodes allValues]) {
        [node willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    NSLog(@"(root) currentpageindex = %d", self.pagingView.currentPageIndex);
}


- (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView {
    return 10;
}

- (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index {
    UIView *view = [pagingView dequeueReusablePage];
    if (view == nil) {
        if(index == 0) {
            view = [[UIView alloc] initWithFrame:self.view.bounds];
            view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(200, 200, 200, 100)];
            lbl.backgroundColor = [UIColor yellowColor];
            lbl.text = [NSString stringWithFormat:@"index: %d.%d", _idx, index];
            lbl.font = [UIFont systemFontOfSize:18];
            [view addSubview:lbl];
        } else {
            NodeViewController *node = [[NodeViewController alloc] init];
            node.view.frame = self.view.bounds;
            node.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            node.idx = index;
//            node.parentScroller = self;
            node.pagingView.parentScroller = self;
            [dictNodes setObject:node forKey:[NSString stringWithFormat:@"%d",index]];
            view = node.view;
        }
    }
    
    return view;
}

- (void)currentPageDidChangeInPagingView:(ATPagingView *)pagingView {
    NSLog(@"root %@",[NSString stringWithFormat:@"%d of %d", pagingView.currentPageIndex+1, pagingView.pageCount]);
}

@end

//
//  ContentScroller.h
//
//  Created by Omid Hashemi on 1/12/12.
//  Copyright (c) 2012 42dp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContentScroller : UIViewController 

@property (nonatomic, readonly) int activeIndex;
@property (nonatomic) BOOL shouldScroll;

-(void) scrollToPage:(int) index;

@end

//
//  NodeViewController.h
//  ScrollerTest
//
//  Created by Omid Hashemi on 5/21/12.
//  Copyright (c) 2012 42dp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATPagingView.h"

@interface NodeViewController : ATPagingViewController<UIScrollViewDelegate>

@property (nonatomic) int idx;

+ (UIColor *) randomColor;

@end

//
//  ContentScrollView.m
//
//  Created by Omid Hashemi on 2/2/12.
//  Copyright (c) 2012 42dp. All rights reserved.
//

#import "ContentScrollView.h"

@implementation ContentScrollView

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self nextResponder] touchesBegan:touches withEvent:event];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self nextResponder] touchesMoved:touches withEvent:event];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self nextResponder] touchesEnded:touches withEvent:event];
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self nextResponder] touchesCancelled:touches withEvent:event];
}

-(void) setContentOffset:(CGPoint)contentOffset {
    [super setContentOffset:contentOffset];
    NSLog(@"_______________ new contentoffset: %@", NSStringFromCGPoint(contentOffset));
}

@end

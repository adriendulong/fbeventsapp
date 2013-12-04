//
//  CameraFocusSquare.m
//  CameraOverlayMoment
//
//  Created by Jérémy on 25/11/2013.
//  Copyright (c) 2013 Jérémy CARRAT. All rights reserved.
//

#import "CameraFocusSquare.h"
#import <QuartzCore/QuartzCore.h>

//const float squareLength = 80.0f;

@implementation CameraFocusSquare

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        [self setBackgroundColor:[UIColor clearColor]];
        [self.layer setBorderWidth:2.0];
        [self.layer setCornerRadius:4.0];
        [self.layer setBorderColor:[UIColor whiteColor].CGColor];
        
        CABasicAnimation* selectionAnimation = [CABasicAnimation animationWithKeyPath:@"borderColor"];
        selectionAnimation.toValue = (id)[UIColor orangeColor].CGColor;
        selectionAnimation.repeatCount = 8;
        [self.layer addAnimation:selectionAnimation
                          forKey:@"selectionAnimation"];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

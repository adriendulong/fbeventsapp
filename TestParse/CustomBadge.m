//
//  CustomBadge.m
//  FbEvents
//
//  Created by Adrien Dulong on 28/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "CustomBadge.h"

@implementation CustomBadge

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addBadge];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    if ((self = [super initWithCoder:coder])) {
        [self addBadge];
    }
    return self;
}

- (void)addBadge
{
    
    CGRect labelFrame = CGRectMake(self.frame.size.width/2-7, self.frame.size.height/2-9, 16, 16);
    self.badgeLabel = [[UILabel alloc] initWithFrame:labelFrame];
    self.badgeLabel.textColor = [UIColor whiteColor];
    self.badgeLabel.backgroundColor = [UIColor clearColor];
    self.badgeLabel.font = [UIFont systemFontOfSize:14];
    self.badgeLabel.textAlignment = NSTextAlignmentCenter;
    self.badgeLabel.text = [NSString stringWithFormat:@"%i", 0];
    
    [self addSubview:self.badgeLabel];
}

- (void)updateBadgeWithNumber:(int)number
{
    self.badgeLabel.text = [NSString stringWithFormat:@"%i", number];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CALayer *imageLayer = self.layer;
    [imageLayer setCornerRadius:11];
    [imageLayer setBorderWidth:1];
    [imageLayer setBorderColor:[UIColor clearColor].CGColor];
    [imageLayer setMasksToBounds:YES];
    
    self.backgroundColor = [UIColor colorWithRed:252/255.0f green:13/255.0f blue:27/255.0f alpha:1.0f];
}

@end


//
//  CustomBadge.h
//  FbEvents
//
//  Created by Adrien Dulong on 28/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomBadge : UIView

@property (strong, nonatomic) UILabel *badgeLabel;

- (void)updateBadgeWithNumber:(int)number;

@end

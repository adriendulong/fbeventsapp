//
//  CommentPostCell.m
//  Woovent
//
//  Created by Jérémy on 10/02/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import "CommentPostCell.h"

@implementation CommentPostCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.size.width = 300;
    contentViewFrame.origin.x += 10;
    self.contentView.frame = contentViewFrame;
}

@end

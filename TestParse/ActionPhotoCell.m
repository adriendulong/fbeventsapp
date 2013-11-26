//
//  ActionPhotoCell.m
//  FbEvents
//
//  Created by Adrien Dulong on 19/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "ActionPhotoCell.h"

@implementation ActionPhotoCell

-(void)viewDidLoad{
    
}

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

- (IBAction)like:(id)sender {
    if (self.likeButton.isSelected) {
        [self.likeButton setSelected:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:ClickLikePhoto object:self userInfo:nil];
    }
    else{
        [self.likeButton setSelected:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:ClickLikePhoto object:self userInfo:nil];
    }
    
}

- (IBAction)more:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:MorePhoto object:self userInfo:nil];
}
@end

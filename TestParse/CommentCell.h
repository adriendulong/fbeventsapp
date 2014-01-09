//
//  CommentCell.h
//  Woovent
//
//  Created by Jérémy on 07/01/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextView *commentTextView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;

@end

//
//  CommentPostCell.h
//  Woovent
//
//  Created by Jérémy on 10/02/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentPostCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *subContentView;

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *fullName;
@property (weak, nonatomic) IBOutlet UILabel *date;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet UILabel *nbLike;
@property (weak, nonatomic) IBOutlet UILabel *nbComment;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeight;

@end

//
//  CommentPostRespCell.h
//  Woovent
//
//  Created by Jérémy on 19/02/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentPostRespCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *fullName;
@property (weak, nonatomic) IBOutlet UILabel *date;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet UIImageView *thumbImageView;
@property (weak, nonatomic) IBOutlet UILabel *nbLike;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeightConstraints;

@end

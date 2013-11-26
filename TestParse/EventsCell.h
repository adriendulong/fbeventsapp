//
//  EventsCell.h
//  TestParse
//
//  Created by Adrien Dulong on 28/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventsCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameEventLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UILabel *ownerInvitation;
@property (weak, nonatomic) IBOutlet UILabel *whereWhenLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;

@end

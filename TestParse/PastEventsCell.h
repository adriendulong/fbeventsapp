//
//  PastEventsCell.h
//  Woovent
//
//  Created by Adrien Dulong on 13/03/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PastEventsCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayDateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *previewPhoto;
@property (weak, nonatomic) IBOutlet UILabel *nameEventLabel;
@property (weak, nonatomic) IBOutlet UILabel *nbPhotosLabel;

@end

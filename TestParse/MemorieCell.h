//
//  MemorieCell.h
//  FbEvents
//
//  Created by Adrien Dulong on 26/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MemorieCell : UITableViewCell
/*
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
//@property (weak, nonatomic) IBOutlet UILabel *nbPhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *placeLabel;
@property (weak, nonatomic) IBOutlet UILabel *peopleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;*/

//New Memorie celle
@property (weak, nonatomic) IBOutlet UILabel *nbLikesLabel;
@property (weak, nonatomic) IBOutlet UILabel *nbCommentsLabel;
@property (weak, nonatomic) IBOutlet UILabel *nbPhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameEventLabel;
@property (weak, nonatomic) IBOutlet PFImageView *backgroundImage;


@end

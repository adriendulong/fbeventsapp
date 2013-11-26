//
//  OwnerPhotoCell.h
//  FbEvents
//
//  Created by Adrien Dulong on 19/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OwnerPhotoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *ownerImage;
@property (weak, nonatomic) IBOutlet UILabel *ownerName;
@property (weak, nonatomic) IBOutlet UILabel *timeTaken;

@end

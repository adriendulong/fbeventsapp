//
//  ActionPhotoCell.h
//  FbEvents
//
//  Created by Adrien Dulong on 19/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActionPhotoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *nbPhotosButton;

- (IBAction)like:(id)sender;
- (IBAction)more:(id)sender;
- (IBAction)detailLikes:(id)sender;
@end

//
//  FirstMemorieCell.h
//  FbEvents
//
//  Created by Adrien Dulong on 26/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstMemorieCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nbPhotosFound;
@property (weak, nonatomic) IBOutlet UIButton *buttonImport;
@property (weak, nonatomic) IBOutlet UILabel *infosPhotosFound;
@property (weak, nonatomic) IBOutlet UIImageView *imagePreview;



@end

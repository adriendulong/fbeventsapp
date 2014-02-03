//
//  PhotosDatasourceCell.h
//  WYPopoverDemoSegue
//
//  Created by Jérémy on 03/02/2014.
//  Copyright (c) 2014 Nicolas CHENG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotosDatasourceCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *datasourceName;
@property (weak, nonatomic) IBOutlet UILabel *nbPhotos;
@property (weak, nonatomic) IBOutlet UIImageView *lastPhoto;

@end

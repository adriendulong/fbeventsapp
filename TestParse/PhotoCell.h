//
//  PhotoCell.h
//  FbEvents
//
//  Created by Adrien Dulong on 19/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet PFImageView *photoImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loader;

@end

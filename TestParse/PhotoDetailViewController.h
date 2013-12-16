//
//  PhotoDetailViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 18/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PhotoDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
@property (strong, nonatomic) PFObject *photo;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *fbLikers;
@property (weak, nonatomic) IBOutlet UIImageView *imageOwner;
@property (weak, nonatomic) IBOutlet UILabel *nameOwner;


@end

//
//  InvitedListViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 25/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>


@interface InvitedListViewController : UITableViewController

@property (strong, nonatomic) NSArray *invited;
@property (strong, nonatomic) NSMutableArray *attending;
@property (strong, nonatomic) NSMutableArray *maybe;
@property (strong, nonatomic) NSMutableArray *no;
@property (strong, nonatomic) NSMutableArray *notjoined;

@end

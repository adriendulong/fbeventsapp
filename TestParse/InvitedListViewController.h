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

@property (strong, nonatomic) NSMutableArray *invited;
@property (strong, nonatomic) NSMutableArray *attending;
@property (strong, nonatomic) NSMutableArray *maybe;
@property (strong, nonatomic) NSMutableArray *no;
@property (strong, nonatomic) NSMutableArray *notjoined;
@property (strong, nonatomic) PFObject *event;
@property (nonatomic, assign) int nbInvitedToAdd;
@property (nonatomic, assign) int nbInvitedAlreadyAdded;
@property (nonatomic, assign) BOOL hasNext;
@property (strong, nonatomic) NSString *afterCursor;

@end

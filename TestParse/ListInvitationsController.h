//
//  ListInvitationsController.h
//  TestParseAgain
//
//  Created by Adrien Dulong on 31/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>


@interface ListInvitationsController : UITableViewController
@property (nonatomic, strong) NSMutableArray *invitations;
@property (nonatomic, strong) NSMutableArray *declined;
@property (nonatomic, strong) NSMutableArray *objectsForTable;
@property (strong, nonatomic) IBOutlet UITableView *invitationsTable;
@property (weak, nonatomic) IBOutlet UISegmentedControl *listSegmentControll;
@property (strong, nonatomic) NSTimer *timeOfActiveUser;
@property (assign, nonatomic) int countTimer;
@property (weak, nonatomic) IBOutlet UIImageView *refreshImage;
@property (assign, nonatomic) BOOL animating;

- (IBAction)settings:(id)sender;
-(void)loadInvitationFromServer;
-(void)invitationChanged:(NSNotification *) notification;
- (IBAction)listTypeChange:(id)sender;
- (IBAction)refresh:(id)sender;

@end

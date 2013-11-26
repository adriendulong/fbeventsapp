//
//  ListInvitationsController.h
//  TestParseAgain
//
//  Created by Adrien Dulong on 31/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <SDWebImage/UIImageView+WebCache.h>


@interface ListInvitationsController : UITableViewController
@property (nonatomic, strong) NSArray *invitations;
@property (nonatomic, strong) NSArray *declined;
@property (nonatomic, strong) NSArray *objectsForTable;
@property (strong, nonatomic) IBOutlet UITableView *invitationsTable;
@property (weak, nonatomic) IBOutlet UISegmentedControl *listSegmentControll;

- (IBAction)settings:(id)sender;
-(void)loadInvitationFromServer;
-(void)invitationChanged:(NSNotification *) notification;
- (IBAction)listTypeChange:(id)sender;

@end

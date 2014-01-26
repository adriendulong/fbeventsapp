//
//  ListInvitationsController.h
//  TestParseAgain
//
//  Created by Adrien Dulong on 31/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>


@interface ListInvitationsController : UITableViewController <UIActionSheetDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) NSMutableArray *invitations;
@property (nonatomic, strong) NSMutableArray *declined;
@property (nonatomic, strong) NSMutableArray *objectsForTable;
@property (strong, nonatomic) IBOutlet UITableView *invitationsTable;
@property (weak, nonatomic) IBOutlet UISegmentedControl *listSegmentControll;
@property (strong, nonatomic) NSTimer *timeOfActiveUser;
@property (assign, nonatomic) int countTimer;
@property (weak, nonatomic) IBOutlet UIImageView *refreshImage;
@property (assign, nonatomic) BOOL animating;
@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
@property (weak, nonatomic) NSMutableArray *eventWaitingForAnswer;
@property (weak, nonatomic) NSString *answerOccuringId;
@property (weak, nonatomic) NSString *buttonAnswerTitle;
@property (strong, nonatomic) NSMutableArray *removingDeclined;
@property (strong, nonatomic) NSMutableArray *removingInvits;

@property (strong, nonatomic) UIView *viewBack;

- (IBAction)settings:(id)sender;
-(void)loadInvitationFromServer;
-(void)loadDeclinedFromSever;
-(void)invitationChanged:(NSNotification *) notification;
- (IBAction)listTypeChange:(id)sender;
- (IBAction)refresh:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *fbReloadButton;

@end

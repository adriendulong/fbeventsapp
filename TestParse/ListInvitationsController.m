//
//  ListInvitationsController.m
//  TestParseAgain
//
//  Created by Adrien Dulong on 31/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "ListInvitationsController.h"
#import "InvitationCell.h"
#import "EventUtilities.h"
#import "ListEvents.h"
#import "PhotosCollectionViewController.h"
#import "MOUtility.h"
#import "ListEvents.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

@interface ListInvitationsController ()

@end

@implementation ListInvitationsController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HaveFinishedRefreshEvents object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:fakeAnswerEvents object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModifEventsInvitationsAnswers object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RsvpChanged" object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [TestFlight passCheckpoint:@"INVITATIONS"];
    [[Mixpanel sharedInstance] track:@"Invitations View Appear"];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:@"Invitations View"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    //Init
    [self.listSegmentControll setTitle:NSLocalizedString(@"ListInvitationsController_InvitationsNotJoinedSegment", nil) forSegmentAtIndex:0];
    [self.listSegmentControll setTitle:NSLocalizedString(@"ListInvitationsController_InvitationsDeclinedSegment", nil) forSegmentAtIndex:1];
    
    [self isEmptyTableView];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Top icon
    self.topImageView.layer.cornerRadius = 16.0f;
    self.topImageView.layer.masksToBounds = YES;
    
    //Notifications Center
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invitationChanged:)
                                                 name:@"RsvpChanged"
                                               object:nil];
    
    //Init
    self.declined = [[NSMutableArray alloc] init];
    self.invitations = [[NSMutableArray alloc] init];
    self.objectsForTable = [[NSMutableArray alloc] init];
    self.animating = NO;
    
    //[self loadInvitationFromServer];
    //[self loadDeclinedFromSever];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopRefresh) name:HaveFinishedRefreshEvents object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fakeInvitationChanged:) name:fakeAnswerEvents object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadDeclinedFromSever) name:ModifEventsInvitationsAnswers object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.objectsForTable count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    InvitationCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[InvitationCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:CellIdentifier];
    }
    
    //init label
    [cell.rsvpSegmentedControl setTitle:NSLocalizedString(@"UISegmentRSVP_Going", nil) forSegmentAtIndex:0];
    [cell.rsvpSegmentedControl setTitle:NSLocalizedString(@"UISegmentRSVP_Maybe", nil) forSegmentAtIndex:1];
    [cell.rsvpSegmentedControl setTitle:NSLocalizedString(@"UISegmentRSVP_Decline", nil) forSegmentAtIndex:2];
    
    //Get the event object.
    PFObject *event = [self.objectsForTable objectAtIndex:indexPath.row][@"event"];
    PFObject *invitation = [self.objectsForTable objectAtIndex:indexPath.row];
    
    //Date
    NSDate *start_date = event[@"start_time"];
    //Formatter for the hour
    NSDateFormatter *formatterHourMinute = [NSDateFormatter new];
    [formatterHourMinute setDateFormat:@"d MMM - HH:mm"];
    [formatterHourMinute setLocale:[NSLocale currentLocale]];
    
    //Fill the cell
    cell.nameLabel.text = event[@"name"];
    cell.whenWhereLabel.text = (event[@"location"] == nil) ? [NSString stringWithFormat:@"%@", [formatterHourMinute stringFromDate:start_date]] : [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_WhenWhere", nil), [formatterHourMinute stringFromDate:start_date], event[@"location"]];
    cell.ownerInvitationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_SendInvit", nil), event[@"owner"][@"name"]];
    
    // Add a nice corner radius to the image
    cell.profilImageView.layer.cornerRadius = 24.0f;
    cell.profilImageView.layer.masksToBounds = YES;
    
    //Profile picture
    [cell.profilImageView setImageWithURL:[MOUtility UrlOfFacebooProfileImage:event[@"owner"][@"id"] withResolution:FacebookNormalProfileImage]
                        placeholderImage:[UIImage imageNamed:@"profil_default"]];
    
    //Assign the event Id
    cell.invitation = [self.objectsForTable objectAtIndex:indexPath.row];
    
    //Init the segment controll if declined
    if ([invitation[@"rsvp_status"] isEqualToString:@"declined"]) {
        [cell.rsvpSegmentedControl setSelectedSegmentIndex:2];
    }
    else{
        [cell.rsvpSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    }
    
    [cell.activityIndicator setHidden:YES];
    
    return cell;
}



/*
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Foo", @"Bar"]];
    //segmentedControl.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];
    return self.headerView;
}
*/
/*
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 50;
}*/

#pragma mark - Server interactions

-(void)loadInvitationFromServer{
    NSLog(@"Load Future Events");
    
    //Load Invitation from local database
    self.invitations = [[MOUtility getFuturInvitationNotReplied] mutableCopy];
    if(self.listSegmentControll.selectedSegmentIndex==0){
        self.objectsForTable = self.invitations;
        [self isEmptyTableView];
        [self.tableView reloadData];
    }
    
    PFQuery *queryEvents = [PFQuery queryWithClassName:@"Event"];
    [queryEvents whereKey:@"start_time" greaterThanOrEqualTo:[NSDate date]];
    [queryEvents orderByAscending:@"start_time"];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"rsvp_status" equalTo:FacebookEventNotReplied];
    [query whereKey:@"event" matchesQuery:queryEvents];
    [query includeKey:@"event"];
    
    #warning Modify Cache Policy
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [self.invitations removeAllObjects];
            
            self.invitations = [[MOUtility sortByStartDate:[objects mutableCopy] isAsc:YES] mutableCopy];
            [[Mixpanel sharedInstance].people  set:@{@"Nb Invitations": [NSNumber numberWithInt:self.invitations.count]}];
            
            //Save in local database
            for(PFObject *invitation in objects){
                [MOUtility saveInvitationWithEvent:invitation];
            }
            
            if(self.listSegmentControll.selectedSegmentIndex==0){
                self.objectsForTable = self.invitations;
                [self isEmptyTableView];
                [self.tableView reloadData];
            }
        } else {
            // Log details of the failure
            NSLog(@"Problème de chargement");
        }
    }];
}


//Get all the declined events
-(void)loadDeclinedFromSever{
    NSLog(@"Load Declined Events");
    
    self.declined = [[MOUtility getFuturInvitationDeclined] mutableCopy];
    if(self.listSegmentControll.selectedSegmentIndex==1){
        self.objectsForTable = self.declined;
        [self isEmptyTableView];
        [self.tableView reloadData];
    }
    
    PFQuery *queryEvents = [PFQuery queryWithClassName:@"Event"];
    [queryEvents whereKey:@"start_time" greaterThanOrEqualTo:[NSDate date]];
    [queryEvents orderByAscending:@"start_time"];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"rsvp_status" equalTo:FacebookEventDeclined];
    [query whereKey:@"event" matchesQuery:queryEvents];
    [query includeKey:@"event"];
    
    #warning Modify Cache Policy
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.declined = [[MOUtility sortByStartDate:[objects mutableCopy] isAsc:YES] mutableCopy];
            
            //Save in local databse
            for(PFObject *invitation in objects){
                [MOUtility saveInvitationWithEvent:invitation];
            }
            
            if(self.listSegmentControll.selectedSegmentIndex==1){
                self.objectsForTable = self.declined;
                [self isEmptyTableView];
                [self.tableView reloadData];
            }
        } else {
            // Log details of the failure
            NSLog(@"Problème de chargement");
        }
    }];
}


# pragma mark Segment results

-(void)invitationChanged:(NSNotification *) notification{
    BOOL isSuccess = [notification.userInfo[@"isSuccess"] boolValue];
    
    
    
    if (!isSuccess) {
        //find position invitation
        for(PFObject *invitation in self.objectsForTable){
            if ([invitation.objectId isEqualToString:notification.userInfo[@"invitationId"]]) {
                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Problem_Title", nil) message:NSLocalizedString(@"ListInvitationsController_ProblemChangingInvitation", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
        [alert show];
    }
    else{
        int i=0;
        int positionToRemove = 0;
        BOOL stillHere = NO;
        for(PFObject *invitation in self.objectsForTable){
            if ([invitation.objectId isEqualToString:notification.userInfo[@"invitationId"]]) {
                positionToRemove = i;
                stillHere = YES;
                break;
            }
            i++;
        }
        
        if (stillHere) {
            if (self.listSegmentControll.selectedSegmentIndex == 0) {
                [self.invitations removeObjectAtIndex:positionToRemove];
                [[Mixpanel sharedInstance] track:@"RSVP Invitation" properties:@{@"Answer": notification.userInfo[@"rsvp"], @"Nb Invitations Now" : [NSNumber numberWithInt:self.invitations.count]}];
                [[Mixpanel sharedInstance].people  set:@{@"Nb Invitations": [NSNumber numberWithInt:self.invitations.count]}];
            }
            else{
                [self.declined removeObjectAtIndex:positionToRemove];
                [[Mixpanel sharedInstance] track:@"RSVP Declined" properties:@{@"Answer": notification.userInfo[@"rsvp"], @"Nb Declined Now" : [NSNumber numberWithInt:self.invitations.count]}];
            }
            
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:positionToRemove inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self isEmptyTableView];
        }
        
        
        if ([notification.userInfo[@"rsvp"] isEqualToString:FacebookEventAttending] || [notification.userInfo[@"rsvp"] isEqualToString:FacebookEventMaybeAnswer]) {
            //Animation tab Evenements
            self.countTimer = 0;
            self.timeOfActiveUser = [NSTimer scheduledTimerWithTimeInterval:0.3  target:self selector:@selector(actionTimer) userInfo:nil repeats:YES];
        }
        else{
            [self loadDeclinedFromSever];
        }
    }
    
    [EventUtilities setBadgeForInvitation:self.tabBarController atIndex:1];
    
    //We reload the list in the future events
    ListEvents *eventsController =  (ListEvents *)[[[[self.tabBarController viewControllers] objectAtIndex:0] viewControllers] objectAtIndex:0];
    [eventsController loadFutureEventsFromServer];
}


-(void)fakeInvitationChanged:(NSNotification *)notification{
    
    [self postReponseMessage:notification];
    
    int i=0;
    int positionToRemove = 0;
    for(PFObject *invitation in self.objectsForTable){
        if ([invitation.objectId isEqualToString:notification.userInfo[@"invitationId"]]) {
            positionToRemove = i;
            break;
        }
        i++;
    }
    
    //Remove it
    //[self.objectsForTable removeObjectAtIndex:positionToRemove];
    if (self.listSegmentControll.selectedSegmentIndex == 0) {
        [self.invitations removeObjectAtIndex:positionToRemove];
        [[Mixpanel sharedInstance] track:@"RSVP Invitation" properties:@{@"Answer": notification.userInfo[@"rsvp"], @"Nb Invitations Now" : [NSNumber numberWithInt:self.invitations.count]}];
        [[Mixpanel sharedInstance].people  set:@{@"Nb Invitations": [NSNumber numberWithInt:self.invitations.count]}];
    }
    else{
        [self.declined removeObjectAtIndex:positionToRemove];
        [[Mixpanel sharedInstance] track:@"RSVP Declined" properties:@{@"Answer": notification.userInfo[@"rsvp"], @"Nb Declined Now" : [NSNumber numberWithInt:self.invitations.count]}];
    }
    
    //reload
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:positionToRemove inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    [self isEmptyTableView];
    
    
}

- (IBAction)listTypeChange:(id)sender {
    if (self.listSegmentControll.selectedSegmentIndex == 0) {
        [TestFlight passCheckpoint:@"SEE_NOT_JOINED"];
        [[Mixpanel sharedInstance] track:@"Click Segement Invitations"];
        
        self.objectsForTable = self.invitations;
        [self isEmptyTableView];
        [self.tableView reloadData];
    }
    else{
        [TestFlight passCheckpoint:@"SEE_DECLINED"];
        [[Mixpanel sharedInstance] track:@"Click Segement Declined"];
        
        self.objectsForTable = self.declined;
        [self isEmptyTableView];
        [self.tableView reloadData];
    }
}



#pragma mark - Navigation

 
 -(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
     if ([segue.identifier isEqualToString:@"DetailEvent"]) {
         [[Mixpanel sharedInstance] track:@"Click Detail Event" properties:@{@"From": @"Invitations View"}];
         
         self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
 
         //Selected row
         NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
 
 
         PhotosCollectionViewController *photosCollectionViewController = segue.destinationViewController;
         photosCollectionViewController.invitation = [self.self.objectsForTable objectAtIndex:selectedRowIndex.row];
         photosCollectionViewController.hidesBottomBarWhenPushed = YES;
    }
     else if ([segue.identifier isEqualToString:@"Login"]){

     }
 
 }

-(void)actionTimer{
    if (self.countTimer%2==0) {
        [[self.tabBarController.tabBar.items objectAtIndex:0] setFinishedSelectedImage:[UIImage imageNamed:@"my_events_on.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"my_events_on.png"]];
    }
    else{
        [[self.tabBarController.tabBar.items objectAtIndex:0] setFinishedSelectedImage:[UIImage imageNamed:@"my_events_on.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"my_events_off.png"]];
    }
    
    self.countTimer++;
    if (self.countTimer > 5) {
        [self.timeOfActiveUser invalidate];
        self.timeOfActiveUser = nil;
    }
}


- (IBAction)refresh:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ModifEventsInvitationsAnswers object:self];
    [self.activityIndicator setHidden:NO];
    [self.refreshImage setHidden:YES];
    [self.fbReloadButton setEnabled:NO];
}


-(void)isEmptyTableView{
    
    self.viewBack = [[UIView alloc] initWithFrame:self.view.frame];
    
    //Image
    UIImage *image = [UIImage imageNamed:@"marmotte_invit_empty"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [imageView setImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    [self.viewBack addSubview:imageView];
    
    //Label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(18, 370, 285, 60)];
    [label setTextColor:[UIColor darkGrayColor]];
    [label setNumberOfLines:2];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.text = (self.listSegmentControll.selectedSegmentIndex == 0) ? NSLocalizedString(@"ListInvitationsController_NoPendingInvitation", nil) : NSLocalizedString(@"ListInvitationsController_NoRefuseInvitation", nil);
    [self.viewBack addSubview:label];
    
    if (!self.objectsForTable) {
        self.tableView.backgroundView = self.viewBack;
    }
    else if(self.objectsForTable.count==0){
        self.tableView.backgroundView = self.viewBack;
    }
    else{
        self.tableView.backgroundView = nil;
    }
    
}

-(void)postReponseMessage:(NSNotification *)notification{
    NSString *title;
    NSString *messageOne;
    NSString *messageTwo;
    NSString *messageThree;
    NSString *messageFour;
    
    self.answerOccuringId = notification.userInfo[@"eventId"];
    
    if ([notification.userInfo[@"rsvp"] isEqualToString:FacebookEventAttending]) {
        title = NSLocalizedString(@"ListInvitationsController_TitleActionSheetPositive", nil);
        messageOne = NSLocalizedString(@"ListInvitationsController_BodyAttendingMessage1", nil);
        messageTwo = NSLocalizedString(@"ListInvitationsController_BodyAttendingMessage2", nil);
        messageThree = NSLocalizedString(@"ListInvitationsController_BodyAttendingMessage3", nil);
        messageFour = NSLocalizedString(@"ListInvitationsController_BodyAttendingMessage4", nil);
    }
    else if([notification.userInfo[@"rsvp"] isEqualToString:FacebookEventMaybeAnswer]){
        title = NSLocalizedString(@"ListInvitationsController_TitleActionSheetMaybe", nil);
        messageOne = NSLocalizedString(@"ListInvitationsController_BodyMaybeMessage1", nil);
        messageTwo = NSLocalizedString(@"ListInvitationsController_BodyMaybeMessage2", nil);
        messageThree = NSLocalizedString(@"ListInvitationsController_BodyMaybeMessage3", nil);
        messageFour = NSLocalizedString(@"ListInvitationsController_BodyMaybeMessage4", nil);
    }
    else{
        title = NSLocalizedString(@"ListInvitationsController_TitleActionSheetDeclined", nil);
        messageOne = NSLocalizedString(@"ListInvitationsController_BodyDeclinedMessage1", nil);
        messageTwo = NSLocalizedString(@"ListInvitationsController_BodyDeclinedMessage2", nil);
        messageThree = NSLocalizedString(@"ListInvitationsController_BodyDeclinedMessage3", nil);
        messageFour = NSLocalizedString(@"ListInvitationsController_BodyDeclinedMessage4", nil);
    }
    
    
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"UIActionSheet_Skip", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:messageOne, messageTwo, messageThree, messageFour, nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (buttonIndex!=4) {
        if (([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound)|| ([FBSession.activeSession.permissions indexOfObject:@"publish_stream"] == NSNotFound)) {
            self.buttonAnswerTitle = buttonTitle;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Auth_Title", nil)
                                                                message:NSLocalizedString(@"UIAlertView_postMessageFacebok", nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"UIAlertView_Cancel", nil)
                                                      otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
            [alertView show];
        }
        else{
            [MOUtility postRSVP:self.answerOccuringId withMessage:buttonTitle];
        }
        
        
    }
}

-(void)stopRefresh{
    [self.activityIndicator setHidden:YES];
    [self.refreshImage setHidden:NO];
    [self.fbReloadButton setEnabled:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == [alertView cancelButtonIndex]) {
        
    }else{
        [MOUtility postRSVP:self.answerOccuringId withMessage:self.buttonAnswerTitle];
    }
}



@end

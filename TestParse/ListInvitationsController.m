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
#import "PDGestureTableView.h"

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

    UIColor *greyColor = [UIColor colorWithRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1];
    [self.tableView setBackgroundColor:greyColor];
    
    //Notifications Center
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invitationChanged:)
                                                 name:@"RsvpChanged"
                                               object:nil];
    
    //Init
    self.declined = [[NSMutableArray alloc] init];
    self.invitations = [[NSMutableArray alloc] init];
    self.objectsForTable = [[NSMutableArray alloc] init];
    self.removingDeclined = [[NSMutableArray alloc] init];
    self.removingInvits = [[NSMutableArray alloc] init];
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

    //Get the event object.
    PFObject *event = [self.objectsForTable objectAtIndex:indexPath.row][@"event"];
    PFObject *invitation = [self.objectsForTable objectAtIndex:indexPath.row];
    
    //Init the segment controll if declined
    if ([invitation[@"rsvp_status"] isEqualToString:@"declined"]) {
        [cell.rsvpSegmentedControl setSelectedSegmentIndex:2];
    }
    else{
        [cell.rsvpSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    }
    
    UIColor *greenColor = [UIColor colorWithRed:130.0/255.0 green:197.0/255.0 blue:56.0/255.0 alpha:1];
    UIColor *blueColor = [UIColor colorWithRed:41.0/255.0 green:128.0/255.0 blue:185.0/255.0 alpha:1];
    UIColor *redColor = [UIColor colorWithRed:192.0/255.0 green:57.0/255.0 blue:43.0/255.0 alpha:1];
    
    cell.firstLeftAction = [PDGestureTableViewCellAction
                            actionWithIcon:[UIImage imageNamed:@"check_little"]
                            color:greenColor
                            fraction:0.20
                            didTriggerBlock:^(PDGestureTableView *gestureTableView, PDGestureTableViewCell *cell) {
                                // Action for first left action triggering.
                                
                                PFObject *invitation;
                                if (self.listSegmentControll.selectedSegmentIndex == 0) {
                                    invitation = self.invitations[indexPath.row];
                                    [self.removingInvits addObject:self.invitations[indexPath.row]];
                                    [self.objectsForTable removeObjectAtIndex:indexPath.row];
                                    
                                }
                                else{
                                    invitation = self.declined[indexPath.row];
                                    NSLog(@"IndexPath %i",indexPath.row);
                                    [self.removingDeclined addObject:self.declined[indexPath.row]];
                                    [self.objectsForTable removeObjectAtIndex:indexPath.row];
                                    
                                }
                                
                                
                                NSDictionary *userInfo = @{@"invitationId": invitation.objectId,
                                                           @"rsvp": FacebookEventAttending, @"eventId" : invitation[@"event"][@"eventId"]};
                                

                                
                                [gestureTableView removeCell:cell completion:^{
                                    NSLog(@"Cell removed!");
                                    [self.tableView reloadData];
                                    
                                    //[[NSNotificationCenter defaultCenter] postNotificationName:fakeAnswerEvents object:self userInfo:userInfo];
                                    [self RsvpToFbEvent:invitation[@"event"][@"eventId"] withRsvp:FacebookEventAttending withInvitation:invitation];
                                    
                                    [self isEmptyTableView];
                                }];
                                
                            }];
    
    cell.secondLeftAction = [PDGestureTableViewCellAction
                            actionWithIcon:[UIImage imageNamed:@"question"]
                            color:blueColor
                            fraction:0.65
                            didTriggerBlock:^(PDGestureTableView *gestureTableView, PDGestureTableViewCell *cell) {
                                // Action for first left action triggering.
                                
                                
                                PFObject *invitation;
                                if (self.listSegmentControll.selectedSegmentIndex == 0) {
                                    invitation = self.invitations[indexPath.row];
                                    [self.removingInvits addObject:self.invitations[indexPath.row]];
                                    [self.objectsForTable removeObjectAtIndex:indexPath.row];
                                    
                                }
                                else{
                                    invitation = self.declined[indexPath.row];
                                    NSLog(@"IndexPath %i",indexPath.row);
                                    [self.removingDeclined addObject:self.declined[indexPath.row]];
                                    [self.objectsForTable removeObjectAtIndex:indexPath.row];
                                    
                                }
                                
                                
                                NSDictionary *userInfo = @{@"invitationId": invitation.objectId,
                                                           @"rsvp": FacebookEventMaybeAnswer, @"eventId" : invitation[@"event"][@"eventId"]};

                                
                                [gestureTableView removeCell:cell completion:^{
                                    NSLog(@"Cell removed!");
                                    [self.tableView reloadData];
                                    
                                    //[[NSNotificationCenter defaultCenter] postNotificationName:fakeAnswerEvents object:self userInfo:userInfo];
                                    [self RsvpToFbEvent:invitation[@"event"][@"eventId"] withRsvp:FacebookEventMaybeAnswer withInvitation:invitation];
                                    
                                    [self isEmptyTableView];
                                }];
                                
                            }];
    
    if (self.listSegmentControll.selectedSegmentIndex == 0) {
        cell.firstRightAction = [PDGestureTableViewCellAction
                                 actionWithIcon:[UIImage imageNamed:@"cross"]
                                 color:redColor
                                 fraction:0.25
                                 didTriggerBlock:^(PDGestureTableView *gestureTableView, PDGestureTableViewCell *cell) {
                                     // Action for first left action triggering.
                                     
                                     PFObject *invitation;
                                     invitation = self.invitations[indexPath.row];
                                     [self.removingInvits addObject:self.invitations[indexPath.row]];
                                     [self.objectsForTable removeObjectAtIndex:indexPath.row];
                                     
                                     
                                     
                                     NSDictionary *userInfo = @{@"invitationId": invitation.objectId,
                                                                @"rsvp": FacebookEventDeclined, @"eventId" : invitation[@"event"][@"eventId"]};
                                     
                                     [gestureTableView removeCell:cell completion:^{
                                         NSLog(@"Cell removed!");
                                         [self.tableView reloadData];
                                         
                                         //[[NSNotificationCenter defaultCenter] postNotificationName:fakeAnswerEvents object:self userInfo:userInfo];
                                         [self RsvpToFbEvent:invitation[@"event"][@"eventId"] withRsvp:FacebookEventDeclined withInvitation:invitation];
                                         
                                         [self isEmptyTableView];
                                     }];
                                     
                                     
                                 }];
    }
    else{
        cell.firstRightAction = nil;
    }
    

    
    
    
    //init label
    [cell.rsvpSegmentedControl setTitle:NSLocalizedString(@"UISegmentRSVP_Going", nil) forSegmentAtIndex:0];
    [cell.rsvpSegmentedControl setTitle:NSLocalizedString(@"UISegmentRSVP_Maybe", nil) forSegmentAtIndex:1];
    [cell.rsvpSegmentedControl setTitle:NSLocalizedString(@"UISegmentRSVP_Decline", nil) forSegmentAtIndex:2];
    
    
    
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
    
    /*PFQuery *queryEvents = [PFQuery queryWithClassName:@"Event"];
    [queryEvents whereKey:@"start_time" greaterThanOrEqualTo:[NSDate date]];
    [queryEvents orderByAscending:@"start_time"];*/
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"rsvp_status" equalTo:FacebookEventNotReplied];
    [query whereKey:@"start_time" greaterThanOrEqualTo:[NSDate date]];
    [query includeKey:@"event"];
    [query orderByAscending:@"start_time"];
    
    #warning Modify Cache Policy
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [self.invitations removeAllObjects];
            
            self.invitations = [objects mutableCopy];
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
    
    /*PFQuery *queryEvents = [PFQuery queryWithClassName:@"Event"];
    [queryEvents whereKey:@"start_time" greaterThanOrEqualTo:[NSDate date]];
    [queryEvents orderByAscending:@"start_time"];*/
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"rsvp_status" equalTo:FacebookEventDeclined];
    [query whereKey:@"start_time" greaterThanOrEqualTo:[NSDate date]];
    [query includeKey:@"event"];
    [query orderByAscending:@"start_time"];
    
    
    #warning Modify Cache Policy
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.declined = [objects mutableCopy];
            
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
    
    BOOL isInDeclined = NO;
    
    
    
    //If not success we put back the row
    if (!isSuccess) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Problem_Title", nil) message:NSLocalizedString(@"ListInvitationsController_ProblemChangingInvitation", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
        [alert show];
        
        
        //It was in declined or invits ?
        for (int i=0; i<self.removingDeclined.count; i++) {
            PFObject *declinedInvit = self.removingDeclined[i];
            if ([declinedInvit.objectId isEqualToString:notification.userInfo[@"invitationId"]]) {
                isInDeclined = YES;
                [self.declined addObject:declinedInvit];
                //[self.objectsForTable addObject:declinedInvit];
                
                if (self.listSegmentControll.selectedSegmentIndex == 1) {
                    //[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                }
                
                break;
            }
        }
        
        if (!isInDeclined) {
            for (int i=0; i<self.removingInvits.count; i++) {
                PFObject *invit = self.removingInvits[i];
                if ([invit.objectId isEqualToString:notification.userInfo[@"invitationId"]]) {
                    [self.invitations addObject:invit];
                    //[self.objectsForTable addObject:invit];
                    
                    if (self.listSegmentControll.selectedSegmentIndex == 1) {
                        //[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                    }
                    
                    break;
                }
            }
        }
        
        
        
    }
    //else we remove the element from the good array
    else{
        PFObject *invitation;
        
        for (int i=0; i<self.removingDeclined.count; i++) {
            PFObject *declinedInvit = self.removingDeclined[i];
            if ([declinedInvit.objectId isEqualToString:notification.userInfo[@"invitationId"]]) {
                isInDeclined = YES;
                invitation = declinedInvit;
                
                break;
            }
        }
        
        
        if (!isInDeclined) {
            for (int i=0; i<self.removingInvits.count; i++) {
                PFObject *invit = self.removingInvits[i];
                if ([invit.objectId isEqualToString:notification.userInfo[@"invitationId"]]) {
                    invitation = invit;
                    
                    break;
                }
                
            }
            [[Mixpanel sharedInstance] track:@"RSVP Invitation" properties:@{@"Answer": notification.userInfo[@"rsvp"], @"Nb Invitations Now" : [NSNumber numberWithInt:self.invitations.count]}];
            [[Mixpanel sharedInstance].people  set:@{@"Nb Invitations": [NSNumber numberWithInt:self.invitations.count]}];
            [self.removingInvits removeObject:invitation];
        }
        else{
            [self.removingDeclined removeObject:invitation];
            [[Mixpanel sharedInstance] track:@"RSVP Declined" properties:@{@"Answer": notification.userInfo[@"rsvp"], @"Nb Declined Now" : [NSNumber numberWithInt:self.invitations.count]}];
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
    PFObject *invitation;
    NSLog(@"%@",notification.userInfo[@"invitationId"]);
    BOOL hasToDelete = NO;
    
    for(PFObject *invitationLoop in self.objectsForTable){
        if ([invitationLoop.objectId isEqualToString:notification.userInfo[@"invitationId"]]) {
            invitation = invitationLoop;
            hasToDelete = YES;
            break;
        }
    }
    
    if (hasToDelete) {
        [self.objectsForTable removeObject:invitation];
        [self postReponseMessage:notification];
        [self.tableView reloadData];
    }
    
    
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
            [[Mixpanel sharedInstance] track:@"Post Answer" properties:@{@"Answer": buttonTitle}];
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
        [[Mixpanel sharedInstance] track:@"Post Answer" properties:@{@"Answer": self.buttonAnswerTitle}];
    }
}



////////
// RSVP To Fb Events
///////

-(void)RsvpToFbEvent:(NSString *)fbId withRsvp:(NSString *)rsvp withInvitation:(PFObject *)invitation{
    
    
    NSString *requestString = [NSString stringWithFormat:@"%@/%@", fbId, rsvp];
    FBRequest *request = [FBRequest requestWithGraphPath:requestString parameters:nil HTTPMethod:@"POST"];
    
    __block NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]initWithCapacity:3];
    [userInfo setObject:invitation.objectId forKey:@"invitationId"];
    [userInfo setObject:rsvp forKey:@"rsvp"];
    
    
    if ([FBSession.activeSession.permissions indexOfObject:@"rsvp_event"] == NSNotFound) {
         ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).comeFromFB = YES;
        [FBSession.activeSession requestNewPublishPermissions:@[@"rsvp_event"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                if (!error) {
                                                     ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).comeFromFB = NO;
                                                    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                        if (!error) {
                                                            NSLog(@"%@", result);
                                                            
                                                            if (result[@"FACEBOOK_NON_JSON_RESULT"]) {
                                                                NSLog(@"OK !!");
                                                                //Save the new rsvp
                                                                NSString *oldRsvp = invitation[@"rsvp_status"];
                                                                invitation[@"rsvp_status"] = rsvp;
                                                                [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                                    if(!error){
                                                                        //Warn the table view controller
                                                                        [MOUtility setRsvp:rsvp forInvitation:invitation.objectId];
                                                                        [userInfo setObject:@YES forKey:@"isSuccess"];
                                                                        [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                                                                    }
                                                                    else{
                                                                        invitation[@"rsvp_status"] = oldRsvp;
                                                                        [userInfo setObject:@NO forKey:@"isSuccess"];
                                                                        [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                                                                    }
                                                                }];
                                                            }
                                                            
                                                        }
                                                        else{
                                                            [userInfo setObject:@NO forKey:@"isSuccess"];
                                                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                                                        }
                                                    }];
                                                } else if (error.fberrorCategory != FBErrorCategoryUserCancelled){
                                                     ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).comeFromFB = NO;
                                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission denied"
                                                                                                        message:@"Unable to get permission to post"
                                                                                                       delegate:nil
                                                                                              cancelButtonTitle:@"OK"
                                                                                              otherButtonTitles:nil];
                                                    [alertView show];
                                                    
                                                }
                                            }];
    }
    else{
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                NSLog(@"%@", result);
                
                if (result[@"FACEBOOK_NON_JSON_RESULT"]) {
                    NSLog(@"OK !!");
                    //Save the new rsvp
                    NSString *oldRsvp = invitation[@"rsvp_status"];
                    invitation[@"rsvp_status"] = rsvp;
                    [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if(!error){
                            //Warn the table view controller
                            [MOUtility setRsvp:rsvp forInvitation:invitation.objectId];
                            [userInfo setObject:@YES forKey:@"isSuccess"];
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                        }
                        else{
                            invitation[@"rsvp_status"] = oldRsvp;
                            [userInfo setObject:@NO forKey:@"isSuccess"];
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                        }
                    }];
                }
                
            }
            else{
                [userInfo setObject:@NO forKey:@"isSuccess"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
            }
        }];
    }
}



@end

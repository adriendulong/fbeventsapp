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
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [TestFlight passCheckpoint:@"INVITATIONS"];
    
    
    [self loadInvitationFromServer];
    [self loadDeclinedFromSever];
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopRefresh:) name:HaveFinishedRefreshEvents object:nil];
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
    
    //Date
    NSDate *start_date = event[@"start_time"];
    //Formatter for the hour
    NSDateFormatter *formatterHourMinute = [NSDateFormatter new];
    [formatterHourMinute setDateFormat:@"HH:mm"];
    NSDateFormatter *formatterMonth = [NSDateFormatter new];
    [formatterMonth setDateFormat:@"MMM"];
    NSDateFormatter *formatterDay = [NSDateFormatter new];
    [formatterDay setDateFormat:@"d"];
    
    //Fill the cell
    cell.nameLabel.text = event[@"name"];
    cell.whenWhereLabel.text = (event[@"location"] == nil) ? [NSString stringWithFormat:@"%@", [formatterHourMinute stringFromDate:start_date]] : [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_WhenWhere", nil), [formatterHourMinute stringFromDate:start_date], event[@"location"]];
    cell.ownerInvitationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_SendInvit", nil), event[@"owner"][@"name"]];
    //cell.monthLabel.text = [NSString stringWithFormat:@"%@", [formatterMonth stringFromDate:start_date]];
    //cell.dayLabel.text = [NSString stringWithFormat:@"%@", [formatterDay stringFromDate:start_date]];
    
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
            self.invitations = [[MOUtility sortByStartDate:[objects mutableCopy] isAsc:YES] mutableCopy];
            
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
            else{
                if([self.invitations count] == 0){
                    //[self.listSegmentControll setSelectedSegmentIndex:1];
                    self.objectsForTable = self.declined;
                }
            }
        } else {
            // Log details of the failure
            NSLog(@"Problème de chargement");
        }
    }];
}


# pragma mark Segment results

-(void)invitationChanged:(NSNotification *) notification{
    //find position invitation
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
    }
    else{
        [self.declined removeObjectAtIndex:positionToRemove];
    }
    
    //reload
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:positionToRemove inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    [self isEmptyTableView];
    
    NSLog(@"RSVP : %@", notification.userInfo[@"rsvp"]);
    if ([notification.userInfo[@"rsvp"] isEqualToString:FacebookEventAttending] || [notification.userInfo[@"rsvp"] isEqualToString:FacebookEventMaybeAnswer]) {
        //Animation tab Evenements
        self.countTimer = 0;
        self.timeOfActiveUser = [NSTimer scheduledTimerWithTimeInterval:0.3  target:self selector:@selector(actionTimer) userInfo:nil repeats:YES];
    }
    
    
    /*
    NSLog(@"DETECT PROTOCOL");
    [self loadInvitationFromServer];
    [self loadDeclinedFromSever];*/
    [EventUtilities setBadgeForInvitation:self.tabBarController atIndex:1];
    
    //We reload the list in the future events
    ListEvents *eventsController =  (ListEvents *)[[[[self.tabBarController viewControllers] objectAtIndex:0] viewControllers] objectAtIndex:0];
    [eventsController loadFutureEventsFromServer];
}

- (IBAction)listTypeChange:(id)sender {
     NSLog(@"Changed : %i", self.listSegmentControll.selectedSegmentIndex);
    if (self.listSegmentControll.selectedSegmentIndex == 0) {
        [TestFlight passCheckpoint:@"SEE_NOT_JOINED"];
        
        self.objectsForTable = self.invitations;
        [self isEmptyTableView];
        [self.tableView reloadData];
    }
    else{
        [TestFlight passCheckpoint:@"SEE_DECLINED"];
        
        self.objectsForTable = self.declined;
        [self isEmptyTableView];
        [self.tableView reloadData];
    }
}



#pragma mark - Navigation

 
 -(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
     if ([segue.identifier isEqualToString:@"DetailEvent"]) {
 
         self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
 
         //Selected row
         NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
 
 
         PhotosCollectionViewController *photosCollectionViewController = segue.destinationViewController;
         photosCollectionViewController.invitation = [self.self.objectsForTable objectAtIndex:selectedRowIndex.row];
         photosCollectionViewController.hidesBottomBarWhenPushed = YES;
    }
     else if ([segue.identifier isEqualToString:@"Login"]){
         NSLog(@"LOGOUT LIST");
         /*
         UINavigationController *navController = (UINavigationController *)[self.tabBarController.viewControllers objectAtIndex:0];
         ListEvents *listEvents = (ListEvents *)[navController.viewControllers objectAtIndex:0];
         listEvents.invitations = nil;
         [listEvents.tableView reloadData];
         LoginViewController *loginViewController = segue.destinationViewController;
         loginViewController.myDelegate = listEvents;
         
         [MOUtility logoutApp];*/
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

#pragma mark - Animate Button Refresh

- (void) spinWithOptions: (UIViewAnimationOptions) options {
    // this spin completes 360 degrees every 2 seconds
    [UIView animateWithDuration: 0.5f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         self.refreshImage.transform = CGAffineTransformRotate(self.refreshImage.transform, M_PI / 2);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if (self.animating) {
                                 // if flag still set, keep spinning with constant speed
                                 [self spinWithOptions: UIViewAnimationOptionCurveLinear];
                             } else if (options != UIViewAnimationOptionCurveEaseOut) {
                                 // one last spin, with deceleration
                                 [self spinWithOptions: UIViewAnimationOptionCurveEaseOut];
                             }
                         }
                     }];
}

- (void) startSpin {
    if (!self.animating) {
        self.animating = YES;
        [self spinWithOptions: UIViewAnimationOptionCurveEaseIn];
    }
}

-(void)stopRefresh:(Notification *)note{
    self.animating = NO;
}

- (void) stopSpin {
    // set the flag to stop spinning after one last 90 degree increment
    self.animating = NO;
}

- (IBAction)refresh:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ModifEventsInvitationsAnswers object:self];
    [self startSpin];
}


-(void)isEmptyTableView{
    
    if (self.listSegmentControll.selectedSegmentIndex == 0) {
        UIView *viewBack = [[UIView alloc] initWithFrame:self.view.frame];
        
        //Image
        UIImage *image = [UIImage imageNamed:@"marmotte_victoire"];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
        [imageView setImage:image];
        imageView.contentMode = UIViewContentModeCenter;
        [viewBack addSubview:imageView];
        
        //Label
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(18, 370, 285, 60)];
        [label setTextColor:[UIColor darkGrayColor]];
        [label setNumberOfLines:2];
        [label setTextAlignment:NSTextAlignmentCenter];
        label.text = @"Yeah !!!\nPlus aucunes invitations en attente !";
        [viewBack addSubview:label];
        
        if (!self.objectsForTable) {
            self.tableView.backgroundView = viewBack;
        }
        else if(self.objectsForTable.count==0){
            self.tableView.backgroundView = viewBack;
        }
        else{
            self.tableView.backgroundView = nil;
        }
    }
    
}



@end

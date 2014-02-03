//
//  ListEvents.m
//  TestParse
//
//  Created by Adrien Dulong on 25/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "ListEvents.h"
#import "EventsCell.h"
#import "MOUtility.h"
#import "EventUtilities.h"
#import "FbEventsUtilities.h"
#import "TestParseAppDelegate.h"
#import "EventDetailViewController.h"
#import "PhotosCollectionViewController.h"
#import "ListInvitationsController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"


@interface ListEvents ()

@end

@implementation ListEvents

@synthesize invitations;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FacebookEventUploaded" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LogOutUser object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LogInUser object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModifEventsInvitationsAnswers object:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    
    if (!self.isBackgroundTask) {
        [TestFlight passCheckpoint:@"MY_EVENTS"];
        [[Mixpanel sharedInstance] track:@"Event View Appear"];
        
        id tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:kGAIScreenName
               value:@"Events View"];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    }
    
}

-(void)viewDidAppear:(BOOL)animated{
    if (self.isNewUser) {
        self.isNewUser = NO;
        [self performSegueWithIdentifier:@"CountEvents" sender:nil];
    }
}


- (void)viewDidLoad
{
    
    //Top icon
    self.topImageView.layer.cornerRadius = 17.0f;
    self.topImageView.layer.masksToBounds = YES;
    
    UIColor *greyColor = [UIColor colorWithRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1];
    [self.tableView setBackgroundColor:greyColor];
    
    
    //Refresh view
    self.animating = NO;
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    refreshControl.tintColor = [UIColor orangeColor];
    [refreshControl addTarget:self action:@selector(fbReload:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    //Init Notif number
    UIButton *buttonNotif = (UIButton *)[[self.navigationController.navigationBar viewWithTag:9] viewWithTag:10];
    NSString *notifMessage = [NSString stringWithFormat:NSLocalizedString(@"ListEvents_Notifs", nil), [MOUtility nbNewNotifs]];
    [buttonNotif setTitle:notifMessage forState:UIControlStateNormal];
    
    [super viewDidLoad];
    
    //Init badge of invitations
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(oneFacebookEventUpdated:) name:@"FacebookEventUploaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadFutureEventsFromServer) name:ModifEventsInvitationsAnswers object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logOut:) name:LogOutUser object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logIn:) name:LogInUser object:nil];
    
    //init
    self.facebookEventsNbDone = 0;
    self.facebookEventNotRepliedDone = 0;
    self.isBackgroundTask = NO;
    
    //Customize Tab bar Controller
    /*
    if ([[self.tabBarController.tabBar.items objectAtIndex:0] respondsToSelector:@selector(setFinishedSelectedImage:withFinishedUnselectedImage:)]) {
        
        [[self.tabBarController.tabBar.items objectAtIndex:0] setFinishedSelectedImage:[UIImage imageNamed:@"my_events_on.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"my_events_off.png"]];
        [[self.tabBarController.tabBar.items objectAtIndex:1] setFinishedSelectedImage:[UIImage imageNamed:@"invitations_on.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"invitations.png"]];
        [[self.tabBarController.tabBar.items objectAtIndex:2] setFinishedSelectedImage:[UIImage imageNamed:@"memories_on.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"memories_off.png"]];
        [[self.tabBarController.tabBar.items objectAtIndex:3] setFinishedSelectedImage:[UIImage imageNamed:@"fire_on"] withFinishedUnselectedImage:[UIImage imageNamed:@"fire_off"]];
        
    }*/
    
    if (![PFUser currentUser]) {
        //In order to looad events from the server when come back
        self.comeFromLogin = YES;
        [self performSegueWithIdentifier:@"Login" sender:nil];
    }
    else{
        //Events from local db
        self.invitations = [MOUtility getAllFuturInvitations];
        [self.tableView reloadData];
        [self isEmptyTableView];
        
        [self localClosestInvitation];
        self.comeFromLogin = NO;
        [self loadFutureEventsFromServer];
        [self setBadgeForInvitation:self.tabBarController atIndex:1];
        
        //Sync with FB
        [self retrieveEventsSince:[NSDate date] to:nil isJoin:YES];
        [self retrieveEventsSince:[NSDate date] to:nil isJoin:NO];
    }

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.invitations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    EventsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[EventsCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:CellIdentifier];
    }
    
    //Get the event object.
    PFObject *event = [self.invitations objectAtIndex:indexPath.row][@"event"];
    
    //Date
    NSDate *start_date = event[@"start_time"];
    //Formatter for the hour
    NSDateFormatter *formatterHourMinute = [NSDateFormatter new];
    [formatterHourMinute setDateFormat:@"HH:mm"];
    [formatterHourMinute setLocale:[NSLocale currentLocale]];
    NSDateFormatter *formatterMonth = [NSDateFormatter new];
    [formatterMonth setDateFormat:@"MMM"];
    [formatterHourMinute setLocale:[NSLocale currentLocale]];
    NSDateFormatter *formatterDay = [NSDateFormatter new];
    [formatterDay setDateFormat:@"d"];
    [formatterDay setLocale:[NSLocale currentLocale]];
    
    
    //Fill the cell
    cell.nameEventLabel.text = event[@"name"];
    
    cell.whereWhenLabel.text = (event[@"location"] == nil) ? [NSString stringWithFormat:@"%@", [formatterHourMinute stringFromDate:start_date]] : [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_WhenWhere", nil), [formatterHourMinute stringFromDate:start_date], event[@"location"]];
    cell.ownerInvitation.text = [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_SendInvit", nil), event[@"owner"][@"name"]];
    cell.monthLabel.text = [[NSString stringWithFormat:@"%@", [formatterMonth stringFromDate:start_date]] uppercaseString];
    cell.dayLabel.text = [NSString stringWithFormat:@"%@", [formatterDay stringFromDate:start_date]];
    
    [cell.coverImageView setImageWithURL:[NSURL URLWithString:event[@"cover"]]
                   placeholderImage:[UIImage imageNamed:@"cover_default"]];
    
    return cell;
}

#pragma mark- Retrieve Facebook Events

-(void)retrieveEventsSince:(NSDate *)sinceDate to:(NSDate *)toDate isJoin:(BOOL)joined{
    
    int startTimeInterval = (int)[sinceDate timeIntervalSince1970];
    NSString *startDate = [NSString stringWithFormat:@"%i", startTimeInterval];
    
    //Request
    NSString *requestString;
    if(joined){
        requestString = [NSString stringWithFormat:@"me/events?fields=%@&since=%@",FacebookEventsFields, startDate];
    }
    else{
        requestString = [NSString stringWithFormat:@"me/events?fields=%@&type=not_replied",FacebookEventsFields];
    }
   
    NSLog(@"Request : %@", requestString);
    
    FBRequest *request = [FBRequest requestForGraphPath:requestString];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            
            if (joined) {
                self.facebookEventsNb = [result[@"data"] count];
            }
            else{
                self.facebookEventNotReplied = [result[@"data"] count];
                if (self.facebookEventNotReplied==0) {
                    ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
                    if (invitationsController) {
                        [invitationsController loadInvitationFromServer];
                        [invitationsController loadDeclinedFromSever];
                    }
                }
            }
            
            
            for(id event in result[@"data"]){
                [FbEventsUtilities saveEvent:event];
                //Save a new event
            }
            
            
        }
        else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            [self performSegueWithIdentifier:@"Login" sender:nil];
        }
        else{
            NSLog(@"%@", error);
            ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
            if (invitationsController) {
                [invitationsController loadInvitationFromServer];
                [invitationsController loadDeclinedFromSever];
            }
            [self stopRefresh];
        }
    }];

}

# pragma mark - Events manipulations


-(void)oneFacebookEventUpdated:(NSNotification *)note{
    //Which rsvp (not_replied or other-
    NSDictionary *userInfo = note.userInfo;
    NSString *rsvp = [userInfo objectForKey:@"rsvp"];
    
    //Not Replied events
    if ([rsvp isEqualToString:@"not_replied"]) {
        self.facebookEventNotRepliedDone ++;
        
        if (self.facebookEventNotRepliedDone == self.facebookEventNotReplied) {
            self.facebookEventNotReplied = 0;
            self.facebookEventNotRepliedDone = 0;
            [self setBadgeForInvitation:self.tabBarController atIndex:1];
            //And reload the table view of the invitation
            //We reload the list in the future events
            ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
            if (invitationsController) {
                [invitationsController loadInvitationFromServer];
                [invitationsController loadDeclinedFromSever];
            }
            
        }
    }
    else{
        self.facebookEventsNbDone ++;
        
        if (self.facebookEventsNb == self.facebookEventsNbDone) {
            self.facebookEventsNb = 0;
            self.facebookEventsNbDone = 0;
            [self loadFutureEventsFromServer];
        }
    }
    
}

- (IBAction)fbReload:(id)sender {
    //[self performSegueWithIdentifier:@"CountEvents" sender:nil];
    /*if (self.isNewUser) {
        [self performSegueWithIdentifier:@"CountEvents" sender:nil];
    }*/
    
    if (!self.isBackgroundTask) {
        [TestFlight passCheckpoint:@"RELOAD_INVITATIONS_FROM_FB"];
    }
    
    
    if (!self.refreshControl.isRefreshing) {
        [self.activityIndicator setHidden:NO];
        [self.refreshImage setHidden:YES];
        
    }
    
    [self.fbReloadButton setEnabled:NO];
    
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:YES];
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:NO];
    
}

-(void)mustReloadEvents:(NSNotification *)note{
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:YES];
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:NO];
}

-(void)loadFutureEventsFromServer{
    NSLog(@"Load Future Events");
    
    NSMutableArray *invits = [[NSMutableArray alloc] init];
    
    /*PFQuery *queryEventEndTime = [PFQuery queryWithClassName:@"Event"];
    [queryEventEndTime whereKeyExists:@"end_time"];
    [queryEventEndTime whereKey:@"end_time" greaterThanOrEqualTo:[NSDate date]];
    
    PFQuery *queryEventStartTime = [PFQuery queryWithClassName:@"Event"];
    [queryEventStartTime whereKeyDoesNotExist:@"end_time"];
    [queryEventStartTime whereKey:@"start_time" greaterThanOrEqualTo:[[NSDate date] dateByAddingTimeInterval:-12*3600]];*/
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    //[query whereKey:@"event" matchesQuery:queryEventStartTime];
    [query whereKey:@"start_time" greaterThanOrEqualTo:[[NSDate date] dateByAddingTimeInterval:-12*3600]];
    [query whereKey:@"rsvp_status" notContainedIn:@[FacebookEventNotReplied,FacebookEventDeclined]];
    [query includeKey:@"event"];
    [query orderByAscending:@"start_time"];
    
    //Cache then network
    #warning Modify Cache Policy
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [invits addObjectsFromArray:objects];
            
            for(PFObject *invitation in objects){
                [MOUtility saveInvitationWithEvent:invitation];
            }
            
            [[Mixpanel sharedInstance].people set:@{@"Nb Futur Events": [NSNumber numberWithInt:invits.count]}];
            
            self.invitations = invits;
            [self isEmptyTableView];
            [self.tableEvents reloadData];
            
            //Select the closest invit
            [self selectClosestInvitation];
            
            [self stopRefresh];
            
            //Query event with end time
            /*PFQuery *queryEnd = [PFQuery queryWithClassName:@"Invitation"];
            [queryEnd whereKey:@"user" equalTo:[PFUser currentUser]];
            [queryEnd whereKey:@"event" matchesQuery:queryEventEndTime];
            [queryEnd whereKey:@"rsvp_status" notContainedIn:@[FacebookEventNotReplied,FacebookEventDeclined]];
            [queryEnd includeKey:@"event"];
            
            [queryEnd findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    [invits addObjectsFromArray:objects];
                    
                    [[Mixpanel sharedInstance].people set:@{@"Nb Futur Events": [NSNumber numberWithInt:invits.count]}];
                    
                    self.invitations = [MOUtility sortByStartDate:invits isAsc:YES];
                    [self isEmptyTableView];
                    [self.tableEvents reloadData];
                    
                    //Select the closest invit
                    [self selectClosestInvitation];
                    
                    [self stopRefresh];
                    
                    
                    for(PFObject *invitation in objects){
                        [MOUtility saveInvitationWithEvent:invitation];
                    }
                }
                else{
                    NSLog(@"Problème de chargement");
                    [self stopRefresh];
                }
            }];*/
            
        } else {
            // Log details of the failure
            NSLog(@"Problème de chargement");
            [self.refreshControl endRefreshing];
        }
    }];
    
}



# pragma mark - Prepare Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"DetailEvent"]) {
        [[Mixpanel sharedInstance] track:@"Detail Event" properties:@{@"From": @"Events View"}];
        
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        //Selected row
        NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
        
    
        PhotosCollectionViewController *photosCollectionViewController = segue.destinationViewController;
        photosCollectionViewController.invitation = [self.invitations objectAtIndex:selectedRowIndex.row];
        photosCollectionViewController.hidesBottomBarWhenPushed = YES;
    }
    
    else if ([segue.identifier isEqualToString:@"Login"]){
        self.invitations = nil;
        [self isEmptyTableView];
        [self.tableView reloadData];
        [self.tabBarController setSelectedIndex:0];
        [MOUtility logoutApp];
        
        
    }
}


#pragma mark - Log Out and In

-(void)logOut:(NSNotification *)note{
    self.invitations = nil;
    [self isEmptyTableView];
    [self.tableView reloadData];
    [self.tabBarController setSelectedIndex:0];
}

-(void)logIn:(NSNotification *)note{
    BOOL b = [note.userInfo[@"is_new"] boolValue];
    NSLog(@"%hhd", b);
    if ([note.userInfo[@"is_new"] boolValue]) {
        self.isNewUser = YES;
    }
    else{
        self.isNewUser = NO;
    }
    
    [self localClosestInvitation];
    [self loadFutureEventsFromServer];
    [self setBadgeForInvitation:self.tabBarController atIndex:1];
    
    //Sync with FB
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:YES];
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:NO];
}

-(void)comingFromLogin{
    [self loadFutureEventsFromServer];
    [self setBadgeForInvitation:self.tabBarController atIndex:1];
    
    //Sync with FB
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:YES];
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:NO];
}


-(void)selectClosestInvitation{
    //__block BOOL haveOlderWithEndTime = NO;
    
    if (self.invitations.count>0) {
        PFObject *actualClosest = [self.invitations objectAtIndex:0];
        
        self.closestInvitation = actualClosest;
        [[NSNotificationCenter defaultCenter] postNotificationName:UpdateClosestEvent object:self userInfo:nil]; 
        
        /*NSDate* dateFutur = actualClosest[@"event"][@"start_time"];
        NSTimeInterval distanceBetweenDates = [dateFutur timeIntervalSinceDate:[NSDate date]];
        NSInteger secondsBetweenDate = distanceBetweenDates;
        NSLog(@"Seconds between = %i", secondsBetweenDate);
        
        //Potential max end date for past event
        __block NSDate *endPotentialDate = [[NSDate date] dateByAddingTimeInterval:-secondsBetweenDate];
        
        NSLog(@"Potential max end date %@", endPotentialDate);
        
        //Try go get en event with an end date closer
        PFQuery *queryEvent = [PFQuery queryWithClassName:@"Event"];
        [queryEvent whereKeyExists:@"end_time"];
        [queryEvent whereKey:@"end_time" greaterThanOrEqualTo:endPotentialDate];
        [queryEvent whereKey:@"start_time" lessThan:[NSDate date]];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
        [query whereKey:@"user" equalTo:[PFUser currentUser]];
        [query whereKey:@"event" matchesQuery:queryEvent];
        [query whereKey:@"rsvp_status" notContainedIn:@[FacebookEventNotReplied,FacebookEventDeclined]];
        [query includeKey:@"event"];
        [query orderByDescending:@"start_time"];
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (objects && objects.count>0) {
                haveOlderWithEndTime = YES;
                self.closestInvitation = [[MOUtility sortByStartDate:[objects mutableCopy] isAsc:NO] objectAtIndex:0];
            }
            
            
            //Try go get en event with no end date closer
            if (haveOlderWithEndTime) {
                endPotentialDate = self.closestInvitation[@"event"][@"end_time"];
            }
            
            PFQuery *queryEventStartMax = [PFQuery queryWithClassName:@"Event"];
            [queryEventStartMax whereKeyDoesNotExist:@"end_time"];
            [queryEventStartMax whereKey:@"start_time" lessThan:[NSDate date]];
            [queryEventStartMax orderByDescending:@"start_time"];
            
            
            PFQuery *queryStart = [PFQuery queryWithClassName:@"Invitation"];
            [queryStart whereKey:@"user" equalTo:[PFUser currentUser]];
            [queryStart whereKey:@"event" matchesQuery:queryEventStartMax];
            [queryStart whereKey:@"rsvp_status" notContainedIn:@[FacebookEventNotReplied,FacebookEventDeclined]];
            [queryStart includeKey:@"event"];
            
            [queryStart getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (!error) {
                    PFObject *event = object[@"event"];
                    NSDate *dateEvent = event[@"start_time"];
                    if ([dateEvent compare:[endPotentialDate dateByAddingTimeInterval:-12*3600]]==NSOrderedDescending) {
                        self.closestInvitation = object;
                        [[NSNotificationCenter defaultCenter] postNotificationName:UpdateClosestEvent object:self userInfo:nil];
                    }
                }
                else{
                    [[NSNotificationCenter defaultCenter] postNotificationName:UpdateClosestEvent object:self userInfo:nil]; 
                }
                
            }];
        }];*/
    }
    
    
    
}

-(void)localClosestInvitation{
    BOOL isOccuring = NO;
    NSArray *futurInvites = [MOUtility getAllFuturInvitations];
    NSArray *pastInvites = [MOUtility getPastMemories];
    
    if ((futurInvites.count>0)&&(pastInvites.count > 0) ) {
        PFObject *futurInvit =  [[MOUtility getAllFuturInvitations] objectAtIndex:0];
        PFObject *pastInvit =  [[MOUtility getPastMemories] objectAtIndex:0];
        
        PFObject *futurEvent = futurInvit[@"event"];
        PFObject *pastEvent = pastInvit[@"event"];
        
        NSDate *futurDate = futurEvent [@"start_time"];
        NSInteger intervalFutur = [futurDate timeIntervalSinceDate:[NSDate date]];
        NSDate *pastDate = [[NSDate alloc] init];
        
        if (pastEvent[@"end_time"]) {
            //Is it occuring right now
            if ([(NSDate *)pastEvent[@"end_time"] compare:[NSDate date]] == NSOrderedDescending ) {
                isOccuring = YES;
                self.closestInvitation = pastInvit;
            }
            else{
                pastDate = pastEvent[@"end_time"];
            }
        }
        else{
            pastDate = [(NSDate *)pastEvent[@"start_time"] dateByAddingTimeInterval:12*3600];
        }
        
        if (!isOccuring) {
            NSInteger intervalPast = fabs([pastDate timeIntervalSinceDate:[NSDate date]]);
            
            if (intervalPast<intervalFutur) {
                self.closestInvitation = pastInvit;
            }
            else{
                self.closestInvitation = futurInvit;
            }
        }
    }
    else if(pastInvites.count >0){
        self.closestInvitation = [pastInvites objectAtIndex:0];
    }
    else if (futurInvites.count >0){
        self.closestInvitation = [futurInvites objectAtIndex:0];
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UpdateClosestEvent object:self userInfo:nil];
    
}


-(void)isEmptyTableView{
    UIView *viewBack = [[UIView alloc] initWithFrame:self.view.frame];
    
    //Image
    UIImage *image = [UIImage imageNamed:@"marmotte_event_empty"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [imageView setImage:image];
     imageView.contentMode = UIViewContentModeCenter;
    [viewBack addSubview:imageView];
    
    //Label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 370, 280, 40)];
    [label setTextColor:[UIColor darkGrayColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.text = NSLocalizedString(@"ListEvents_NoEvent", nil);
    [viewBack addSubview:label];
    
    
    if (!self.invitations) {
        self.tableView.backgroundView = viewBack;
    }
    else if(self.invitations.count==0){
        self.tableView.backgroundView = viewBack;
    }
    else{
       self.tableView.backgroundView = nil;
    }
}


-(void)setBadgeForInvitation:(UITabBarController *)controller atIndex:(NSUInteger)index{
    
    //From local database
    int countInvit = [MOUtility countFutureInvitations];
    if(countInvit>0){
        [[[[controller tabBar] items] objectAtIndex:index] setBadgeValue:[NSString stringWithFormat:@"%d", countInvit]];
    }
    else{
        [[[[controller tabBar] items] objectAtIndex:index] setBadgeValue:nil];
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"rsvp_status" equalTo:@"not_replied"];
    [query whereKey:@"start_time" greaterThan:[NSDate date]];
    
    
    [query countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (!error) {
            // The count request succeeded. Log the count
            if(count>0){
                [[[[controller tabBar] items] objectAtIndex:index] setBadgeValue:[NSString stringWithFormat:@"%d", count]];
            }
            else{
                [[[[controller tabBar] items] objectAtIndex:index] setBadgeValue:nil];
            }
            
            //Mixpanel
            //[[Mixpanel sharedInstance] track:@"Invitations Set Badge" properties:@{@"Nb Invitations": [NSNumber numberWithInt:count]}];
            
            //If it was a background task, said that it is finished
            if (self.isBackgroundTask) {
                self.isBackgroundTask = NO;
                [[Mixpanel sharedInstance] track:@"Background Fetch"];
                self.completionHandler(UIBackgroundFetchResultNewData);
            }
            
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
            currentInstallation.badge = count;
            [currentInstallation saveEventually];
            
            
        } else {
            // The request failed
            //If it was a background task, said that it is finished
            if (self.isBackgroundTask) {
                self.isBackgroundTask = NO;
                [[Mixpanel sharedInstance] track:@"Background Fetch"];
                self.completionHandler(UIBackgroundFetchResultFailed);
                
            }
        }
    }];
}

-(void)stopRefresh{
    [self.activityIndicator setHidden:YES];
    [self.refreshImage setHidden:NO];
    [self.fbReloadButton setEnabled:YES];
    [self.refreshControl endRefreshing];
    [[NSNotificationCenter defaultCenter] postNotificationName:HaveFinishedRefreshEvents object:self];
}


@end

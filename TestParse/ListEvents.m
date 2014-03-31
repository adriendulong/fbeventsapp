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
#import "MBProgressHUD.h"
#import "iRate.h"


@interface ListEvents ()

@end

@implementation ListEvents{
    UIImageView *navBarHairlineImageView;
}

@synthesize invitations;

- (void)initRate
{
    /* ------------------ iRate ------------------- */
    /*          ---> Noter l'application <--        */
    /* -------------------------------------------- */
    
    //set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
    [iRate sharedInstance].applicationBundleID = @"com.moment.Woovent";
    [iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    [iRate sharedInstance].appStoreID = 781588768;
    [iRate sharedInstance].daysUntilPrompt = 2;
    [iRate sharedInstance].usesUntilPrompt = 10;
    [iRate sharedInstance].applicationName = @"Woovent";
    //[iRate sharedInstance].useAllAvailableLanguages = NO;
    
    //enable preview mode
    [iRate sharedInstance].previewMode = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FacebookEventUploaded" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LogOutUser object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LogInUser object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModifEventsInvitationsAnswers object:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarHairlineImageView.hidden = YES;
    
    
    
    if (!self.isBackgroundTask) {
        [[Mixpanel sharedInstance] track:@"Event View Appear"];
        
        id tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:kGAIScreenName
               value:@"Events View"];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    navBarHairlineImageView.hidden = NO;
}

-(void)viewDidAppear:(BOOL)animated{
    if (self.isNewUser) {
        self.isNewUser = NO;
        [self performSegueWithIdentifier:@"CountEvents" sender:nil];
    }
}


- (void)viewDidLoad
{
    self.title = NSLocalizedString(@"UITabBar_Title_FirstPosition", nil);
    //[self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:(253/255.0) green:(160/255.0) blue:(20/255.0) alpha:1]];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [UIColor whiteColor],NSForegroundColorAttributeName,
                                    [UIColor whiteColor],NSBackgroundColorAttributeName,
                                    [MOUtility getFontWithSize:20.0] , NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    navBarHairlineImageView = [self findHairlineImageViewUnder:self.navigationController.navigationBar];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    
    //Top icon
    self.topImageView.layer.cornerRadius = 17.0f;
    self.topImageView.layer.masksToBounds = YES;
    
    UIColor *greyColor = [UIColor colorWithRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1];
    [self.tableView setBackgroundColor:greyColor];
    
    
    //Refresh view
    self.animating = NO;
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    refreshControl.tintColor = [UIColor grayColor];
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
        
        self.comeFromLogin = NO;
        [self loadFutureEventsFromServer];
        ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:invitationsController.view animated:YES];
        hud.labelText = NSLocalizedString(@"ListEvents_Searching", nil);
        if (invitationsController) {
            [invitationsController loadInvitationFromServer];
            [invitationsController loadDeclinedFromSever];
        }
        [self setBadgeForInvitation:self.tabBarController atIndex:1];
        
        //Sync with FB
        [self retrieveEventsSinceAsync:[NSDate date] to:nil isJoin:YES];
        [self retrieveEventsSinceAsync:[NSDate date] to:nil isJoin:NO];
    
        [self initRate];
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
    [formatterHourMinute setDateFormat:@"hh:mm a"];
    //[formatterHourMinute setLocale:[NSLocale currentLocale]];
    NSDateFormatter *formatterMonth = [NSDateFormatter new];
    [formatterMonth setDateFormat:@"MMM"];
    //[formatterHourMinute setLocale:[NSLocale currentLocale]];
    NSDateFormatter *formatterDay = [NSDateFormatter new];
    [formatterDay setDateFormat:@"d"];
    [formatterDay setLocale:[NSLocale currentLocale]];
    
    
    //Fill the cell
    cell.nameEventLabel.text = event[@"name"];
    
    NSString *hourToPrint;
    if (![event[@"is_date_only"] boolValue]) {
        hourToPrint = [formatterHourMinute stringFromDate:start_date];
    }
    else{
        if (event[@"end_time"]) {
            NSInteger nbDays = [MOUtility daysBetweenDate:(NSDate *)event[@"start_time"] andDate:(NSDate *)event[@"end_time"]];
            hourToPrint = [NSString stringWithFormat:NSLocalizedString(@"ListEvents_DateEventLabelDuring", nil), nbDays];
        }
        else{
            hourToPrint = NSLocalizedString(@"ListEvents_DateEventLabelAllDay", nil);
        }
    }
    
    cell.whereWhenLabel.text = (event[@"location"] == nil) ? [NSString stringWithFormat:@"%@", hourToPrint] : [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_WhenWhere", nil), hourToPrint, event[@"location"]];
    cell.ownerInvitation.text = [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_SendInvit", nil), event[@"owner"][@"name"]];
    cell.monthLabel.text = [[NSString stringWithFormat:@"%@", [formatterMonth stringFromDate:start_date]] uppercaseString];
    cell.dayLabel.text = [NSString stringWithFormat:@"%@", [formatterDay stringFromDate:start_date]];
    
    [cell.coverImageView setImageWithURL:[NSURL URLWithString:event[@"cover"]]
                        placeholderImage:[UIImage imageNamed:@"default_cover"]];
    
    return cell;
}

#pragma mark- Retrieve Facebook Events
/*
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
                    [self setBadgeForInvitation:self.tabBarController atIndex:1];
                    ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
                    if (invitationsController) {
                        [invitationsController loadInvitationFromServer];
                        [invitationsController loadDeclinedFromSever];
                    }
                }
                
                if (self.facebookEventsNb == 0) {
                    [self stopRefresh];
                }
            }
            
            
            for(id event in result[@"data"]){
                [[FbEventsUtilities saveEventAsync:event] continueWithBlock:^id(BFTask *task) {
                    if (task.error) {
                        NSLog(@"Error");
                    }
                    else{
                        NSLog(@"OK");
                        NSLog(@"Invitation : %@", (PFObject *)task.result);
                    }
                    
                    return nil;
                }];
                
                //[FbEventsUtilities saveEvent:event];
                //Save a new event
            }
            
            
        }
        else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            [[Mixpanel sharedInstance] track:@"OAuth Disconnect"];
            if (!self.isBackgroundTask) {
                [self performSegueWithIdentifier:@"Login" sender:nil];
            }
            else{
                self.completionHandler(UIBackgroundFetchResultFailed);
            }
        }
        else{
            NSLog(@"%@", error);
            
            if (!self.isBackgroundTask) {
                ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
                if (invitationsController) {
                    [invitationsController loadInvitationFromServer];
                    [invitationsController loadDeclinedFromSever];
                }
                [self stopRefresh];
            }
            else{
                self.completionHandler(UIBackgroundFetchResultFailed);
            }
            
        }
    }];

}
*/

-(void)retrieveEventsSinceAsync:(NSDate *)sinceDate to:(NSDate *)toDate isJoin:(BOOL)joined{
    
    NSDate *start_date = [MOUtility setDateTime:sinceDate withTime:0];
    int startTimeInterval = (int)[start_date timeIntervalSince1970];
    NSString *startDate = [NSString stringWithFormat:@"%i", startTimeInterval];
    
    
    
    //Request
    NSString *requestString;
    if(joined){
        requestString = [NSString stringWithFormat:@"me/events?fields=%@&since=%@&limit=100",FacebookEventsFields, startDate];
    }
    else{
        requestString = [NSString stringWithFormat:@"me/events?fields=%@&type=not_replied&limit=100&since=%@",FacebookEventsFields, startDate];
    }
    
    NSLog(@"Request : %@", requestString);
    
    FBRequest *request = [FBRequest requestForGraphPath:requestString];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            
            //Futur events
            if (joined) {
                if ([result[@"data"] count]>0) {
                    //Update or create all events
                    NSMutableArray *tasks = [NSMutableArray array];
                    
                    for(id event in result[@"data"]){
                        [tasks addObject:[FbEventsUtilities saveEventAsync:event]];
                    }
                    
                    [[BFTask taskForCompletionOfAllTasks:tasks] continueWithBlock:^id(BFTask *task) {
                        if (task.error) {
                            NSLog(@"Une erreur a eu lieu lors des %i events futurs", [tasks count]);
                            [self stopRefresh];
                            [self loadFutureEventsFromServer];
                        }
                        else{
                            NSLog(@"Tout c'est bien passé avec les %i events futurs", [tasks count]);
                            [self stopRefresh];
                            [self loadFutureEventsFromServer];
                        }
                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                        
                        return nil;
                    }];
                }
                else{
                    [self stopRefresh];
                }
            }
            
            //Futur invitations
            else{
                
                //No invitations
                if ([result[@"data"] count]==0) {
                    [self setBadgeForInvitation:self.tabBarController atIndex:1];
                    ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
                    if (invitationsController) {
                        [invitationsController loadInvitationFromServer];
                        [invitationsController loadDeclinedFromSever];
                    }
                }
                
                //Create or update invitations
                else{
                    NSMutableArray *tasks = [NSMutableArray array];
                    
                    for(id event in result[@"data"]){
                        [tasks addObject:[FbEventsUtilities saveEventAsync:event]];
                    }
                    
                    [[BFTask taskForCompletionOfAllTasks:tasks] continueWithBlock:^id(BFTask *task) {
                        if (task.error) {
                            NSLog(@"Une erreur a eu lieu lors des %i events invitations", [tasks count]);
                        }
                        else{
                            NSLog(@"Tout c'est bien passé avec les %i events invitations", [tasks count]);
                        }
                        
                        [self setBadgeForInvitation:self.tabBarController atIndex:1];
                        ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
                        if (invitationsController) {
                            [invitationsController loadInvitationFromServer];
                            [invitationsController loadDeclinedFromSever];
                        }
                        
                        return nil;
                    }];
                    
                }
                
            }
        }
        else{
            if (self.isBackgroundTask) {
                self.completionHandler(UIBackgroundFetchResultFailed);
            }
            else{
                [self stopRefresh];
                [self handleAuthError:error];
            }
        }
    }];
    
}

# pragma mark - Events manipulations

/*
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
    
}*/

- (IBAction)fbReload:(id)sender {
    //[self performSegueWithIdentifier:@"CountEvents" sender:nil];
    /*if (self.isNewUser) {
        [self performSegueWithIdentifier:@"CountEvents" sender:nil];
    }*/

    if (!self.isBackgroundTask) {
        if (!self.refreshControl.isRefreshing) {
            [self.activityIndicator setHidden:NO];
            [self.refreshImage setHidden:YES];
            
        }
        
        [self.fbReloadButton setEnabled:NO];
        
        [self retrieveEventsSinceAsync:[NSDate date] to:nil isJoin:YES];
        [self retrieveEventsSinceAsync:[NSDate date] to:nil isJoin:NO];
    }
    else{
        [self retrieveEventsSinceAsync:[NSDate date] to:nil isJoin:NO];
    }
    
    
    
    
}

-(void)mustReloadEvents:(NSNotification *)note{
    [self retrieveEventsSinceAsync:[NSDate date] to:nil isJoin:YES];
    [self retrieveEventsSinceAsync:[NSDate date] to:nil isJoin:NO];
}

-(void)loadFutureEventsFromServer{
    NSLog(@"Load Future Events");
    
    NSMutableArray *invits = [[NSMutableArray alloc] init];
    
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    //[query whereKey:@"event" matchesQuery:queryEventStartTime];
    [query whereKey:@"start_time" greaterThanOrEqualTo:[[NSDate date] dateByAddingTimeInterval:-25*3600]];
    [query whereKey:@"rsvp_status" notContainedIn:@[FacebookEventNotReplied,FacebookEventDeclined]];
    [query includeKey:@"event"];
    [query orderByAscending:@"start_time"];
    
    //Cache then network
    #warning Modify Cache Policy
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [invits addObjectsFromArray:[[MOUtility keepGoodEvents:objects] copy]];
            //[invits addObjectsFromArray:objects];
            
            //Erase all actual notifs
            [MOUtility eraseNotifsOfType:0];
            [MOUtility eraseNotifsOfType:1];
            

            for(PFObject *invitation in objects){
                [MOUtility programNotifForEvent:invitation];
                [MOUtility saveInvitationWithEvent:invitation];
            }

            
            [[Mixpanel sharedInstance].people set:@{@"Nb Futur Events": [NSNumber numberWithInt:invits.count]}];
            
            self.invitations = invits;
            [self isEmptyTableView];
            [self.tableEvents reloadData];
            
            [self stopRefresh];
            
            
            
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
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"ListEvents_Searching", nil);
    
    
    if ([note.userInfo[@"is_new"] boolValue]) {
        self.isNewUser = YES;
    }
    else{
        self.isNewUser = NO;
    }

    if (!self.isNewUser) {
        [self loadFutureEventsFromServer];
        ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:invitationsController.view animated:YES];
        hud.labelText = NSLocalizedString(@"ListEvents_Searching", nil);
        if (invitationsController) {
            [invitationsController loadInvitationFromServer];
            [invitationsController loadDeclinedFromSever];
        }
    }
    [self setBadgeForInvitation:self.tabBarController atIndex:1];
    
    
    //Sync with FB
    [self retrieveEventsSinceAsync:[NSDate date] to:nil isJoin:YES];
    [self retrieveEventsSinceAsync:[NSDate date] to:nil isJoin:NO];
}

-(void)comingFromLogin{
    [self loadFutureEventsFromServer];
    [self setBadgeForInvitation:self.tabBarController atIndex:1];
    
    //Sync with FB
    [self retrieveEventsSinceAsync:[NSDate date] to:nil isJoin:YES];
    [self retrieveEventsSinceAsync:[NSDate date] to:nil isJoin:NO];
}



-(void)isEmptyTableView{
    UIView *viewBack = [[UIView alloc] initWithFrame:self.view.frame];
    
    //Image
    UIImage *image = [UIImage imageNamed:@"events_empty"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [imageView setImage:image];
     imageView.contentMode = UIViewContentModeCenter;
    [viewBack addSubview:imageView];
    
    //Label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 370, 280, 40)];
    [label setTextColor:[UIColor darkGrayColor]];
    [label setFont:[MOUtility getFontWithSize:18.0]];
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
                NSLog(@"OK");
                [[Mixpanel sharedInstance] track:@"Background Fetch" properties:@{@"success": @YES}];
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
                [[Mixpanel sharedInstance] track:@"Background Fetch" properties:@{@"success": @NO}];
                self.completionHandler(UIBackgroundFetchResultFailed);
                
            }
        }
    }];
}

-(void)stopRefresh{
    [self.activityIndicator setHidden:YES];
    [self.refreshImage setHidden:NO];
    [self.fbReloadButton setEnabled:YES];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self.refreshControl endRefreshing];
    [[NSNotificationCenter defaultCenter] postNotificationName:HaveFinishedRefreshEvents object:self];
}


- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}



- (void)handleAuthError:(NSError *)error
{
    NSString *alertText;
    NSString *alertTitle;
    
    if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
        // Error requires people using you app to make an action outside your app to recover
        alertTitle = @"Something went wrong";
        alertText = [FBErrorUtility userMessageForError:error];
        [self showMessage:alertText withTitle:alertTitle];
        
        ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
        if (invitationsController) {
            [invitationsController loadInvitationFromServer];
            [invitationsController loadDeclinedFromSever];
        }
        [self stopRefresh];
        
    } else {
        // You need to find more information to handle the error within your app
        if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
            //The user refused to log in into your app, either ignore or...
            [[Mixpanel sharedInstance] track:@"OAuth Disconnect"];
            alertTitle = @"Login cancelled";
            alertText = @"You need to login to access this part of the app";
            [self showMessage:alertText withTitle:alertTitle];
            [self performSegueWithIdentifier:@"Login" sender:nil];
            
        } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
            // We need to handle session closures that happen outside of the app
            [[Mixpanel sharedInstance] track:@"OAuth Disconnect"];
            alertTitle = @"Session Error";
            alertText = @"Your current session is no longer valid. Please log in again.";
            [self showMessage:alertText withTitle:alertTitle];
            [self performSegueWithIdentifier:@"Login" sender:nil];
            
        } else {
            // All other errors that can happen need retries
            // Show the user a generic error message
            alertTitle = @"Something went wrong";
            alertText = @"Please retry";
            [self showMessage:alertText withTitle:alertTitle];
            
            ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
            if (invitationsController) {
                [invitationsController loadInvitationFromServer];
                [invitationsController loadDeclinedFromSever];
            }
            [self stopRefresh];
        }
    }
}


- (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

@end

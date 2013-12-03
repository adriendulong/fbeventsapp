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

@interface ListEvents ()

@end

@implementation ListEvents

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FacebookEventUploaded" object:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //self.title = @"";
    
    NSLog(@"WIll Appear");
    //[self loadFutureEventsFromServer];
    //[EventUtilities setBadgeForInvitation:self.tabBarController atIndex:1];
    
    /*
    if(self.comeFromLogin){
        self.comeFromLogin = NO;
        NSLog(@"COme from login");
        
        #warning If not network load from the last Date of from the core data
        [self loadFutureEventsFromServer];
        [EventUtilities setBadgeForInvitation:self.tabBarController atIndex:1];
        
        //Sync with FB
        [self retrieveEventsSince:[NSDate date] to:nil isJoin:YES];
        [self retrieveEventsSince:[NSDate date] to:nil isJoin:NO];
        
        
    }*/
    
    //If the events need to be refreshed (something occured in the invitations)
    //TestParseAppDelegate *delegate = [(TestParseAppDelegate *)[UIApplication sharedApplication] delegate];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Init badge of invitations
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(oneFacebookEventUpdated:) name:@"FacebookEventUploaded" object:nil];
    
    //init
    self.facebookEventsNbDone = 0;
    self.facebookEventNotRepliedDone = 0;
    
    //Customize Tab bar Controller
    if ([[self.tabBarController.tabBar.items objectAtIndex:0] respondsToSelector:@selector(setFinishedSelectedImage:withFinishedUnselectedImage:)]) {
        
        [[self.tabBarController.tabBar.items objectAtIndex:0] setFinishedSelectedImage:[UIImage imageNamed:@"my_events_on.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"my_events_off.png"]];
        [[self.tabBarController.tabBar.items objectAtIndex:1] setFinishedSelectedImage:[UIImage imageNamed:@"invitations_on.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"invitations.png"]];
        [[self.tabBarController.tabBar.items objectAtIndex:2] setFinishedSelectedImage:[UIImage imageNamed:@"memories_on.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"memories_off.png"]];
        
    }
    
    NSLog(@"Did load");
    if (![PFUser currentUser]) {
        NSLog(@"No current user");
        
        #warning TODO : update user info
        //In order to looad events from the server when come back
        self.comeFromLogin = YES;
        [self performSegueWithIdentifier:@"Login" sender:nil];
    }
    else{
        self.comeFromLogin = NO;
        [self loadFutureEventsFromServer];
        [EventUtilities setBadgeForInvitation:self.tabBarController atIndex:1];
        
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
    NSDateFormatter *formatterMonth = [NSDateFormatter new];
    [formatterMonth setDateFormat:@"MMM"];
    NSDateFormatter *formatterDay = [NSDateFormatter new];
    [formatterDay setDateFormat:@"d"];
    
    //Fill the cell
    cell.nameEventLabel.text = event[@"name"];
    cell.whereWhenLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_WhenWhere", nil), [formatterHourMinute stringFromDate:start_date], event[@"location"]];
    cell.ownerInvitation.text = [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_SendInvit", nil), event[@"owner"][@"name"]];
    cell.monthLabel.text = [[NSString stringWithFormat:@"%@", [formatterMonth stringFromDate:start_date]] uppercaseString];
    cell.dayLabel.text = [NSString stringWithFormat:@"%@", [formatterDay stringFromDate:start_date]];
    
    [cell.coverImageView setImageWithURL:[NSURL URLWithString:event[@"cover"]]
                   placeholderImage:[UIImage imageNamed:@"covertest.png"]];
    
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
        requestString = [NSString stringWithFormat:@"me/events?fields=%@&since=%@&type=not_replied",FacebookEventsFields, startDate];
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
                self.facebookEventNotReplied = [result[@"data"] count];;
            }
            
            
            for(id event in result[@"data"]){
                [FbEventsUtilities saveEvent:event];
                //Save a new event
            }
            
            
        }
        else{
            NSLog(@"%@", error);
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
            [EventUtilities setBadgeForInvitation:self.tabBarController atIndex:1];
            //And reload the table view of the invitation
            //We reload the list in the future events
            ListInvitationsController *invitationsController =  (ListInvitationsController *)[[[[self.tabBarController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
            if (invitationsController) {
                NSLog(@"NOT NULLLLLLL");
                [invitationsController loadInvitationFromServer];
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
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:YES];
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:NO];
}

-(void)loadFutureEventsFromServer{
    NSLog(@"Load Future Events");
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"start_time" greaterThan:[NSDate date]];
    [query whereKey:@"rsvp_status" notContainedIn:@[FacebookEventNotReplied,FacebookEventDeclined]];
    [query includeKey:@"event"];
    [query orderByAscending:@"start_time"];
    
    //Cache then network
    #warning Modify Cache Policy
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"LOADED FUTURE");
            self.invitations = objects;
            [self.tableEvents reloadData];
        } else {
            // Log details of the failure
            NSLog(@"Problème de chargement");
        }
    }];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

# pragma mark - Prepare Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"DetailEvent"]) {
        
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        //Selected row
        NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
        
    
        PhotosCollectionViewController *photosCollectionViewController = segue.destinationViewController;
        photosCollectionViewController.invitation = [self.invitations objectAtIndex:selectedRowIndex.row];
    }
    else if ([segue.identifier isEqualToString:@"Login"]){
        NSLog(@"LOGOUT LIST");
        self.invitations = nil;
        [self.tableView reloadData];
        LoginViewController *loginViewController = segue.destinationViewController;
        loginViewController.myDelegate = self;
        // Clear all caches
        [PFQuery clearAllCachedResults];
        [PFUser logOut];
    }
}


-(void)comingFromLogin{
    [self loadFutureEventsFromServer];
    [EventUtilities setBadgeForInvitation:self.tabBarController atIndex:1];
    
    //Sync with FB
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:YES];
    [self retrieveEventsSince:[NSDate date] to:nil isJoin:NO];
}

#pragma mark - Logout

- (IBAction)logout:(id)sender {
    NSLog(@"LOGOUT LIST");
    
    
    [PFUser logOut];
    [self performSegueWithIdentifier:@"Login" sender:nil];
}


@end

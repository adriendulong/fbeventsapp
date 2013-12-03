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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadInvitationFromServer];
    [self loadDeclinedFromSever];
    
    //Notifications Center
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invitationChanged:)
                                                 name:@"RsvpChanged"
                                               object:nil];

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
    cell.whenWhereLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_WhenWhere", nil), [formatterHourMinute stringFromDate:start_date], event[@"location"]];
    cell.ownerInvitationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ListInvitationsController_SendInvit", nil), event[@"owner"][@"name"]];
    //cell.monthLabel.text = [NSString stringWithFormat:@"%@", [formatterMonth stringFromDate:start_date]];
    //cell.dayLabel.text = [NSString stringWithFormat:@"%@", [formatterDay stringFromDate:start_date]];
    
    // Add a nice corner radius to the image
    cell.profilImageView.layer.cornerRadius = 24.0f;
    cell.profilImageView.layer.masksToBounds = YES;
    
    //Profile picture
    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=normal&return_ssl_resources=1", event[@"owner"][@"id"]]];
    [cell.profilImageView setImageWithURL:pictureURL
                        placeholderImage:[UIImage imageNamed:@"covertest.png"]];
    
    //Assign the event Id
    cell.invitation = [self.objectsForTable objectAtIndex:indexPath.row];
    
    //Init the segment controll if declined
    if ([invitation[@"rsvp_status"] isEqualToString:@"declined"]) {
        [cell.rsvpSegmentedControl setSelectedSegmentIndex:2];
    }
    else{
        [cell.rsvpSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    }
    
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
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"rsvp_status" equalTo:@"not_replied"];
    [query whereKey:@"start_time" greaterThan:[NSDate date]];
    [query orderByAscending:@"start_time"];
    [query includeKey:@"event"];
    
    #warning Modify Cache Policy
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.invitations = objects;
            if(self.listSegmentControll.selectedSegmentIndex==0){
                self.objectsForTable = self.invitations;
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
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"rsvp_status" equalTo:@"declined"];
    [query whereKey:@"start_time" greaterThan:[NSDate date]];
    [query orderByAscending:@"start_time"];
    [query includeKey:@"event"];
    
    #warning Modify Cache Policy
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.declined = objects;
            if(self.listSegmentControll.selectedSegmentIndex==1){
                self.objectsForTable = self.declined;
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
    NSLog(@"DETECT PROTOCOL");
    [self loadInvitationFromServer];
    [self loadDeclinedFromSever];
    [EventUtilities setBadgeForInvitation:self.tabBarController atIndex:1];
    
    //We reload the list in the future events
    ListEvents *eventsController =  (ListEvents *)[[[[self.tabBarController viewControllers] objectAtIndex:0] viewControllers] objectAtIndex:0];
    [eventsController loadFutureEventsFromServer];
}

- (IBAction)listTypeChange:(id)sender {
     NSLog(@"Changed : %i", self.listSegmentControll.selectedSegmentIndex);
    if (self.listSegmentControll.selectedSegmentIndex == 0) {
        self.objectsForTable = self.invitations;
        [self.tableView reloadData];
    }
    else{
        self.objectsForTable = self.declined;
        [self.tableView reloadData];
    }
}

#pragma mark - Other

- (IBAction)settings:(id)sender {
    NSLog(@"LOGOUT");
    [PFUser logOut];
    [self performSegueWithIdentifier:@"FirstLaunch" sender:nil];
    
}

- (void) dealloc
{
    // If you don't remove yourself as an observer, the Notification Center
    // will continue to try and send notification objects to the deallocated
    // object.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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


#pragma mark - Navigation

 
 -(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
     if ([segue.identifier isEqualToString:@"DetailEvent"]) {
 
         self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
 
         //Selected row
         NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
 
 
         PhotosCollectionViewController *photosCollectionViewController = segue.destinationViewController;
         photosCollectionViewController.invitation = [self.self.objectsForTable objectAtIndex:selectedRowIndex.row];
    }
 
 }

@end

//
//  InvitedListViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 25/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "InvitedListViewController.h"
#import "InvitedCell.h"
#import "MOUtility.h"
#import "EventUtilities.h"
#import "FbEventsUtilities.h"
#import "MBProgressHUD.h"

@interface InvitedListViewController ()

@end

@implementation InvitedListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:InvitedDetailFinished object:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"InvitedListViewController_Title", nil);
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"InvitedListViewController_Loading", nil);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(greatMomentToUpdateInvited:) name:InvitedDetailFinished object:nil];
    
    self.invited = [[NSMutableArray alloc] init];
    self.attending = [[NSMutableArray alloc] init];
    self.maybe = [[NSMutableArray alloc] init];
    self.no = [[NSMutableArray alloc] init];
    self.notjoined = [[NSMutableArray alloc] init];
    
    for(PFObject *invit in self.invited){
        if ([invit[@"rsvp_status"] isEqualToString:FacebookEventAttending]) {
            [self.attending addObject:invit];
        }
        else if ([invit[@"rsvp_status"] isEqualToString:FacebookEventMaybe]) {
            [self.maybe addObject:invit];
        }
        else if ([invit[@"rsvp_status"] isEqualToString:FacebookEventNotReplied]) {
            [self.notjoined addObject:invit];
        }
        else if ([invit[@"rsvp_status"] isEqualToString:FacebookEventDeclined]) {
            [self.no addObject:invit];
        }
    }

    [self getGuestsFromFacebookEvent:nil];
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
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section ==0) {
        return NSLocalizedString(@"InvitedListViewController_Presents", nil);
    }
    else if(section ==1){
        return NSLocalizedString(@"InvitedListViewController_Maybe", nil);
    }
    else if(section ==2){
        return NSLocalizedString(@"InvitedListViewController_NoResponse", nil);
    }
    else{
        return NSLocalizedString(@"InvitedListViewController_Absent", nil);
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return [self.attending count];
    }
    else if(section == 1){
        return [self.maybe count];
    }
    else if(section == 2){
        return [self.notjoined count];
    }
    else{
        return [self.no count];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    InvitedCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[InvitedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSURL *pictureURL = [[NSURL alloc] init];
    NSString *name = [[NSString alloc] init];
    
    PFObject *invited;
    if (indexPath.section==0) {
        invited = [self.attending objectAtIndex:indexPath.row];
    }
    else if (indexPath.section==1) {
        invited = [self.maybe objectAtIndex:indexPath.row];
    }
    else if (indexPath.section==2) {
        invited = [self.notjoined objectAtIndex:indexPath.row];
    }
    else{
        invited = [self.no objectAtIndex:indexPath.row];
    }
    
    
    
    if (invited[@"user"]) {
        pictureURL = [MOUtility UrlOfFacebooProfileImage:invited[@"user"][@"facebookId"] withResolution:FacebookLargeProfileImage];
        name = invited[@"user"][@"name"];
    }
    else{
        pictureURL = [MOUtility UrlOfFacebooProfileImage:invited[@"prospect"][@"facebookId"] withResolution:FacebookLargeProfileImage];
        name = invited[@"prospect"][@"name"];
    }
    
    
    [cell.photoImageView setImageWithURL:pictureURL];
    cell.nameLabel.text = name;
    
    return cell;
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

-(void)getGuestsFromFacebookEvent:(NSString *)next{
    NSString *requestString;
    if (next) {
        requestString = [NSString stringWithFormat:@"%@/invited?fields=id,name,rsvp_status&limit=100&after=%@", self.event[@"eventId"], next];
    }
    else{
        requestString = [NSString stringWithFormat:@"%@/invited?fields=id,name,rsvp_status&limit=100", self.event[@"eventId"]];
    }
    
    FBRequest *request = [FBRequest requestForGraphPath:requestString];

    
    
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            NSLog(@"result : %@", result);
            //Get all the invited
            NSArray *guests = result[@"data"];
            
            self.nbInvitedToAdd = guests.count;
            self.nbInvitedAlreadyAdded = 0;
            
            if(result[@"paging"][@"cursors"][@"after"]){
                self.hasNext = YES;
                self.afterCursor = result[@"paging"][@"cursors"][@"after"];
            }
            else{
                self.hasNext = NO;
            }
            
            for (id guest in guests) {
                [self addOrUpdateInvited:guest];
            }
            
        }
        else{
            NSLog(@"%@", error);
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        }
    }];
}

-(void)addOrUpdateInvited:(NSDictionary *)invited{
    //PFObject *guest;
    //PFObject *invitation;
    
    PFObject *prospectObject = [PFObject objectWithClassName:@"Prospect"];
    prospectObject[@"facebookId"] = invited[@"id"];
    prospectObject[@"name"] = invited[@"name"];
    [self createInvitation:invited[@"rsvp_status"] forUser:nil forProspect:prospectObject];
    
    /*
    //We see if there is an invitation for this user
    for(id invit in self.invited){
        PFObject *tempGuests = [FbEventsUtilities getProspectOrUserFromInvitation:invit];
        if ([tempGuests[@"facebookId"] isEqualToString:invited[@"id"]]) {
            guest = tempGuests;
            invitation = invit;
        }
    }
    
    //We already have an invitation and a guest we just update the invitation
    if (guest) {
        //Update guest or user
        if (![guest[@"name"] isEqualToString:invited[@"name"]]) {
            guest[@"name"] = invited[@"name"];
            [guest saveEventually];
        }
        
        //Update invitation
        if (![invitation[@"rsvp_status"] isEqualToString:invited[@"rsvp_status"]]) {
            invitation[@"rsvp_status"] = invited[@"rsvp_status"];
            [invitation saveEventually];
        }
        
        //We have finished with this user
        [[NSNotificationCenter defaultCenter] postNotificationName:InvitedDetailFinished object:self userInfo:nil];
    }
    
    //The invitation does not exist
    else{
        //See if a user or a prospect exist
        PFQuery *query = [PFUser query];
        [query whereKey:@"facebookId" equalTo:invited[@"id"]];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *userFound, NSError *error) {
            if (error && error.code == kPFErrorObjectNotFound) {
                ///////
                // PROSPECT EXISTS ??
                //////
                PFQuery *queryProspect = [PFQuery queryWithClassName:@"Prospect"];
                [queryProspect whereKey:@"facebookId" equalTo:invited[@"id"]];
                [queryProspect getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    
                    //If there is no prospect
                    if (error && error.code == kPFErrorObjectNotFound) {
                        //We create a prospect
                        PFObject *prospectObject = [PFObject objectWithClassName:@"Prospect"];
                        prospectObject[@"facebookId"] = invited[@"id"];
                        prospectObject[@"name"] = invited[@"name"];
                        [prospectObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            //And create invitation
                            [self createInvitation:invited[@"rsvp_status"] forUser:nil forProspect:prospectObject];
                        }];
                    }
                    //A prospect already exist, add invitation
                    else if(!error){
                        [self createInvitation:invited[@"rsvp_status"] forUser:nil forProspect:object];
                    }
                }];
            }
            else if(!error){
                //Invitation exists ?
                PFQuery *invitationUser = [PFQuery queryWithClassName:@"Invitation"];
                [invitationUser whereKey:@"user" equalTo:userFound];
                [invitationUser whereKey:@"event" equalTo:self.event];
                [invitationUser getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (error && error.code == kPFErrorObjectNotFound) {
                        [self createInvitation:invited[@"rsvp_status"] forUser:(PFUser *)userFound forProspect:nil];
                    }
                }];
                
                
            }
        }];
        
    }*/
    
}


-(void)createInvitation:(NSString *)rsvp forUser:(PFUser *)user forProspect:(PFObject *)prospect{
    PFObject *invitation = [PFObject objectWithClassName:@"Invitation"];
    [invitation setObject:self.event forKey:@"event"];
    
    invitation[@"isOwner"] = @NO;
    invitation[@"isAdmin"] = @NO;
    
    if (user) {
        [invitation setObject:user forKey:@"user"];
        if([EventUtilities isOwnerOfEvent:self.event forUser:user])
        {
            NSLog(@"You are the owner !!");
            invitation[@"isOwner"] = @YES;
        }
        
        if ([EventUtilities isAdminOfEvent:self.event  forUser:user]) {
            invitation[@"isAdmin"] = @YES;
        }
        
        invitation[@"is_memory"] = @NO;
    }
    else{
        [invitation setObject:prospect forKey:@"prospect"];
        if([EventUtilities isOwnerOfEvent:self.event  forUser:prospect])
        {
            NSLog(@"You are the owner !!");
            invitation[@"isOwner"] = @YES;
        }
        
        if ([EventUtilities isAdminOfEvent:self.event forUser:prospect]) {
            invitation[@"isAdmin"] = @YES;
        }
    }
    
    invitation[@"rsvp_status"] = rsvp;
    invitation[@"start_time"] = self.event[@"start_time"];
    
    [self.invited addObject:invitation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:InvitedDetailFinished object:self userInfo:nil];
    
    /*
    [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [self.invited addObject:invitation];
        [[NSNotificationCenter defaultCenter] postNotificationName:InvitedDetailFinished object:self userInfo:nil];
    }];*/
    
}

-(void)newDataTable{
    self.attending = [[NSMutableArray alloc] init];
    self.maybe = [[NSMutableArray alloc] init];
    self.no = [[NSMutableArray alloc] init];
    self.notjoined = [[NSMutableArray alloc] init];
    
    for(PFObject *invit in self.invited){
        if ([invit[@"rsvp_status"] isEqualToString:FacebookEventAttending]) {
            [self.attending addObject:invit];
        }
        else if ([invit[@"rsvp_status"] isEqualToString:FacebookEventMaybe]) {
            [self.maybe addObject:invit];
        }
        else if ([invit[@"rsvp_status"] isEqualToString:FacebookEventNotReplied]) {
            [self.notjoined addObject:invit];
        }
        else if ([invit[@"rsvp_status"] isEqualToString:FacebookEventDeclined]) {
            [self.no addObject:invit];
        }
    }
    
    [self.tableView reloadData];
    
}

-(void)greatMomentToUpdateInvited:(NSNotification *)note{
    self.nbInvitedAlreadyAdded++;
    
    
    if (self.nbInvitedAlreadyAdded==self.nbInvitedToAdd) {
        if (self.hasNext) {
            [self getGuestsFromFacebookEvent:self.afterCursor];
        }
        [self newDataTable];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }
    
    
}

@end

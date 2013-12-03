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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"InvitedListViewController_Title", nil);
    
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
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section ==0) {
        return @"Présents";
    }
    else if(section ==1){
        return @"Peut-être";
    }
    else if(section ==2){
        return @"Pas de réponse";
    }
    else{
        return @"Absent";
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

@end

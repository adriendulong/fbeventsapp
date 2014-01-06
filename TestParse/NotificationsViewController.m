//
//  NotificationsViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 09/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "NotificationsViewController.h"
#import "MOUtility.h"
#import "Notification.h"
#import "PhotosCollectionViewController.h"
#import "PhotoDetailViewController.h"

@interface NotificationsViewController ()

@end

@implementation NotificationsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [self.terminateButton setTitle:NSLocalizedString(@"UIBArButtonItem_Terminate", nil)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.notifications = [NSArray arrayWithArray:[MOUtility getNotifs]];
    if (self.notifications.count==0) {
        [self.tableView setHidden:YES];
    }
	// Do any additional setup after loading the view.
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
    return self.notifications.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Notification *notif = [self.notifications objectAtIndex:indexPath.row];
    
    UILabel *title = (UILabel *)[cell viewWithTag:3];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    
    title.text = notif.message;
    
    if ([notif.type intValue]==0) {
        imageView.image = [UIImage imageNamed:@"camera_orange"];
    }
    else {
        imageView.image = [UIImage imageNamed:@"chat"];
    }
    
    
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Notification *notif = [self.notifications objectAtIndex:indexPath.row];
    
    //Notif read one time, no more new
    [MOUtility notificationJustRead:notif];
    
    //Event Detail
    if ([notif.type intValue]==0) {
        self.selectedInvitation = [MOUtility invitationToParseInvitation:notif.invitation];
        [self performSegueWithIdentifier:@"EventDetail" sender:nil];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    else if([notif.type intValue] == 1){
        
        PFObject *photo = [PFObject objectWithClassName:@"Photo"];
        photo.objectId = notif.objectId;
        
        self.selectedPhoto = photo;
        [self performSegueWithIdentifier:@"PhotoDetail" sender:nil];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
}



- (IBAction)finish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"EventDetail"]) {
        PhotosCollectionViewController *photosCollectionViewController = segue.destinationViewController;
        photosCollectionViewController.invitation = self.selectedInvitation;
    }
    else if([segue.identifier isEqualToString:@"PhotoDetail"]){
        PhotoDetailViewController *photoDetail = segue.destinationViewController;
        photoDetail.photo = self.selectedPhoto;
    }
    
}

@end

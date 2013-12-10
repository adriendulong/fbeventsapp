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
        imageView.image = [UIImage imageNamed:@"chat"];
    }
    else {
        imageView.image = [UIImage imageNamed:@"chat"];
    }
        
    
    
    return cell;
    
}



- (IBAction)finish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

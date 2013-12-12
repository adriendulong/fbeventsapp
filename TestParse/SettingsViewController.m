//
//  SettingsViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 11/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "SettingsViewController.h"
#import "MOUtility.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LogInUser object:nil];
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.mustDismiss) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mustDismiss = NO;
    
    self.title = @"Preférences";
    self.navigationController.navigationBar.tintColor = [UIColor orangeColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logIn:) name:LogInUser object:nil];
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation[@"is_push_notif"]) {
        [self.switchNotifTel setOn:YES];
    }
    else{
        [self.switchNotifTel setOn:NO];
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
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 2;
    }
    else if (section == 1){
        return 3;
    }
    else{
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView
                       cellForRowAtIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==1) {
        
        //Remarques et preuves d'amour
        if (indexPath.row==0) {
            if ([MFMailComposeViewController canSendMail])
            {
                MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
                mailer.mailComposeDelegate = self;
                [mailer setSubject:@"A Message from "];
                NSArray *toRecipients = [NSArray arrayWithObjects:@"adrien@appmoment.fr",nil];
                [mailer setToRecipients:toRecipients];
                [self presentViewController:mailer animated:YES completion:NULL];
            }
            else{
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Problème" message:@"Problème lors de l'ouverture de l'email" delegate:self cancelButtonTitle:@"ok" otherButtonTitles: nil] ;
                [alert show];
            }
        }
        //Rank on the app store
        else if(indexPath.row==1){
            
        }
        //Go on facebook page
        else if (indexPath.row==2){
            
        }
    }
    else if (indexPath.section==2){
        //Conditions d'utilisations
        if (indexPath.row==0) {
            //Cool
        }

    }
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

- (IBAction)finish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)changeNotifTel:(id)sender {
    if (self.switchNotifTel.isOn) {
        
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        
        if (!currentInstallation.deviceToken) {
            [self.switchNotifTel setOn:NO];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notifications" message:@"Veuillez autoriser les notification pour cette application en allant dans Paramètres > Centre de notifications."delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ChooseLastEventViewController_OK", nil), nil];
            [alert show];
        }
        else{
            currentInstallation[@"is_push_notif"] = @YES;
            [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    
                }
            }];
        }
        
        
    }
    else{
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        currentInstallation[@"is_push_notif"] = @NO;
        [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [self.switchNotifTel setOn:YES];
            }
        }];
    }
    
}
- (IBAction)changeNotifMail:(id)sender {
    if(self.swithNotifMail.isOn){
        PFUser *currentUser = [PFUser currentUser];
        currentUser[@"is_mail_notif"] = @YES;
        [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [self.swithNotifMail setOn:NO];
            }
        }];
    }
    else{
        PFUser *currentUser = [PFUser currentUser];
        currentUser[@"is_mail_notif"] = @NO;
        [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [self.swithNotifMail setOn:YES];
            }
        }];
    }
}


-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Email Cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Email Saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Email Sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Email Failed");
            break;
        default:
            NSLog(@"Email Not Sent");
            break;
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}



# pragma mark - Prepare Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"Login"]){
        [[NSNotificationCenter defaultCenter] postNotificationName:LogOutUser object:self];
        [MOUtility logoutApp];
        
    }
}

-(void)logIn:(NSNotification *)note{
    self.mustDismiss = YES;
}


@end

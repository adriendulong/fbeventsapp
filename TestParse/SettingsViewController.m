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

-(void)viewWillAppear:(BOOL)animated{
    [TestFlight passCheckpoint:@"SETTINGS"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mustDismiss = NO;
    
    self.title = NSLocalizedString(@"SettingsViewController_Title", nil);
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
        return 2;
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
                [mailer setSubject:NSLocalizedString(@"SettingsViewController_Mail_Object", nil)];
                NSArray *toRecipients = [NSArray arrayWithObjects:@"adrien@appmoment.fr",nil];
                [mailer setToRecipients:toRecipients];
                [self presentViewController:mailer animated:YES completion:NULL];
            }
            else{
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Problem_Title", nil) message:NSLocalizedString(@"UIAlertView_Problem_Message4", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"UIAlertView_Dismiss", nil)  otherButtonTitles: nil] ;
                [alert show];
            }
        }
        //Go on facebook page
        else if (indexPath.row==1){
            NSURL *url = [NSURL URLWithString:@"fb://page/600308563362702"];
            if(![[UIApplication sharedApplication] openURL:url]){
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://facebook.com/woovent"]];
            }
        }
    }
    else if (indexPath.section==2){
        //Conditions d'utilisations
        if (indexPath.row==0) {
            //Cool
        }

    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}


- (IBAction)finish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)changeNotifTel:(id)sender {
    if (self.switchNotifTel.isOn) {
        
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        
        if (!currentInstallation.deviceToken) {
            [self.switchNotifTel setOn:NO];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Notifs_Title", nil) message:NSLocalizedString(@"UIAlertView_Notifs_Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ChooseLastEventViewController_OK", nil), nil];
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
        [TestFlight passCheckpoint:@"DISCONNECT"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:LogOutUser object:self];
        [MOUtility logoutApp];
        
    }
}

-(void)logIn:(NSNotification *)note{
    self.mustDismiss = YES;
}


@end
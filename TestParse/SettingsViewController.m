//
//  SettingsViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 11/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "SettingsViewController.h"
#import "MOUtility.h"
#import "FbEventsUtilities.h"

@implementation APActivityIconSettings
- (NSString *)activityType { return @"com.moment.rateApp"; }
- (NSString *)activityTitle { return NSLocalizedString(@"SettingsViewController_rateApp", nil); }
- (UIImage *) activityImage { return [UIImage imageNamed:@"heart_off"]; }
- (BOOL) canPerformWithActivityItems:(NSArray *)activityItems { return YES; }
- (void) prepareWithActivityItems:(NSArray *)activityItems { }
- (UIViewController *) activityViewController { return nil; }
- (void) performActivity {
   //Open App Store
    NSString *iTunesLink = @"itms-apps://itunes.com/apps/woovent";
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
}
@end

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
    
    //Init
    self.iPhoneNotifLabel.text = NSLocalizedString(@"SettingsViewController_iPhoneNotifs", nil);
    self.mailNotifLabel.text = NSLocalizedString(@"SettingsViewController_mailNotifs", nil);
    self.supportLabel.text = NSLocalizedString(@"SettingsViewController_support", nil);
    self.facebookLabel.text = NSLocalizedString(@"SettingsViewController_wooventFB", nil);
    self.cguLabel.text = NSLocalizedString(@"SettingsViewController_CGU", nil);
    self.disconnectLabel.text = NSLocalizedString(@"SettingsViewController_disconnect", nil);
    self.thanksLabel.text =  NSLocalizedString(@"SettingsViewController_Thanks", nil);
    self.myStatsLabel.text = NSLocalizedString(@"SettingsViewController_myStats", nil);
    [self.finishLabel setTitle:NSLocalizedString(@"UIBArButtonItem_Terminate", nil)];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mustDismiss = NO;
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [UIColor whiteColor],NSForegroundColorAttributeName,
                                    [UIColor whiteColor],NSBackgroundColorAttributeName,
                                    [MOUtility getFontWithSize:20.0] , NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    self.title = NSLocalizedString(@"SettingsViewController_Title", nil);
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logIn:) name:LogInUser object:nil];
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if ([currentInstallation[@"is_push_notif"] boolValue]) {
        [self.switchNotifTel setOn:YES];
    }
    else{
        [self.switchNotifTel setOn:NO];
    }
    
    PFUser *user = [PFUser currentUser];
    if ([user[@"is_mail_notif"] boolValue]) {
        [self.swithNotifMail setOn:YES];
    }
    else{
        [self.swithNotifMail setOn:NO];
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

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section==0) {
        return NSLocalizedString(@"SettingsViewController_TitleSectionOne", nil);
    }
    else if(section == 1){
        return NSLocalizedString(@"SettingsViewController_TitleSectionTwo", nil);
    }
    else if(section == 2)
    {
        return NSLocalizedString(@"SettingsViewController_TitleSectionThree", nil);
    }
    else{
        return NSLocalizedString(@"SettingsViewController_TitleSectionFour", nil);
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    if (section == 3) {
        NSString *version = [NSString stringWithFormat:@"Woovent v%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
        return version;
    }
    else{
        return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    else if (section == 1) {
        return 3;
    }
    else if (section == 2){
        return 2;
    }
    else{
        return 3;
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
    if (indexPath.section==0) {
        if (indexPath.row==0) {
            [self share];
        }
    }
    else if (indexPath.section==1) {
        if (indexPath.row==2) {
            [self performSegueWithIdentifier:@"CountEvents" sender:nil];
        }
    }
    else if (indexPath.section==2) {
        
        //Remarques et preuves d'amour
        if (indexPath.row==0) {
            if ([MFMailComposeViewController canSendMail])
            {
                MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
                mailer.mailComposeDelegate = self;
                [mailer setSubject:NSLocalizedString(@"SettingsViewController_Mail_Object", nil)];
                NSArray *toRecipients = [NSArray arrayWithObjects:@"adrien@woovent.com",nil];
                [mailer setToRecipients:toRecipients];
                [self presentViewController:mailer animated:YES completion:NULL];
            }
            else if(indexPath.row==1){
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Problem_Title", nil) message:NSLocalizedString(@"UIAlertView_Problem_Message4", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"UIAlertView_Dismiss", nil)  otherButtonTitles: nil] ;
                [alert show];
            }
        }
        //Go on facebook page
        else if (indexPath.row==1){
            NSURL *url = [NSURL URLWithString:@"fb://profile/600308563362702"];
            if(![[UIApplication sharedApplication] openURL:url]){
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://facebook.com/woovent"]];
            }
        }
    }
    else if (indexPath.section==3){
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
        [[Mixpanel sharedInstance].people set:@{@"is_mail_notif": @YES}];
        
        [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [self.swithNotifMail setOn:NO];
            }
        }];
    }
    else{
        PFUser *currentUser = [PFUser currentUser];
        currentUser[@"is_mail_notif"] = @NO;
        [[Mixpanel sharedInstance].people set:@{@"is_mail_notif": @NO}];
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
    NSString *b = note.userInfo[@"is_new"];
    NSLog(@"%@", b);

    self.mustDismiss = YES;
}


-(void)share{
    NSString *message = [NSString  stringWithFormat:NSLocalizedString(@"SettingsViewController_ShareApp", nil)];
    NSArray *urlToShare = [NSArray arrayWithObjects:message, nil];
    
    
    //Custom Save Date
    APActivityIconSettings *ca = [[APActivityIconSettings alloc] init];
    NSArray *Acts = @[ca];
    
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:urlToShare applicationActivities:Acts];
    [controller setValue:NSLocalizedString(@"SettingsViewController_ShareAppTitle", nil) forKey:@"subject"];
    NSArray *excludedActivities = @[UIActivityTypePostToWeibo,
                                    UIActivityTypeAirDrop,
                                    UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                                    UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,
                                    UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
    controller.excludedActivityTypes = excludedActivities;
    
    controller.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (completed) {
            [[Mixpanel sharedInstance] track:@"Share App" properties:@{@"type": activityType}];
        }
    };
    
    [self presentViewController:controller animated:YES completion:nil];
}


@end

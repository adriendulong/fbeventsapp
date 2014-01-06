//
//  FirstLaunchViewController.m
//  TestParse
//
//  Created by Adrien Dulong on 12/10/13.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "FirstLaunchViewController.h"

@interface FirstLaunchViewController ()

@end

@implementation FirstLaunchViewController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

#pragma mark Facebook Login & Sign Up

- (IBAction)facebook:(id)sender {
    //LOADER
    UIActivityIndicatorView *activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.center=self.view.center;
    [activityView startAnimating];
    [self.view addSubview:activityView];
    
    
    NSArray *permissionsArray = @[@"user_about_me", @"user_birthday", @"user_location", @"email", @"user_events", @"read_stream",
                                 @"user_photos", @"friends_photo"];
    
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {
            if (!error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_ErrorLogin_Title", nil) message:NSLocalizedString(@"UIAlertView_ErrorLogin_Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
                [alert show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_ErrorLogin_Title", nil) message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
                [alert show];
            }
        } else if (user.isNew) {
            [self updateUserInfos];
        } else {
            [self updateUserInfos];
        }
    }];
}

-(void)updateUserInfos{
    FBRequest *request = [FBRequest requestForMe];
    
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // result is a dictionary with the user's Facebook data
            NSDictionary *userData = (NSDictionary *)result;
            
            NSString *facebookID = userData[@"id"];

            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            PFUser *currentUser = [PFUser currentUser];
            currentUser.email = userData[@"email"];
            
            if(userData[@"id"]){
                currentUser[@"facebookId"] = userData[@"id"];
            }
            
            if(userData[@"first_name"]){
                currentUser[@"first_name"] = userData[@"first_name"];
            }
            
            if(userData[@"last_name"]){
                currentUser[@"last_name"] = userData[@"last_name"];
            }
            
            if(userData[@"location"][@"name"]){
                currentUser[@"location"] = userData[@"location"][@"name"];
            }
            
            if(userData[@"gender"]){
                currentUser[@"gender"] = userData[@"gender"];
            }
            
            if(userData[@"birthday"]){
                currentUser[@"birthday"] = userData[@"birthday"];
            }
            
            currentUser[@"pictureURL"] = [pictureURL absoluteString];
            
            [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [self dismissViewControllerAnimated:NO completion:nil];
                } else {
                    NSLog(@"%@",[error userInfo][@"error"]);
                }
            }];
        }
    }];
}



@end

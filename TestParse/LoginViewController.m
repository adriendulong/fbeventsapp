//
//  LoginViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 15/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "LoginViewController.h"
#import "TutorialViewController.h"
#import "MOUtility.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

#define IS_BIG_SCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )


@interface LoginViewController ()

@end

@implementation LoginViewController
@synthesize myDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    self.mixpanel = [Mixpanel sharedInstance];
    [self.mixpanel track:@"LoginView Show"];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:@"Login View"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    self.isNewUser = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Init label
    [self.cguButton setTitle:NSLocalizedString(@"LoginViewController_CGU", nil) forState:UIControlStateNormal];
    [self.facebookButton setTitle:NSLocalizedString(@"LoginViewController_ConnectFB", nil) forState:UIControlStateNormal];
    
    [self.activityIndicator setHidden:YES];
    
	// Do any additional setup after loading the view.
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                          navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                        options:nil];
    
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    //[[self.pageController view] setFrame:[[self view] bounds]];
    CGRect viewFrame = self.view.bounds;
    
    if (IS_BIG_SCREEN) {
        viewFrame.size.height -= 100;
    }
    else{
        viewFrame.size.height -= 65;
    }
    
    [[self.pageController view] setFrame:viewFrame];
    
    TutorialViewController *initialViewController = [self viewControllerAtIndex:0];
    
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    [self.pageController setViewControllers:viewControllers
                                  direction:UIPageViewControllerNavigationDirectionForward
                                   animated:NO
                                 completion:nil];
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
    
    self.pageControl = [self getPageControl];
    [self setPageIndicatorTintColor:[UIColor grayColor]];
    [self setCurrentPageIndicatorTintColor:[UIColor orangeColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




- (TutorialViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TutorialViewController *childViewController = [storyboard instantiateViewControllerWithIdentifier:@"TutorialViewController"];
    childViewController.index = index;
    
    return childViewController;
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(TutorialViewController *)viewController index];
    
    if (index == 0) {
        return nil;
    }
    
    // Decrease the index by 1 to return
    index--;
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(TutorialViewController *)viewController index];
    
    index++;
    
    if (index == 4) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
    
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    // The number of items reflected in the page indicator.
    return 4;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    // The selected item reflected in the page indicator.
    return 0;
}

- (UIPageControl *)getPageControl
{
    NSArray *subviews = self.pageController.view.subviews;
    UIPageControl *thisControl = nil;
    for (int i=0; i<[subviews count]; i++) {
        if ([[subviews objectAtIndex:i] isKindOfClass:[UIPageControl class]]) {
            thisControl = (UIPageControl *)[subviews objectAtIndex:i];
        }
    }
    
    return thisControl;
}

- (void)setPageIndicatorTintColor:(UIColor *)color
{
    self.pageControl.pageIndicatorTintColor = color;
}

- (void)setCurrentPageIndicatorTintColor:(UIColor *)color
{
    self.pageControl.currentPageIndicatorTintColor = color;
}

#pragma mark Facebook Login & Sign Up

- (IBAction)facebook:(id)sender {
    [[Mixpanel sharedInstance] track:@"Click Login Button"];
    
    
    //LOADER
    [self.activityIndicator setHidden:NO];
    
    
    NSArray *permissionsArray = @[@"user_about_me", @"user_birthday", @"user_location", @"email", @"user_events", @"read_stream"];
    
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (error) {
            [self.activityIndicator setHidden:YES];
            [self handleAuthError:error];
        }
        /*if (!user) {
            [[Mixpanel sharedInstance] track:@"Error Login"];
            if (!error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_ErrorLogin_Title", nil) message:NSLocalizedString(@"UIAlertView_ErrorLogin_Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
                [alert show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_ErrorLogin_Title", nil) message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
                [alert show];
            }
        } */else if (user.isNew) {
            self.isNewUser = YES;
            //Mixpanel
            [self.mixpanel createAlias:user.objectId
                    forDistinctID:[Mixpanel sharedInstance].distinctId];
            [self.mixpanel identify:user.objectId];
            [self.mixpanel track:@"New User"];
            [[Mixpanel sharedInstance].people set:@{@"$created": [NSDate date]}];

            UIApplication *application = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).application;
            [application setMinimumBackgroundFetchInterval:TimeIntervalFetch];
            
            //Attach this user to this device
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            currentInstallation[@"owner"] = user;
            [currentInstallation saveInBackground];
            
            [self updateUserInfos];
        } else {
            //Mixpanel
            [self.mixpanel identify:user.objectId];
            [self.mixpanel track:@"Login Existing User"];
            
            UIApplication *application = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).application;
            [application setMinimumBackgroundFetchInterval:TimeIntervalFetch];
            
            //Attach this user to this device
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            currentInstallation[@"owner"] = user;
            [currentInstallation saveInBackground];
            
            [self updateUserInfos];
        }
    }];
}

-(void)updateUserInfos{
    FBRequest *request = [FBRequest requestForMe];
    [self.mixpanel identify:[PFUser currentUser].objectId];
    
    //[self.mixpanel.people set:@{@"is_mail_notif": [PFUser currentUser][@"is_mail_notif"]}];
    
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // result is a dictionary with the user's Facebook data
            NSDictionary *userData = (NSDictionary *)result;
            
            NSString *facebookID = userData[@"id"];
            
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            PFUser *currentUser = [PFUser currentUser];
            currentUser.email = userData[@"email"];
            [self.mixpanel.people set:@{@"$email": currentUser.email}];
            
            if(userData[@"id"]){
                currentUser[@"facebookId"] = userData[@"id"];
            }
            
            if(userData[@"first_name"]){
                currentUser[@"first_name"] = userData[@"first_name"];
                [self.mixpanel.people set:@{@"First Name": currentUser[@"first_name"]}];
            }
            
            if(userData[@"last_name"]){
                currentUser[@"last_name"] = userData[@"last_name"];
                [self.mixpanel.people set:@{@"Last Name": currentUser[@"last_name"]}];
            }
            
            if(userData[@"name"]){
                currentUser[@"name"] = userData[@"name"];
                [[Mixpanel sharedInstance].people set:@{@"$name": currentUser[@"name"]}];
            }
            
            if(userData[@"location"][@"name"]){
                currentUser[@"location"] = userData[@"location"][@"name"];
                [self.mixpanel.people set:@{@"Location": currentUser[@"location"]}];
                [self.mixpanel registerSuperProperties:@{@"Location": currentUser[@"location"]}];
            }
            
            if(userData[@"gender"]){
                
                currentUser[@"gender"] = userData[@"gender"];
                [self.mixpanel registerSuperProperties:@{@"Gender": currentUser[@"gender"]}];
                [self.mixpanel.people set:@{@"Gender": currentUser[@"gender"]}];
            }
            
            if(userData[@"birthday"]){
                currentUser[@"birthday"] = userData[@"birthday"];
                [self.mixpanel registerSuperProperties:@{@"Birthday": [MOUtility birthdayStringToDate:userData[@"birthday"]]}];
                [self.mixpanel.people set:@{@"Birthday": [MOUtility birthdayStringToDate:userData[@"birthday"]]}];
            }
            
            currentUser[@"pictureURL"] = [pictureURL absoluteString];
            [self.mixpanel.people set:@{@"$profile_picture": currentUser[@"pictureURL"]}];
            currentUser[@"is_mail_notif"] = @YES;
            
            [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    //Update permissions
                    FBRequest *requestPerms = [FBRequest requestForGraphPath:@"me/permissions"];
                    [requestPerms startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                        PFUser *currentUser =[PFUser currentUser];
                        
                        NSArray *permissions = result[@"data"];
                        if ([[permissions objectAtIndex:0][@"rsvp_event"] intValue] == 1) {
                            currentUser[@"has_rsvp_perm"] = @YES;
                        }
                        else{
                            currentUser[@"has_rsvp_perm"] = @NO;
                        }
                        
                        if ([[permissions objectAtIndex:0][@"publish_stream"] intValue] == 1) {
                            currentUser[@"has_publish_perm"] = @YES;
                        }
                        else{
                            currentUser[@"has_publish_perm"] = @NO;
                        }
                        
                        [currentUser saveInBackground];
                        

                       
                        [[NSNotificationCenter defaultCenter] postNotificationName:LogInUser object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:self.isNewUser] forKey:@"is_new"]];
                        /*if([self.myDelegate respondsToSelector:@selector(comingFromLogin)])
                         {
                         [self.myDelegate comingFromLogin];
                         }*/
                        
                        [self dismissViewControllerAnimated:NO completion:nil];
                    }];
                } else {
                    
                    NSDictionary *userInfo = @{@"is_new": [NSNumber numberWithBool:self.isNewUser]};
                    [[NSNotificationCenter defaultCenter] postNotificationName:LogInUser object:userInfo];
                    /*if([self.myDelegate respondsToSelector:@selector(comingFromLogin)])
                     {
                     [self.myDelegate comingFromLogin];
                     }*/
                    
                    [self dismissViewControllerAnimated:NO completion:nil];
                }
            }];
        }
    }];
}

- (void)handleAuthError:(NSError *)error
{
    NSString *alertText;
    NSString *alertTitle;
    if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
        // Error requires people using you app to make an action outside your app to recover
        alertTitle = @"Something went wrong";
        alertText = [FBErrorUtility userMessageForError:error];
        [self showMessage:alertText withTitle:alertTitle];
        
    } else {
        // You need to find more information to handle the error within your app
        if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
            //The user refused to log in into your app, either ignore or...
            alertTitle = @"Login cancelled";
            alertText = @"You need to login to access this part of the app";
            [self showMessage:alertText withTitle:alertTitle];
            
        } else {
            // All other errors that can happen need retries
            // Show the user a generic error message
            alertTitle = @"Something went wrong";
            alertText = @"Please retry";
            [self showMessage:alertText withTitle:alertTitle];
        }
    }
}

- (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}


@end

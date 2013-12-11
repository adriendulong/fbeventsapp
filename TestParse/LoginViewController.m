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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
        viewFrame.size.height -= 50;
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
    //LOADER
    [self.activityIndicator setHidden:NO];
    
    
    NSArray *permissionsArray = @[@"user_about_me", @"user_birthday", @"user_location", @"email", @"user_events", @"read_stream"];
    
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_ErrorLogin_Title", nil) message:NSLocalizedString(@"UIAlertView_ErrorLogin_Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
                [alert show];
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_ErrorLogin_Title", nil) message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
                [alert show];
            }
        } else if (user.isNew) {
            
            //Attach this user to this device
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            currentInstallation[@"owner"] = user;
            [currentInstallation saveInBackground];
            
            [self updateUserInfos];
        } else {
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
    
    NSLog(@" Facebook session :%@", [[[PFFacebookUtils session] accessTokenData] expirationDate]);
    
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
                
                if ([MOUtility isATestUser:currentUser[@"facebookId"]]) {
                    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                    [currentInstallation addUniqueObject:@"Testers" forKey:@"channels"];
                    [currentInstallation saveInBackground];
                }
                

            }
            
            if(userData[@"first_name"]){
                currentUser[@"first_name"] = userData[@"first_name"];
            }
            
            if(userData[@"last_name"]){
                currentUser[@"last_name"] = userData[@"last_name"];
            }
            
            if(userData[@"name"]){
                currentUser[@"name"] = userData[@"name"];
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
            currentUser[@"is_mail_notif"] = @YES;
            
            [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:LogInUser object:self];
                    /*if([self.myDelegate respondsToSelector:@selector(comingFromLogin)])
                    {
                        [self.myDelegate comingFromLogin];
                    }*/
                    
                    [self dismissViewControllerAnimated:NO completion:nil];
                } else {
                    NSLog(@"%@",[error userInfo][@"error"]);
                }
            }];
        }
    }];
}

@end

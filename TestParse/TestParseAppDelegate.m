//
//  TestParseAppDelegate.m
//  TestParse
//
//  Created by Adrien Dulong on 08/10/13.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "TestParseAppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>
#import "TestFlight.h"

@implementation TestParseAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight takeOff:@"abb31330-3ffd-4455-ab95-dd07c3381468"];
    
    //Google maps
    [GMSServices provideAPIKey:@"AIzaSyBOpJuAT7dEsXCxPbd_6m89wJPUbEIEM80"];
    
    // Override point for customization after application launch.
    [Parse setApplicationId:@"5eiOkg1KxyOMYD1elwGQZIPsYQ19lD6NO4XoNgZc"
                  clientKey:@"ePcZZ8UymNn0lv0FI4ZdAiwfCT9V3EQ31e9EIogm"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    //Facebook init
    [PFFacebookUtils initializeFacebook];
    
    CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
    
    UIStoryboard *iPhoneStoryboard = (iOSDeviceScreenSize.height == 480) ? [UIStoryboard storyboardWithName:@"Storyboard_iPhone35" bundle:nil] : [UIStoryboard storyboardWithName:@"Storyboard_iPhone35" bundle:nil];
    
    UIViewController *viewController = [iPhoneStoryboard instantiateInitialViewController];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController  = viewController;
    [self.window makeKeyAndVisible];
    
    //Customize Tab bar Text
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor orangeColor]
                                                        } forState:UIControlStateSelected];
    
    //Init
    self.needToRefreshEvents = NO;
    
    return YES;
}


//Handle Single Sign On FB
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [PFFacebookUtils handleOpenURL:url];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"ENTER FOREGROUND");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"BECOME ACTIVE");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

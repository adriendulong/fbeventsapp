//
//  TestParseAppDelegate.m
//  TestParse
//
//  Created by Adrien Dulong on 08/10/13.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "TestParseAppDelegate.h"
#import "TestFlight.h"
#import "PhotosCollectionViewController.h"
#import "PhotoDetailViewController.h"
#import "MOUtility.h"
#import "ListInvitationsController.h"
#import "ListEvents.h"
#import "GAI.h"
#import <Crashlytics/Crashlytics.h>
#import "KeenClient.h"
#import "Constants.h"
#import "AppsfireSDK.h"
#import "AppsfireAdSDK.h"


@implementation TestParseAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    //Prod or Dev
    self.isProdApp = NO;
    
    #warning DEVCONFIG
    [TestFlight takeOff:@"730fc4c1-31c0-4954-815c-db37d664150a"];
    
    //Mixpanel
    [Mixpanel sharedInstanceWithToken:MixpanelToken];
    [[Mixpanel sharedInstance].people set:@{@"language": [[NSLocale preferredLanguages] objectAtIndex:0]}];
    
    // Initialize tracker.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-46687213-1"];
    
    // Override point for customization after application launch.
#warning DEVCONFIG
    [Parse setApplicationId:[MOUtility getParseAppId]
                  clientKey:[MOUtility getParseClientKey]];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    //Facebook init
    [PFFacebookUtils initializeFacebook];
    
    //Appsfire
    [AppsfireSDK connectWithAPIKey:@"26256D854142A235E899A6BD9ADDA2A2"];
    
#ifdef DEBUG
    [AppsfireAdSDK setDebugModeEnabled:YES];
#endif
    
    //Prepare
    [AppsfireAdSDK prepare];
    
    //Crashlytics
    [Crashlytics startWithAPIKey:@"9e1ac2698261626f408a06299471b1f9ca65f65e"];
    
    // Register for push notifications
    [application registerForRemoteNotificationTypes:
                            UIRemoteNotificationTypeBadge |
                            UIRemoteNotificationTypeAlert |
                            UIRemoteNotificationTypeSound];
    
    //Customize Tab bar Text and icons
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor orangeColor]
                                                        } forState:UIControlStateSelected];
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    [[tabBarController.tabBar.items objectAtIndex:0] setFinishedSelectedImage:[UIImage imageNamed:@"my_events_on.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"my_events_off.png"]];
    [[tabBarController.tabBar.items objectAtIndex:1] setFinishedSelectedImage:[UIImage imageNamed:@"invitations_on.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"invitations_off.png"]];
    [[tabBarController.tabBar.items objectAtIndex:2] setFinishedSelectedImage:[UIImage imageNamed:@"heart_on.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"heart_off.png"]];
    //[[tabBarController.tabBar.items objectAtIndex:3] setFinishedSelectedImage:[UIImage imageNamed:@"fire_on"] withFinishedUnselectedImage:[UIImage imageNamed:@"fire_off"]];
    [[tabBarController.tabBar.items objectAtIndex:0] setTitle:NSLocalizedString(@"UITabBar_Title_FirstPosition", nil)];
    [[tabBarController.tabBar.items objectAtIndex:1] setTitle:NSLocalizedString(@"UITabBar_Title_SecondPosition", nil)];
    [[tabBarController.tabBar.items objectAtIndex:2] setTitle:NSLocalizedString(@"UITabBar_Title_ThirdPosition", nil)];
    //[[tabBarController.tabBar.items objectAtIndex:3] setTitle:NSLocalizedString(@"UITabBar_Title_FourthPosition", nil)];
    
    //Init
    self.needToRefreshEvents = NO;
    self.storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    
    
    
    ////////////////
    // PUSH ///////
    //////////////
    
    //Track
    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double
        // counting the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    
    //Clear Badge
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation[@"modelName"] = [[UIDevice currentDevice] name];
        currentInstallation[@"language"] = [[NSLocale preferredLanguages] objectAtIndex:0];
        currentInstallation[@"iosVersion"] = [[UIDevice currentDevice] systemVersion];
        currentInstallation.badge = 0;
        
        [currentInstallation saveEventually];
    }
    else{
        currentInstallation[@"modelName"] = [[UIDevice currentDevice] name];
        currentInstallation[@"iosVersion"] = [[UIDevice currentDevice] systemVersion];
        currentInstallation[@"language"] = [[NSLocale preferredLanguages] objectAtIndex:0];
        [currentInstallation saveEventually];
    }
    
    //Fetch Background
    self.application = application;
    
    [PFPush handlePush:launchOptions];
    
    /* PUSH */
    
    if ([launchOptions valueForKey:@"e"]!=nil) {
        //New Photo in event
        NSString *eventId = [launchOptions objectForKey:@"e"];
        
        PFQuery *innerQueryEvent = [PFQuery queryWithClassName:@"Event"];
        [innerQueryEvent whereKey:@"objectId" equalTo:eventId];
        
        PFQuery *queryInvit = [PFQuery queryWithClassName:@"Invitation"];
        [queryInvit whereKey:@"event" matchesQuery:innerQueryEvent];
        [queryInvit includeKey:@"event"];
        queryInvit.cachePolicy = kPFCachePolicyCacheElseNetwork;
        
        [queryInvit getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (error && error.code == kPFErrorObjectNotFound) {
                //completionHandler(UIBackgroundFetchResultFailed);
            }else if ([PFUser currentUser]) {
                PhotosCollectionViewController *viewController = (PhotosCollectionViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotosCollectionEvent"];
                viewController.invitation = object;
                viewController.hidesBottomBarWhenPushed = YES;
                
                UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
                UINavigationController *navController = (UINavigationController *)tabBar.selectedViewController;
                [navController pushViewController:viewController animated:YES];
                
                //completionHandler(UIBackgroundFetchResultNewData);
            } else {
                //completionHandler(UIBackgroundFetchResultNoData);
            }
            
        }];
    }
    else if([launchOptions valueForKey:@"p"]!=nil){
        //New interaction on a photo
        NSString *photoId = [launchOptions objectForKey:@"p"];
        
        PFQuery *queryPhoto = [PFQuery queryWithClassName:@"Photo"];
        [queryPhoto whereKey:@"objectId" equalTo:photoId];
        [queryPhoto includeKey:@"user"];
        [queryPhoto includeKey:@"prospect"];
        queryPhoto.cachePolicy = kPFCachePolicyCacheElseNetwork;
        
        [queryPhoto getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (error && error.code == kPFErrorObjectNotFound) {
                //completionHandler(UIBackgroundFetchResultFailed);
            }else if ([PFUser currentUser]) {
                
                PhotoDetailViewController *viewController = (PhotoDetailViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotoDetail"];
                viewController.photo = object;
                viewController.hidesBottomBarWhenPushed = YES;
                
                UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
                UINavigationController *navController = (UINavigationController *)tabBar.selectedViewController;
                [navController pushViewController:viewController animated:YES];
                
                //completionHandler(UIBackgroundFetchResultNewData);
            } else {
                //completionHandler(UIBackgroundFetchResultNoData);
            }
            
        }];
    }
    else if([launchOptions valueForKey:@"type"]!=nil){
        if([[launchOptions valueForKey:@"type"] intValue]==0){
            if ([PFUser currentUser]) {
                UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
                [tabBar setSelectedIndex:1];
                
                //completionHandler(UIBackgroundFetchResultNewData);
            }
            
        }
    }
    
    
    
    ////// LOCAL Notifs
    UILocalNotification *locationNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (locationNotification) {
        // Set icon badge number to zero
        NSString *objectIdInvit = locationNotification.userInfo[@"invitationId"];
        
        PFQuery *queryInvit = [PFQuery queryWithClassName:@"Invitation"];
        [queryInvit whereKey:@"objectId" equalTo:objectIdInvit];
        [queryInvit includeKey:@"event"];
        queryInvit.cachePolicy = kPFCachePolicyCacheElseNetwork;
        
        [queryInvit getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (error && error.code == kPFErrorObjectNotFound) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem"
                                                                message:@"There was a problem accessing to this event."
                                                               delegate:self cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                
            }else if ([PFUser currentUser]) {
                PhotosCollectionViewController *viewController = (PhotosCollectionViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotosCollectionEvent"];
                viewController.invitation = object;
                viewController.hidesBottomBarWhenPushed = YES;
                
                UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
                UINavigationController *navController = (UINavigationController *)tabBar.selectedViewController;
                [navController pushViewController:viewController animated:YES];
                
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem"
                                                                message:@"There was a problem accessing to this event."
                                                               delegate:self cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            
        }];
    }
    
    
    
    //Update user infos
    if ([PFUser currentUser]) {
        [MOUtility updateUserInfos];
    }
    
    //Use to say we come back after a facebook auth
    self.comeFromFB = NO;
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    /*return [FBAppCall handleOpenUrl:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];*/
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
            withSession:[PFFacebookUtils session]
                    fallbackHandler:^(FBAppCall *call) {
                        NSLog(@"In fallback handler");
                    }];
}

//Handle Single Sign On FB
/*
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [PFFacebookUtils handleOpenURL:url];
}*/

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSNumber *seconds = @([[NSDate date] timeIntervalSinceDate:self.startTime]);
    [[Mixpanel sharedInstance] track:@"Session" properties:@{@"Length": seconds}];
    
    NSDictionary *event= [NSDictionary dictionaryWithObjectsAndKeys: seconds, @"length", nil];
    [[KeenClient sharedClient] addEvent:event toEventCollection:@"Session" error:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    UIBackgroundTaskIdentifier taskId = [application beginBackgroundTaskWithExpirationHandler:^(void) {
        NSLog(@"Background task is being expired.");
    }];
    
    [[KeenClient sharedClient] uploadWithFinishedBlock:^(void) {
        [application endBackgroundTask:taskId];
    }];

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    //reload events
    if ([PFUser currentUser]) {
        if (!self.comeFromFB) {
            UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
            UINavigationController *navController = (UINavigationController *)[tabBar.viewControllers objectAtIndex:0];
            ListEvents *listEvents = (ListEvents *)[navController.viewControllers objectAtIndex:0];
            [listEvents fbReload:nil];
        }
        else{
            self.comeFromFB = NO;
        }
    }
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSArray *localNotifs = [[UIApplication sharedApplication] scheduledLocalNotifications];

    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSettings setDefaultAppID:FacebookAppId];
    [FBAppEvents activateApp];
    [[Mixpanel sharedInstance] track:@"App Open"];
    [[Mixpanel sharedInstance].people set:@{@"Last Session": [NSDate date]}];
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
    
    //Clear Badge
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        
        [currentInstallation saveEventually];
    }
    
    self.startTime = [NSDate date];
    
    [KeenClient disableGeoLocation];
    [KeenClient sharedClientWithProjectId:[MOUtility getKeenProjectId]
                              andWriteKey:[MOUtility getKeenWriteKey]
                               andReadKey:[MOUtility getKeenReadKey]];
    
    KeenClient *client = [KeenClient sharedClient];
    client.globalPropertiesBlock = ^NSDictionary *(NSString *eventCollection) {
        if ([PFUser currentUser]){
            PFUser *user = [PFUser currentUser];
            
            NSMutableDictionary *infos = [[NSMutableDictionary alloc] init];
            [infos setObject:user.objectId forKey:@"id"];
            if (user[@"name"]) {
                [infos setObject:user[@"name"] forKey:@"name"];
            }
            if (user[@"location"]) {
                [infos setObject:user[@"location"] forKey:@"location"];
            }
            if (user[@"facbeookId"]) {
                [infos setObject:user[@"facbeookId"] forKey:@"facbeookId"];
            }
            if (user[@"email"]) {
                [infos setObject:user[@"email"] forKey:@"email"];
            }
            
            return [infos copy];
        }
        else{
            return nil;
        }
    };
    
    NSDictionary *event;
    if ([PFUser currentUser]) {
        event= [NSDictionary dictionaryWithObjectsAndKeys: @YES, @"with_user", nil];
    }
    else{
        event= [NSDictionary dictionaryWithObjectsAndKeys: @NO, @"with_user", nil];
    }
    
    [[KeenClient sharedClient] addEvent:event toEventCollection:@"App Open" error:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    currentInstallation[@"is_push_notif"] = @YES;
    [currentInstallation saveInBackground];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel.people addPushDeviceToken:newDeviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    
    if (application.applicationState == UIApplicationStateInactive) {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    
    if (application.applicationState == UIApplicationStateActive) {
        
        if ([userInfo valueForKey:@"e"]!=nil) {
            //New Photo in event
            NSString *eventId = [userInfo objectForKey:@"e"];
            
            PFQuery *innerQueryEvent = [PFQuery queryWithClassName:@"Event"];
            [innerQueryEvent whereKey:@"objectId" equalTo:eventId];
            
            PFQuery *queryInvit = [PFQuery queryWithClassName:@"Invitation"];
            [queryInvit whereKey:@"event" matchesQuery:innerQueryEvent];
            [queryInvit includeKey:@"event"];
            queryInvit.cachePolicy  = kPFCachePolicyCacheElseNetwork;
            
            [queryInvit getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (error && error.code == kPFErrorObjectNotFound) {
                    completionHandler(UIBackgroundFetchResultFailed);
                }else if ([PFUser currentUser]) {
                    //Add a notif to the core data
                    /* NSDictionary *dictionnary;
                     if ([MOUtility getEventForObjectId:eventId]!=nil) {
                     dictionnary = @{@"invitation": [MOUtility saveInvitationWithEvent:object],
                     @"type" : @0,
                     @"message": [[userInfo valueForKey:@"aps"] valueForKey:@"alert"]};
                     }
                     else{
                     dictionnary = @{@"invitation": [MOUtility saveInvitationWithEvent:object],
                     @"type" : @0,
                     @"message": [[userInfo valueForKey:@"aps"] valueForKey:@"alert"]};
                     }
                     
                     
                     [MOUtility saveNotification:dictionnary];*/
                    
                    PhotosCollectionViewController *viewController = (PhotosCollectionViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotosCollectionEvent"];
                    viewController.invitation = object;
                    viewController.hidesBottomBarWhenPushed = YES;
                    
                    UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
                    UINavigationController *navController = (UINavigationController *)tabBar.selectedViewController;
                    [navController pushViewController:viewController animated:YES];
                    
                    completionHandler(UIBackgroundFetchResultNewData);
                } else {
                    completionHandler(UIBackgroundFetchResultNoData);
                }
                
            }];
        }
        else if([userInfo valueForKey:@"p"]!=nil){
            //New interaction on a photo
            NSString *photoId = [userInfo objectForKey:@"p"];
            
            PFQuery *queryPhoto = [PFQuery queryWithClassName:@"Photo"];
            [queryPhoto whereKey:@"objectId" equalTo:photoId];
            [queryPhoto includeKey:@"user"];
            [queryPhoto includeKey:@"prospect"];
            queryPhoto.cachePolicy  = kPFCachePolicyCacheElseNetwork;
            
            [queryPhoto getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (error && error.code == kPFErrorObjectNotFound) {
                    completionHandler(UIBackgroundFetchResultFailed);
                }else if ([PFUser currentUser]) {
                    /*NSDictionary *dictionnary = @{@"objectId": photoId,
                     @"type" : @1,
                     @"message": [[userInfo valueForKey:@"aps"] valueForKey:@"alert"]};
                     [MOUtility saveNotification:dictionnary];*/
                    
                    
                    PhotoDetailViewController *viewController = (PhotoDetailViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotoDetail"];
                    viewController.photo = object;
                    viewController.hidesBottomBarWhenPushed = YES;
                    
                    UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
                    UINavigationController *navController = (UINavigationController *)tabBar.selectedViewController;
                    [navController pushViewController:viewController animated:YES];
                    
                    completionHandler(UIBackgroundFetchResultNewData);
                } else {
                    completionHandler(UIBackgroundFetchResultNoData);
                }
                
            }];
        }
        else if([[userInfo valueForKey:@"type"] intValue]==0){
            if ([PFUser currentUser]) {
                UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
                [tabBar setSelectedIndex:1];
                
                completionHandler(UIBackgroundFetchResultNewData);
            }
            
        }
    }
    else if (application.applicationState == UIApplicationStateBackground){
        
        if ([userInfo valueForKey:@"e"]!=nil) {
            //New Photo in event
            NSString *eventId = [userInfo objectForKey:@"e"];
            
            PFQuery *innerQueryEvent = [PFQuery queryWithClassName:@"Event"];
            [innerQueryEvent whereKey:@"objectId" equalTo:eventId];
            
            PFQuery *queryInvit = [PFQuery queryWithClassName:@"Invitation"];
            [queryInvit whereKey:@"event" matchesQuery:innerQueryEvent];
            [queryInvit includeKey:@"event"];
            
            [queryInvit getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (error && error.code == kPFErrorObjectNotFound) {
                    completionHandler(UIBackgroundFetchResultFailed);
                }else if ([PFUser currentUser]) {
                    completionHandler(UIBackgroundFetchResultNewData);
                } else {
                    completionHandler(UIBackgroundFetchResultNoData);
                }
                
            }];
        }
        else if([userInfo valueForKey:@"p"]!=nil){
            //New interaction on a photo
            NSString *photoId = [userInfo objectForKey:@"p"];
            
            PFQuery *queryPhoto = [PFQuery queryWithClassName:@"Photo"];
            [queryPhoto whereKey:@"objectId" equalTo:photoId];
            [queryPhoto includeKey:@"user"];
            [queryPhoto includeKey:@"prospect"];
            
            [queryPhoto getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (error && error.code == kPFErrorObjectNotFound) {
                    completionHandler(UIBackgroundFetchResultFailed);
                }else if ([PFUser currentUser]) {
                    completionHandler(UIBackgroundFetchResultNewData);
                } else {
                    completionHandler(UIBackgroundFetchResultNoData);
                }
                
            }];
        }
        
        [PFPush handlePush:userInfo];
    }
    else{
        
        if ([userInfo valueForKey:@"e"]!=nil) {
            //New Photo in event
            NSString *eventId = [userInfo objectForKey:@"e"];
            
            PFQuery *innerQueryEvent = [PFQuery queryWithClassName:@"Event"];
            [innerQueryEvent whereKey:@"objectId" equalTo:eventId];
            
            PFQuery *queryInvit = [PFQuery queryWithClassName:@"Invitation"];
            [queryInvit whereKey:@"event" matchesQuery:innerQueryEvent];
            [queryInvit includeKey:@"event"];
            queryInvit.cachePolicy = kPFCachePolicyCacheElseNetwork;
            
            [queryInvit getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (error && error.code == kPFErrorObjectNotFound) {
                    completionHandler(UIBackgroundFetchResultFailed);
                }else if ([PFUser currentUser]) {
                    PhotosCollectionViewController *viewController = (PhotosCollectionViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotosCollectionEvent"];
                    viewController.invitation = object;
                    viewController.hidesBottomBarWhenPushed = YES;
                    
                    UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
                    UINavigationController *navController = (UINavigationController *)tabBar.selectedViewController;
                    [navController pushViewController:viewController animated:YES];
                    
                    completionHandler(UIBackgroundFetchResultNewData);
                } else {
                    completionHandler(UIBackgroundFetchResultNoData);
                }
                
            }];
        }
        else if([userInfo valueForKey:@"p"]!=nil){
            //New interaction on a photo
            NSString *photoId = [userInfo objectForKey:@"p"];
            
            PFQuery *queryPhoto = [PFQuery queryWithClassName:@"Photo"];
            [queryPhoto whereKey:@"objectId" equalTo:photoId];
            [queryPhoto includeKey:@"user"];
            [queryPhoto includeKey:@"prospect"];
            queryPhoto.cachePolicy = kPFCachePolicyCacheElseNetwork;
            
            [queryPhoto getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (error && error.code == kPFErrorObjectNotFound) {
                    completionHandler(UIBackgroundFetchResultFailed);
                }else if ([PFUser currentUser]) {
                    
                    PhotoDetailViewController *viewController = (PhotoDetailViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotoDetail"];
                    viewController.photo = object;
                    viewController.hidesBottomBarWhenPushed = YES;
                    
                    UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
                    UINavigationController *navController = (UINavigationController *)tabBar.selectedViewController;
                    [navController pushViewController:viewController animated:YES];
                    
                    completionHandler(UIBackgroundFetchResultNewData);
                } else {
                    completionHandler(UIBackgroundFetchResultNoData);
                }
                
            }];
        }
        else if([[userInfo valueForKey:@"type"] intValue]==0){
            if ([PFUser currentUser]) {
                UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
                [tabBar setSelectedIndex:1];
                
                completionHandler(UIBackgroundFetchResultNewData);
            }
            
        }
        
        [PFPush handlePush:userInfo];
    }
    
    
    
    //
    
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateActive) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rappel"
                                                        message:notification.alertBody
                                                       delegate:self cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else {
        NSString *objectIdInvit = notification.userInfo[@"invitationId"];
        
        PFQuery *queryInvit = [PFQuery queryWithClassName:@"Invitation"];
        [queryInvit whereKey:@"objectId" equalTo:objectIdInvit];
        [queryInvit includeKey:@"event"];
        queryInvit.cachePolicy = kPFCachePolicyCacheElseNetwork;
        
        [queryInvit getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (error && error.code == kPFErrorObjectNotFound) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem"
                                                                message:@"There was a problem accessing to this event."
                                                               delegate:self cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                
            }else if ([PFUser currentUser]) {
                PhotosCollectionViewController *viewController = (PhotosCollectionViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotosCollectionEvent"];
                viewController.invitation = object;
                viewController.hidesBottomBarWhenPushed = YES;
                
                UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
                UINavigationController *navController = (UINavigationController *)tabBar.selectedViewController;
                [navController pushViewController:viewController animated:YES];

            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem"
                                                                message:@"There was a problem accessing to this event."
                                                               delegate:self cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            
        }];
    }

}


-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    //[[Mixpanel sharedInstance] track:@"Background Fetch"];
    
    if ([PFUser currentUser]) {
        UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
        UINavigationController *navController = (UINavigationController *)[tabBar.viewControllers objectAtIndex:0];
        ListEvents *listEvents = (ListEvents *)[navController.viewControllers objectAtIndex:0];
        listEvents.completionHandler = completionHandler;
        listEvents.isBackgroundTask = YES;
        [listEvents fbReload:nil];
        
    }
    
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"FbEvents" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"FbEvents.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES
                              };
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end

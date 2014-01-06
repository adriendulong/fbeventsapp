//
//  ListEvents.h
//  TestParse
//
//  Created by Adrien Dulong on 25/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "LoginViewController.h"

@interface ListEvents : UITableViewController <SecondDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableEvents;
@property (nonatomic, strong) NSArray *invitations;
@property(nonatomic, assign) int facebookEventsNb;
@property(nonatomic, assign) int facebookEventNotReplied;
@property(nonatomic, assign) int facebookEventsNbDone;
@property(nonatomic, assign) int facebookEventNotRepliedDone;
@property(nonatomic, assign) bool comeFromLogin;
@property(nonatomic, assign) bool loadingNotJoinFBEvents;
@property (nonatomic, assign) BOOL animating;
@property (weak, nonatomic) IBOutlet UIImageView *refreshImage;
@property (strong, nonatomic) PFObject *closestInvitation;
@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
@property (copy) void (^completionHandler)(UIBackgroundFetchResult);
@property (assign, nonatomic) BOOL isBackgroundTask;

-(void)loadFutureEventsFromServer;
- (IBAction)fbReload:(id)sender;
-(void)retrieveEventsSince:(NSDate *)sinceDate to:(NSDate *)toDate isJoin:(BOOL)joined;

@end

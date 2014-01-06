//
//  TestParseAppDelegate.h
//  TestParse
//
//  Created by Adrien Dulong on 08/10/13.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Mixpanel/Mixpanel.h"

@interface TestParseAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) BOOL needToRefreshEvents;

@property (strong, nonatomic) UIStoryboard *storyboard;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) UIApplication *application;
@property (strong, nonatomic) NSDate *startTime;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

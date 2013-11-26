//
//  MemoriesController.h
//  TestParseAgain
//
//  Created by Adrien Dulong on 05/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface MemoriesController : UIViewController

@property (nonatomic, assign) int nbTotalEvents;

- (IBAction)getOldEvents:(id)sender;

@end

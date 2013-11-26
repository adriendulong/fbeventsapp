//
//  FirstLaunchViewController.h
//  TestParse
//
//  Created by Adrien Dulong on 12/10/13.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface FirstLaunchViewController : UIViewController
- (IBAction)facebook:(id)sender;
-(void)updateUserInfos;

@end

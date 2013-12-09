//
//  NotificationsViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 09/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *notifications;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)finish:(id)sender;
@end

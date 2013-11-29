//
//  MemoriesImportViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 27/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MemoriesImportViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (assign,nonatomic) int nbTotalEvents;
@property (strong, nonatomic) NSMutableArray *arrayEvents;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) PFObject *chosedEvent;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

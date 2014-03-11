//
//  MemoriesViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 23/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MemoriesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) NSMutableArray *memoriesInvitations;
@property (strong, nonatomic) NSMutableArray *photosEvent;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
@property (nonatomic, assign) BOOL hasPhotosToImport;
@property (nonatomic, assign) int nbPhotosToImport;

@end

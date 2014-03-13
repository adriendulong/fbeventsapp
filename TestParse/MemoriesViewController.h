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
@property (strong, nonatomic) NSMutableArray *allPastInvitations;
@property (strong, nonatomic) NSMutableArray *tableViewObjects;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
@property (nonatomic, assign) BOOL hasPhotosToImport;
@property (nonatomic, assign) NSInteger nbPhotosToImport;
@property (nonatomic, assign) NSInteger nbEventsToImportFrom;
@property (nonatomic, assign) NSInteger nbEventsWhichHavePhotos;
@property (strong, nonatomic) NSArray *previewPhotos;
@property (strong, nonatomic) NSMutableArray *imagesBackgroundEvents;
@property (strong, nonatomic) NSMutableArray *allPastEventsInfosPhotos;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;


- (IBAction)changeEventsPrinted:(id)sender;

@end

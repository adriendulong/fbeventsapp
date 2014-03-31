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
@property (strong, nonatomic) PFObject *chosenInvitation;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (assign, nonatomic) BOOL thereIsMore;
@property (strong, nonatomic) NSString *nextPage;
@property (weak, nonatomic) IBOutlet UILabel *kindEventsTitle;
@property (strong, nonatomic) NSArray *nbPhotosPerEvents;

- (IBAction)finish:(id)sender;
@end

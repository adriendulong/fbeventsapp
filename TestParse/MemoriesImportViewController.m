//
//  MemoriesImportViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 27/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "MemoriesImportViewController.h"
#import "MemoriesImportCell.h"
#import "MOUtility.h"
#import "ChooseLastEventViewController.h"
#import "PhotosImportedViewController.h"
#import "MBProgressHUD.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

@interface MemoriesImportViewController ()

@property (strong, nonatomic) MBProgressHUD *hud;

@end

@implementation MemoriesImportViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:@"Memories To Import View"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    self.kindEventsTitle.text = NSLocalizedString(@"MemoriesImportViewController_WhatEventKind", nil);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.thereIsMore = NO;
    
    self.title = NSLocalizedString(@"MemoriesImportViewController_Title", nil);
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.arrayEvents = [[NSMutableArray alloc] init];
    [self.activityIndicator startAnimating];
    [self.activityIndicator setHidden:NO];
    [self loadOldFacebookEvents:nil];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.thereIsMore) {
        return ([self.arrayEvents count]+1);
    }
    else{
        return self.arrayEvents.count;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    if (indexPath.row<self.arrayEvents.count) {
        
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.labelText = NSLocalizedString(@"MemoriesImportViewController_Loading", nil);
        
        NSDictionary *eventFacebook = [self.arrayEvents objectAtIndex:indexPath.row];
        
        __block PFObject *event;
        
        //This event is only on the server ?
        PFQuery*queryEvent = [PFQuery queryWithClassName:@"Event"];
        [queryEvent whereKey:@"eventId" equalTo:eventFacebook[@"id"]];
        [queryEvent getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            //Event already exists
            if (!error) {
                event = object;
                
                //See if an invitation exists
                PFQuery *queryInvit  = [PFQuery queryWithClassName:@"Invitation"];
                [queryInvit whereKey:@"user" equalTo:[PFUser currentUser]];
                [queryInvit whereKey:@"event" equalTo:event];
                [queryInvit getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    //There is an invitation
                    if (!error) {
                        if (![object[@"is_memory"] boolValue]) {
                            object[@"is_memory"] = @YES;
                            [object saveInBackground];
                        }
                        
                        //If end time but not have set type we do it now
                        if (event[@"end_time"] && !event[@"type"]) {
                            int type = [MOUtility typeEvent:event];
                            event[@"type"] = [NSNumber numberWithInt:type];
                            [event saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                
                                ////
                                // PERFORM SEGUE
                                ////
                                self.chosedEvent = event;
                                [[Mixpanel sharedInstance] track:@"Select Event Import" properties:@{@"has_end_time": @YES}];
                                [self performSegueWithIdentifier:@"DirectImport" sender:nil];
                                
                                
                            }];
                        }
                        else{
                            ////
                            // PERFORM SEGUE
                            ////
                            self.chosedEvent = event;
                            if (event[@"end_time"]) {
                                [[Mixpanel sharedInstance] track:@"Select Event Import" properties:@{@"has_end_time": @NO}];
                                [self performSegueWithIdentifier:@"DirectImport" sender:nil];
                                
                            }
                            else{
                                [[Mixpanel sharedInstance] track:@"Select Event Import" properties:@{@"has_end_time": @YES}];
                                [self performSegueWithIdentifier:@"TypeEvent" sender:nil];
                                
                            }
                        }
                    }
                    //No Invitation; create one
                    else{
                        PFObject *invitation = [MOUtility createInvitationFromFacebookDict:eventFacebook andEvent:event];
                        [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (succeeded) {
                                ////
                                // PERFORM SEGUE
                                ////
                                
                                //If end time but not have set type we do it now
                                if (event[@"end_time"] && !event[@"type"]) {
                                    int type = [MOUtility typeEvent:event];
                                    event[@"type"] = [NSNumber numberWithInt:type];
                                    [event saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                        
                                        ////
                                        // PERFORM SEGUE
                                        ////
                                        self.chosedEvent = event;
                                        [[Mixpanel sharedInstance] track:@"Select Event Import" properties:@{@"has_end_time": @YES}];
                                        [self performSegueWithIdentifier:@"DirectImport" sender:nil];
                                        
                                        
                                    }];
                                }
                                else{
                                    ////
                                    // PERFORM SEGUE
                                    ////
                                    self.chosedEvent = event;
                                    if (event[@"end_time"]) {
                                        [[Mixpanel sharedInstance] track:@"Select Event Import" properties:@{@"has_end_time": @YES}];
                                        [self performSegueWithIdentifier:@"DirectImport" sender:nil];
                                        
                                    }
                                    else{
                                        [[Mixpanel sharedInstance] track:@"Select Event Import" properties:@{@"has_end_time": @NO}];
                                        [self performSegueWithIdentifier:@"TypeEvent" sender:nil];
                                        
                                    }
                                }
                            }
                            else{
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem" message:@"Problème lors de l'importation de l'évènement, veuillez reessayer plus tard" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
                                [alert show];
                            }
                        }];
                    }
                }];
                
                
            }
            //NO event, must create it
            else if(error && error.code == kPFErrorObjectNotFound){
                PFObject *event = [MOUtility createEventFromFacebookDict:eventFacebook];
                [event saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        //Create invitation
                        PFObject *invitation = [MOUtility createInvitationFromFacebookDict:eventFacebook andEvent:event];
                        [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (succeeded) {
                                /////
                                // PERFORM SEGUE
                                /////
                                self.chosedEvent = event;
                                if (event[@"end_time"]) {
                                    [[Mixpanel sharedInstance] track:@"Select Event Import" properties:@{@"has_end_time": @YES}];
                                    [self performSegueWithIdentifier:@"DirectImport" sender:nil];
                                }
                                else{
                                    [[Mixpanel sharedInstance] track:@"Select Event Import" properties:@{@"has_end_time": @NO}];
                                    [self performSegueWithIdentifier:@"TypeEvent" sender:nil];
                                }
                            }
                            else{
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Problem_Title", nil) message:NSLocalizedString(@"UIAlertView_Problem_Message3", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Problem_Title", nil), nil];
                                [alert show];
                            }
                        }];
                    }
                    else{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Problem_Title", nil) message:NSLocalizedString(@"UIAlertView_Problem_Message3", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Problem_Title", nil), nil];
                        [alert show];
                    }
                }];
            
            
        }
        }];
    }
    
    //Load More
    else{
        [self loadOldFacebookEvents:self.nextPage];
        UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[[self.tableView cellForRowAtIndexPath:indexPath] viewWithTag:1];
        [activityIndicator startAnimating];
        [activityIndicator setHidden:NO];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row<self.arrayEvents.count) {
        static NSString *CellIdentifier = @"Cell";
        
        MemoriesImportCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[MemoriesImportCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            
        }
        
        NSDictionary *event = [self.arrayEvents objectAtIndex:indexPath.row];
        
        //Date
        NSDate *start_date = [MOUtility parseFacebookDate:event[@"start_time"] isDateOnly:[event[@"is_date_only"] boolValue]];
        //Formatter for the hour
        NSDateFormatter *formatterHourMinute = [NSDateFormatter new];
        [formatterHourMinute setDateFormat:@"HH:mm"];
        NSDateFormatter *formatterMonth = [NSDateFormatter new];
        [formatterMonth setDateFormat:@"MMM"];
        NSDateFormatter *formatterDay = [NSDateFormatter new];
        [formatterDay setDateFormat:@"d"];
        
        //Fill the cell
        cell.nameLabel.text = event[@"name"];
        cell.placeLabel.text = [NSString stringWithFormat:@"A %@", event[@"location"]];
        cell.monthLabel.text = [[NSString stringWithFormat:@"%@", [formatterMonth stringFromDate:start_date]] uppercaseString];
        cell.dayLabel.text = [NSString stringWithFormat:@"%@", [formatterDay stringFromDate:start_date]];
        cell.peopleLabel.text = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"MemoriesImportViewController_By", nil), event[@"owner"][@"name"]];
        
        return cell;
    }
    else{
        static NSString *CellIdentifier = @"CellLoadMore";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            
        }
        
        UILabel *label = (UILabel *)[cell viewWithTag:11];
        [label setText:NSLocalizedString(@"MemoriesImportViewController_LoadMore", nil)];
        
        
        UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:1];
        [activityIndicator stopAnimating];
        [activityIndicator setHidden:YES];
        
        return cell;
    }
    
}

-(void)loadOldFacebookEvents:(NSString *)requestFacebook{
    int startTimeInterval = (int)[[NSDate date] timeIntervalSince1970];
    NSString *stopDate = [NSString stringWithFormat:@"%i", startTimeInterval];
    
    //Request
    if (requestFacebook==nil) {
        requestFacebook = [NSString stringWithFormat:@"/me/events?fields=%@&until=%@&limit=20",FacebookEventsFields, stopDate];
    }
    FBRequest *request = [FBRequest requestForGraphPath:requestFacebook];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            //NSLog(@"%@", result);
            
            for(id event in result[@"data"]){
                [self.arrayEvents addObject:event];
                self.nbTotalEvents++;
            }
            
            if(result[@"paging"][@"next"]){
                self.thereIsMore = YES;
                NSURL *previous = [NSURL URLWithString:result[@"paging"][@"next"]];
                NSString *goodRequest = [NSString stringWithFormat:@"%@?%@", [previous path], [previous query]];
                self.nextPage = goodRequest;
                //[self loadOldFacebookEvents:goodRequest];
            }
            else{
                self.thereIsMore = NO;
                
            }
            
            [self.activityIndicator stopAnimating];
            [self.activityIndicator setHidden:YES];
            [self.tableView reloadData];
            
            
        }
        else{
            NSLog(@"%@", error);
        }
    }];
    
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [self.hud hide:YES];

    if ([segue.identifier isEqualToString:@"TypeEvent"]){
        ChooseLastEventViewController *chooseLastEvent = (ChooseLastEventViewController *)segue.destinationViewController;
        chooseLastEvent.event = self.chosedEvent;
        chooseLastEvent.levelRoot = 0;
    }
    else if([segue.identifier isEqualToString:@"DirectImport"]){
        PhotosImportedViewController *photosImported = (PhotosImportedViewController *)segue.destinationViewController;
        photosImported.event = self.chosedEvent;
        photosImported.levelRoot = 0;
    }
    
}

@end

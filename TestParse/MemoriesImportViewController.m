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
#import "FbEventsUtilities.h"
#import "Photo.h"

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 110;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return self.arrayEvents.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    if (indexPath.row<self.arrayEvents.count) {
        
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.labelText = NSLocalizedString(@"MemoriesImportViewController_Loading", nil);
        
        NSMutableDictionary *eventCustom = [[self.arrayEvents objectAtIndex:indexPath.row] mutableCopy];
        NSDictionary *eventFacebook = eventCustom[@"event"];

        
        [[FbEventsUtilities saveEventAsync:eventFacebook] continueWithBlock:^id(BFTask *task) {
            if (task.error) {
                NSLog(@"Error saveing/creatin event");
            }
            else{
                NSLog(@"Invitation : %@", task.result);
                self.chosenInvitation = task.result;
                [self performSegueWithIdentifier:@"DirectImport" sender:self];
            }
            
            [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
            
            return nil;
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
        static NSString *CellIdentifier = @"MemoriesCell";
        
        MemoriesImportCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[MemoriesImportCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            
        }
        
        NSMutableDictionary *eventCustom = [self.arrayEvents objectAtIndex:indexPath.row];
        NSDictionary *event = eventCustom[@"event"];
        
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
        cell.monthLabel.text = [[NSString stringWithFormat:@"%@", [formatterMonth stringFromDate:start_date]] uppercaseString];
        cell.dayLabel.text = [NSString stringWithFormat:@"%@", [formatterDay stringFromDate:start_date]];
        /*cell.peopleLabel.text = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"MemoriesImportViewController_By", nil), event[@"owner"][@"name"]];*/
        

        cell.nbPhotosFound.text = [NSString stringWithFormat:@"%i photos retrouvées", [eventCustom[@"nb_photos"] integerValue]] ;
        
        if ([eventCustom[@"photos"] count]>0) {
            UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
            imageView.image = ((Photo *)[eventCustom[@"photos"] objectAtIndex:0]).thumbnail;
        }
        
        if ([eventCustom[@"photos"] count]>1) {
            UIImageView *imageView = (UIImageView *)[cell viewWithTag:2];
            imageView.image = ((Photo *)[eventCustom[@"photos"] objectAtIndex:1]).thumbnail;
        }

        if ([eventCustom[@"photos"] count]>2) {
            UIImageView *imageView = (UIImageView *)[cell viewWithTag:3];
            imageView.image = ((Photo *)[eventCustom[@"photos"] objectAtIndex:2]).thumbnail;
        }
        
        if ([eventCustom[@"photos"] count]>3) {
            UIImageView *imageView = (UIImageView *)[cell viewWithTag:4];
            imageView.image = ((Photo *)[eventCustom[@"photos"] objectAtIndex:3]).thumbnail;
        }
        
        if ([eventCustom[@"photos"] count]>4) {
            UIImageView *imageView = (UIImageView *)[cell viewWithTag:5];
            imageView.image = ((Photo *)[eventCustom[@"photos"] objectAtIndex:4]).thumbnail;
        }
        
        if ([eventCustom[@"photos"] count]>5) {
            UIImageView *imageView = (UIImageView *)[cell viewWithTag:6];
            imageView.image = ((Photo *)[eventCustom[@"photos"] objectAtIndex:5]).thumbnail;
        }

        
        
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
        //requestFacebook = [NSString stringWithFormat:@"/me/events?fields=%@&until=%@&limit=20",FacebookEventsFields, stopDate];
        requestFacebook = [NSString stringWithFormat:@"/me/events?fields=%@&until=%@&limit=100",FacebookEventsFields, stopDate];
        NSLog(@"requestFacebook = %@", requestFacebook);
    }
    FBRequest *request = [FBRequest requestForGraphPath:requestFacebook];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            //NSLog(@"%@", result);
            
            NSArray *resultArray = result[@"data"];
            NSMutableArray *idsEvents = [[NSMutableArray alloc] init];
            
            
            for (int e=0; e < resultArray.count; e++) {
                
                NSDictionary *event = (NSDictionary *)resultArray[e];
                
                [idsEvents addObject:event[@"id"]];
                
                
                
                
                
                
            }
            
            [[self getFacebookIdOfEventAlreadyInvited:[idsEvents copy]] continueWithBlock:^id(BFTask *task) {
                if (task.error) {
                    NSLog(@"Error");
                    
                    for(NSDictionary *event in result[@"data"]){
                        NSDate *endTimeWoovent = (NSDate *)[MOUtility getEndDateWooventEvent:event];
                        NSDate *start_time = (NSDate *)[MOUtility parseFacebookDate:event[@"start_time"] isDateOnly:[event[@"is_date_only"] boolValue]];
                        
                        NSMutableDictionary *eventCustom = [[NSMutableDictionary alloc] init];
                        [eventCustom setObject:event forKey:@"event"];
                        [eventCustom setObject:endTimeWoovent forKey:@"end_time_woovent"];
                        [eventCustom setObject:start_time forKey:@"start_time"];
                        [eventCustom setObject:[NSNumber numberWithInt:0] forKey:@"nb_photos"];
                        [eventCustom setObject:[[NSMutableArray alloc] init] forKey:@"photos"];
                        
                        [self.arrayEvents addObject:eventCustom];
                    }
                    
                    [self getNbPhotosBetweenDate:self.arrayEvents withCallback:^(NSArray *events) {
                        
                        NSMutableArray *eventsWithPhotos = [[NSMutableArray alloc] init];
                        
                        for(NSMutableDictionary *event in events){
                            if ([event[@"nb_photos"] intValue]>0) {
                                [eventsWithPhotos addObject:event];
                            }
                        }
                        
                        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"nb_photos"  ascending:NO];
                        self.arrayEvents = [[eventsWithPhotos sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]] copy];
                        [self.activityIndicator stopAnimating];
                        [self.activityIndicator setHidden:YES];
                        [self.tableView reloadData];
                    }];
                    
                }
                else{
                    NSLog(@"Ids deja invités : %@", task.result);
                    NSArray *eventsToRemove = (NSArray *)task.result;
                    
                    for(NSDictionary *event in result[@"data"]){
                        if (![eventsToRemove containsObject:event[@"id"]]) {
                            NSDate *endTimeWoovent = (NSDate *)[MOUtility getEndDateWooventEvent:event];
                            NSDate *start_time = (NSDate *)[MOUtility parseFacebookDate:event[@"start_time"] isDateOnly:[event[@"is_date_only"] boolValue]];
                            
                            NSMutableDictionary *eventCustom = [[NSMutableDictionary alloc] init];
                            [eventCustom setObject:event forKey:@"event"];
                            [eventCustom setObject:endTimeWoovent forKey:@"end_time_woovent"];
                            [eventCustom setObject:start_time forKey:@"start_time"];
                            [eventCustom setObject:[NSNumber numberWithInt:0] forKey:@"nb_photos"];
                            [eventCustom setObject:[[NSMutableArray alloc] init] forKey:@"photos"];

                            [self.arrayEvents addObject:eventCustom];
                        }
                        
                    }
                    
                    [self getNbPhotosBetweenDate:self.arrayEvents withCallback:^(NSArray *events) {
                        NSMutableArray *eventsWithPhotos = [[NSMutableArray alloc] init];
                        
                        for(NSMutableDictionary *event in events){
                            if ([event[@"nb_photos"] intValue]>0) {
                                [eventsWithPhotos addObject:event];
                            }
                        }

                        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"nb_photos"  ascending:NO];
                        self.arrayEvents = [[eventsWithPhotos sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]] copy];
                        [self.activityIndicator stopAnimating];
                        [self.activityIndicator setHidden:YES];
                        [self.tableView reloadData];
                    }];
                }
                
                return nil;
            }];
            
            
            /*if(result[@"paging"][@"next"]){
                //NSLog(@"result[@\"paging\"][@\"next\"] = %@", result[@"paging"][@"next"]);
                self.thereIsMore = YES;
                NSURL *previous = [NSURL URLWithString:result[@"paging"][@"next"]];
                //NSLog(@"previous.path = %@ | previous.query = %@", previous.path, previous.query);
                NSString *goodRequest = [NSString stringWithFormat:@"%@?%@", previous.path, previous.query];
                //NSLog(@"goodRequest = %@", goodRequest);
                self.nextPage = goodRequest;
                //[self loadOldFacebookEvents:goodRequest];
            }
            else{
                self.thereIsMore = NO;
                
            }*/
            
            
            //[self.tableView reloadData];
            
            
        }
        else{
            NSLog(@"%@", error);
        }
    }];
    
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [self.hud hide:YES];

    /*if ([segue.identifier isEqualToString:@"TypeEvent"]){
        ChooseLastEventViewController *chooseLastEvent = (ChooseLastEventViewController *)segue.destinationViewController;
        chooseLastEvent.event = self.chosenInvitation;
        chooseLastEvent.levelRoot = 0;
    }*/
    if([segue.identifier isEqualToString:@"DirectImport"]){
        
        PhotosImportedViewController *photosImported = (PhotosImportedViewController *)segue.destinationViewController;
        photosImported.invitations = [NSMutableArray arrayWithObject:self.chosenInvitation];
        photosImported.levelRoot = 0;
    }
    
}


#pragma mark - Load photos

- (void)getNbPhotosBetweenDate:(NSArray *)events withCallback:(void (^)(NSArray *events))callback
{
    
    __block NSMutableArray *nbPhotosEvents = [[NSMutableArray alloc] init];
    
    for(NSDictionary *event in events){
        int nbPhotos = 0;
        [nbPhotosEvents addObject:[NSNumber numberWithInt:nbPhotos]];
    }
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        @autoreleasepool {
            if (group) {
                
                if ([[group valueForProperty:ALAssetsGroupPropertyType] compare:[NSNumber numberWithInt:ALAssetsGroupPhotoStream]]!=NSOrderedSame) {
                    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop2) {
                        if (result) {
                            
                            for(NSMutableDictionary *event in events){
                                int nbPhotos = [(NSNumber *)event[@"nb_photos"] intValue];
                                
                                NSDate *photoDate = (NSDate *)[result valueForProperty:ALAssetPropertyDate];
                                
                                if ([MOUtility date:photoDate isBetweenDate:(NSDate *)event[@"start_time"] andDate:(NSDate *)event[@"end_time_woovent"]]) {
                                    nbPhotos++;
                                    
                                    if (nbPhotos<7) {
                                        Photo *photo = [[Photo alloc] init];
                                        photo.thumbnail = [UIImage imageWithCGImage:result.thumbnail];
                                        [event[@"photos"] addObject:photo];
                                    }

                                }
                                
                                
                                [event setObject:[NSNumber numberWithInt:nbPhotos] forKey:@"nb_photos"];
                            }
                        }
                    }];
                    
                    if (stop) {
                        callback(events);
                    }
                    
                }
                
            }
        }
        
    } failureBlock:^(NSError *error) {
        NSLog(@"Failed.");
    }];
}


-(BFTask *)getFacebookIdOfEventAlreadyInvited:(NSArray *)idsFacebookEvent{
     BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    NSMutableArray *idsFacebookEventAlreadyInvited = [[NSMutableArray alloc] init];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Event"];
    [query whereKey:@"eventId" containedIn:idsFacebookEvent];
    [query whereKey:@"nb_photos" greaterThan:[NSNumber numberWithInt:0]];
    
    PFQuery *queryInvitation = [PFQuery queryWithClassName:@"Invitation"];
    [queryInvitation whereKey:@"user" equalTo:[PFUser currentUser]];
    [queryInvitation whereKey:@"event" matchesQuery:query];
    [queryInvitation includeKey:@"event"];
    
    [queryInvitation findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for(PFObject *invitation in objects){
                PFObject *event = invitation[@"event"];
                [idsFacebookEventAlreadyInvited addObject:event[@"eventId"]];
            }
            
            [task setResult:[idsFacebookEventAlreadyInvited copy]];
        }
        else{
            [task setError:error];
        }
    }];
    
    
    return task.task;
}

- (IBAction)finish:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

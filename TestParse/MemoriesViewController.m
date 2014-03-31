//
//  MemoriesViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 23/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "MemoriesViewController.h"
#import "PhotosCollectionViewController.h"
#import "MemorieCell.h"
#import "FirstMemorieCell.h"
#import "MemoriesImportViewController.h"
#import "NSMutableArray+Reverse.h"
#import "MOUtility.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "MBProgressHUD.h"
#import "Photo.h"
#import "PastEventsCell.h"
#import "PhotosImportedViewController.h"

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )
#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)

@interface MemoriesViewController ()

@end

@implementation MemoriesViewController{
    UIImageView *navBarHairlineImageView;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UploadPhotoFinished object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    navBarHairlineImageView.hidden = NO;
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //self.hasPhotosToImport = NO;
    
    PFUser *user = [PFUser currentUser];
    [user refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        NSLog(@"User last upload : %@", user[@"last_upload"]);
        if ([self.allPastInvitations count]>0) {
            [self getPhotosToUpload];
        }
        
    }];
    
    /*if ([self.memoriesInvitations count]>0) {
        [MOUtility programNotifForEvent:[self.memoriesInvitations objectAtIndex:0][@"event"]];
    }*/
    
    navBarHairlineImageView.hidden = YES;
    [[Mixpanel sharedInstance] track:@"Memories View Loaded"];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:@"Memories View"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.hasPhotosToImport = NO;
    
    //Init object table view
    self.memoriesInvitations = [[NSMutableArray alloc] init];
    self.allPastInvitations = [[NSMutableArray alloc] init];
    self.allPastEventsInfosPhotos = [[NSMutableArray alloc] init];
    self.tableViewObjects = self.memoriesInvitations;
    
    self.title = NSLocalizedString(@"UITabBar_Title_ThirdPosition", nil);
    //[self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:(253/255.0) green:(160/255.0) blue:(20/255.0) alpha:1]];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [UIColor whiteColor],NSForegroundColorAttributeName,
                                    [UIColor whiteColor],NSBackgroundColorAttributeName,
                                    [MOUtility getFontWithSize:20.0] , NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    navBarHairlineImageView = [self findHairlineImageViewUnder:self.navigationController.navigationBar];
    
    UIColor *greyColor = [UIColor colorWithRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1];
    [self.tableView setBackgroundColor:greyColor];
    
    //Top icon
    self.topImageView.layer.cornerRadius = 16.0f;
    self.topImageView.layer.masksToBounds = YES;
    
    self.memoriesInvitations = [[NSMutableArray alloc] init];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPhotosAfterUpload:) name:UploadPhotoFinished object:nil];
    
    [self loadMemoriesFromSeverWithPhotosBeforeDate:nil];

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
    if (self.hasPhotosToImport) {
        return [self.tableViewObjects count]+1;
    }
    else{
        return [self.tableViewObjects count];
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.hasPhotosToImport) {
        if (indexPath.row == 0) {
            return 100;
        }
        else{
            if([self.segmentControl selectedSegmentIndex]==0){
                return 173;
            }
            else{
                return 90;
            }
            
        }
    }
    else{
        if([self.segmentControl selectedSegmentIndex]==0){
            return 173;
        }
        else{
            return 90;
        }
    }
    
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    

    static NSString *CellIdentifier = @"Cell";
    static NSString *FirstCellIdentifier = @"FirstCell";
    NSInteger indexPosition = indexPath.row;
    
    if (self.hasPhotosToImport) {
        indexPosition = indexPath.row - 1;
        
        if (indexPath.row == 0) {
            FirstMemorieCell *cell = [tableView dequeueReusableCellWithIdentifier:FirstCellIdentifier forIndexPath:indexPath];
            
            //if (cell == nil) {
              //  cell = [[FirstMemorieCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            //}
            
            [[cell viewWithTag:1] setBackgroundColor:[MOUtility colorWithHexString:@"00a0dc"]];
            
            //Labels
            cell.infosPhotosFound.text = [NSString stringWithFormat:@"Des photos ont été retrouvé pour %i évènements", self.nbEventsWhichHavePhotos];
            [cell.buttonImport setTitle:@"Importer ces photos" forState:UIControlStateNormal];

            
            cell.nbPhotosFound.text = [NSString stringWithFormat:@"%li", (long)self.nbPhotosToImport];
            
            UIView *viewImage = (UIView *)[cell viewWithTag:2];
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(27, 19, 63, 63)];
            imgView.image = ((Photo *)self.previewPhotos[0]).thumbnail;
            
            [viewImage addSubview:imgView];
            imgView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-12));
            
            if ([self.previewPhotos count]>1) {
                UIView *viewImageTwo = (UIView *)[cell viewWithTag:3];
                UIImageView *imgViewTwo = [[UIImageView alloc] initWithFrame:CGRectMake(27, 19, 63, 63)];
                imgViewTwo.image = ((Photo *)self.previewPhotos[1]).thumbnail;
                
                [viewImageTwo addSubview:imgViewTwo];
                imgViewTwo.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(10));
            }
            
            
            
            
            return cell;
        }
    }
    
    //Get the event object.
    PFObject *event = [self.tableViewObjects objectAtIndex:indexPosition][@"event"];
    
    if ([self.segmentControl selectedSegmentIndex]==0) {
        MemorieCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[MemorieCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        //[self getNbPhotosAtIndex:indexPath forCell:cell];
        
        
        
        //Date
        NSDate *start_date = event[@"start_time"];
        //Formatter for the hour
        NSDateFormatter *formatterHourMinute = [NSDateFormatter new];
        [formatterHourMinute setDateFormat:@"HH:mm"];
        [formatterHourMinute setLocale:[NSLocale currentLocale]];
        NSDateFormatter *formatterMonth = [NSDateFormatter new];
        [formatterMonth setDateFormat:@"MMM"];
        [formatterHourMinute setLocale:[NSLocale currentLocale]];
        NSDateFormatter *formatterDay = [NSDateFormatter new];
        [formatterDay setDateFormat:@"d"];
        [formatterDay setLocale:[NSLocale currentLocale]];
        
        
        //Fill the cell
        cell.nameEventLabel.text = event[@"name"];
        //Comments
        if (event[@"nb_comments"]) {
            cell.nbCommentsLabel.text = [NSString stringWithFormat:@"%@", event[@"nb_comments"]];
        }
        else{
            cell.nbCommentsLabel.text = @"0";
        }
        
        //Likes
        if (event[@"nb_likes"]) {
            cell.nbLikesLabel.text = [NSString stringWithFormat:@"%@", event[@"nb_likes"]];
        }
        else{
            cell.nbLikesLabel.text = @"0";
        }
        
        //Photos
        //Likes
        if (event[@"nb_photos"]) {
            cell.nbPhotosLabel.text = [NSString stringWithFormat:@"%@", event[@"nb_photos"]];
        }
        else{
            cell.nbPhotosLabel.text = @"0";
        }
        
        if ([self.segmentControl selectedSegmentIndex]==0) {
            if (![[self.imagesBackgroundEvents objectAtIndex:indexPosition] isKindOfClass:[NSNull class]]) {
                cell.backgroundImage.image = [UIImage imageNamed:@"default_cover"];
                cell.backgroundImage.file = [self.imagesBackgroundEvents objectAtIndex:indexPosition];
                [cell.backgroundImage loadInBackground];
            }
            else{
                cell.backgroundImage.image = [UIImage imageNamed:@"default_cover"];
            }
            
            //Get and set the most likes photos as cover photo
            [[self setMostLikePhoto:event] continueWithBlock:^id(BFTask *task) {
                if (task.error) {
                    NSLog(@"Error while loading the photos of event : %@", event[@"name"]);
                }
                else{
                    //cell.backgroundImage.image = [UIImage imageNamed:@"default_cover"];
                    
                    if (task.result != nil) {
                        if (task.result[0][@"full_image"]!=nil) {
                            [self.imagesBackgroundEvents replaceObjectAtIndex:indexPosition withObject:task.result[0][@"full_image"]];
                            cell.backgroundImage.file = task.result[0][@"full_image"]; // remote image
                            
                            [cell.backgroundImage loadInBackground];
                        }
                    }
                    
                }
                
                return nil;
            }];
        }
        
        
        return cell;
    }
    else{
        PastEventsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PastCell" forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[PastEventsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.nameEventLabel.text = event[@"name"];
        
        
        //Date manips
        NSDate *start_date = event[@"start_time"];
        NSDateFormatter *formatterMonth = [NSDateFormatter new];
        [formatterMonth setDateFormat:@"MMM"];
        NSDateFormatter *formatterDay = [NSDateFormatter new];
        [formatterDay setDateFormat:@"d"];
        [formatterDay setLocale:[NSLocale currentLocale]];
        
        cell.monthLabel.text = [[NSString stringWithFormat:@"%@", [formatterMonth stringFromDate:start_date]] uppercaseString];
        cell.dayDateLabel.text = [NSString stringWithFormat:@"%@", [formatterDay stringFromDate:start_date]];
        
        if ([self.allPastEventsInfosPhotos count]>indexPosition) {
            if ([self.allPastEventsInfosPhotos[indexPosition][@"nb_photos"] intValue]>0) {
                [[cell viewWithTag:1] setHidden:NO];
                cell.previewPhoto.image = ((Photo *)[self.allPastEventsInfosPhotos[indexPosition][@"photos"] objectAtIndex:0]).thumbnail;
                cell.nbPhotosLabel.text = [NSString stringWithFormat:@"%@", self.allPastEventsInfosPhotos[indexPosition][@"nb_photos"]];
            }
            else{
                [[cell viewWithTag:1] setHidden:YES];
            }
        }
        else{
            [[cell viewWithTag:1] setHidden:YES];
        }
        

        return cell;
    }
    
    

    
    
    
    
    
    
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}



#pragma mark - Parse Events

-(void)loadMemoriesFromSeverWithPhotosBeforeDate:(NSDate *)date{
    //From local database
    //self.memoriesInvitations = [[MOUtility getPastMemories] mutableCopy];
    //[self isEmptyTableView];
    //[self.tableView reloadData];

    if (date==nil) {
        [self.memoriesInvitations removeAllObjects];
        [self.allPastInvitations removeAllObjects];
        date = [NSDate date];
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"start_time" lessThan:date];
    [query whereKey:@"rsvp_status" notContainedIn:@[FacebookEventNotReplied, FacebookEventDeclined]];
    [query includeKey:@"event"];
    [query orderByDescending:@"start_time"];
    query.limit = 100;

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            NSMutableArray *allEvents = [[NSMutableArray alloc] init];
            
            //On verifie cb de Memories on a
            for(PFObject *invitation in objects){
                PFObject *event = invitation[@"event"];
                if ([(NSNumber *)event[@"nb_photos"] intValue]>0) {
                    [self.memoriesInvitations addObject:invitation];
                }
                [self.allPastInvitations addObject:invitation];
                [allEvents addObject:invitation];
            }
            
            //Do we have to paginate
            if (([objects count]==100)&&([self.memoriesInvitations count]<20)) {
                NSLog(@"Paginate to get more");
            }
            
            //Cache image
            self.imagesBackgroundEvents = [[NSMutableArray alloc] initWithCapacity:[self.memoriesInvitations count]];
            for(PFObject *invitation in objects){
                [self.imagesBackgroundEvents addObject:[NSNull null]];
            }
            
            
            if ([self.segmentControl selectedSegmentIndex]==0) {
                self.tableViewObjects = self.memoriesInvitations;
            }
            else{
                self.tableViewObjects = self.allPastInvitations;
            }
            
            
            
            [self isEmptyTableView];
            [self.tableView reloadData];
            
            [self getPhotosToUpload];
            

            //Get number of photos for all events
            [[MOUtility getNumberOfPhotosToImport:nil forInvitations:[allEvents copy]] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                NSLog(@"On main thread : %d",[NSThread isMainThread] ? 1:0);
                if (task.error) {
                    NSLog(@"Error");
                }
                else{
                    NSMutableArray *insertIndexPaths = [[NSMutableArray alloc] init];
                    
                    int i=0;
                    if (self.hasPhotosToImport) {
                        i++;
                    }
                    
                    for(NSMutableDictionary *dicInfos in (NSMutableArray *)task.result){
                        NSDictionary *infosPhotos = @{@"nb_photos": dicInfos[@"nb_photos"], @"photos" : dicInfos[@"photos"]};
                        [self.allPastEventsInfosPhotos addObject:infosPhotos];
                        
                        if ([infosPhotos[@"nb_photos"] intValue]>0) {
                            [insertIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                        }
                    }
                    
                    if ([self.segmentControl selectedSegmentIndex]==1) {
                        [self.tableView reloadRowsAtIndexPaths:[insertIndexPaths copy] withRowAnimation:UITableViewRowAnimationNone];
                    }
                    
                }
                
                return nil;
            }];
            
            [[Mixpanel sharedInstance].people set:@{@"Memories": [NSNumber numberWithInteger:self.memoriesInvitations.count]}];
            
            /*
            for(PFObject *invitation in objects){
                [MOUtility saveInvitationWithEvent:invitation];
            }*/

            
        } else {
            // Log details of the failure
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            NSLog(@"Problème de chargement");
        }
    }];
}


-(void)loadRealMemoriesBeforeDate:(NSDate *)date afterNbInvitations:(NSInteger)nbInvitationsToSkip{
    
}

#pragma mark - Load Photos


-(void)loadPhotosAfterUpload:(NSNotification *)note{
    [self loadMemoriesFromSeverWithPhotosBeforeDate:nil];
}


#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"DetailEvent"]) {
        [[Mixpanel sharedInstance] track:@"Detail Event" properties:@{@"From": @"Memories View"}];
        
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        //Selected row
        NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
        
        NSInteger position;
        if (self.hasPhotosToImport) {
            position = selectedRowIndex.row -1;
        }
        else{
            position = selectedRowIndex.row;
        }
        
        PhotosCollectionViewController *photosCollectionViewController = segue.destinationViewController;
        if([self.segmentControl selectedSegmentIndex]==0){
            photosCollectionViewController.invitation = [self.memoriesInvitations objectAtIndex:position];
        }
        else{
            photosCollectionViewController.invitation = [self.allPastInvitations objectAtIndex:position];
        }
        
        photosCollectionViewController.hidesBottomBarWhenPushed = YES;
    }
    else if ([segue.identifier isEqualToString:@"ImportEmpty"]) {
        [[Mixpanel sharedInstance] track:@"Click Import" properties:@{@"From": @"Empty"}];
    }
    else if ([segue.identifier isEqualToString:@"ImportTopBar"]) {
        
        [[Mixpanel sharedInstance] track:@"Click Import" properties:@{@"From": @"Top bar"}];
    }
    else if([segue.identifier isEqualToString:@"DirectImport"]){
        
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        PhotosImportedViewController *photosImported = (PhotosImportedViewController *)[navController.viewControllers objectAtIndex:0];
        photosImported.invitations = [self.invitationsToImport mutableCopy];
        photosImported.levelRoot = 0;
        
        photosImported.hidesBottomBarWhenPushed = YES;
    }

}


-(void)createMemorie{
    
    
    [self performSegueWithIdentifier:@"ImportEmpty" sender:nil];
}

-(void)isEmptyTableView{
    UIView *viewBack = [[UIView alloc] initWithFrame:self.view.frame];
    [viewBack setUserInteractionEnabled:NO];
    
    UIImage *image = [UIImage imageNamed:@"broken_heart"];
    UIImageView *imageView = [[UIImageView alloc] init];
    
    //Arrow
    UIImage *imageArrow = [UIImage imageNamed:@"arrowWoovent"];
    UIImageView *imageViewArrow = [[UIImageView alloc] init];
    
    //Label
    UILabel *label = [[UILabel alloc] init];
    UILabel *labelArrow = [[UILabel alloc] init];
    
    
    imageViewArrow.frame = CGRectMake(235, 75, 60, 34);
    labelArrow.frame = CGRectMake(20, 95, 240, 25);
    //Image
    if (IS_IPHONE_5) {
        imageView.frame = CGRectMake(109, 200, 102, 90);
        label.frame = CGRectMake(20, 330, 280, 60);
    }
    else{
        imageView.frame = CGRectMake(109, 200, 102, 90);
        label.frame = CGRectMake(20, 310, 280, 60);
    }
    
    
    
    [imageView setImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    
    [imageViewArrow setImage:imageArrow];
    imageViewArrow.contentMode = UIViewContentModeCenter;
    
    [label setTextColor:[UIColor darkGrayColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setNumberOfLines:1];
    [label setFont:[MOUtility getFontWithSize:18.0]];
    label.text = NSLocalizedString(@"MemoriesViewController_Empty", nil);
    
    [labelArrow setTextColor:[UIColor orangeColor]];
    [labelArrow setTextAlignment:NSTextAlignmentLeft];
    [labelArrow setNumberOfLines:1];
    [labelArrow setFont:[MOUtility getFontWithSize:14.0]];
    labelArrow.text = NSLocalizedString(@"MemoriesViewController_EmptyLabelClick", nil);
    
    [viewBack addSubview:imageView];
    [viewBack addSubview:imageViewArrow];
    [viewBack addSubview:label];
    [viewBack addSubview:labelArrow];

    
    if (!self.tableViewObjects) {
        self.tableView.backgroundView = viewBack;
        
    }
    else if(self.tableViewObjects.count==0){
        
        self.tableView.backgroundView = viewBack;
    }
    else{
        self.tableView.backgroundView = nil;
    }
}

- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}


//Nombre de photos à uploader en attente
-(void)getPhotosToUpload{
    NSDate *last_upload = (NSDate *)[PFUser currentUser][@"last_upload"];
    NSMutableArray *invitationsToCheck = [[NSMutableArray alloc] init];
    
    for(PFObject *invitation in self.allPastInvitations){
        NSDate *start_date = (NSDate *)invitation[@"event"][@"start_time"];
        
        //If start time event after last upload
        if (last_upload) {
            if ([last_upload compare:start_date]==NSOrderedAscending) {
                [invitationsToCheck addObject:invitation];
            }
        }
        else{
            [invitationsToCheck addObject:invitation];
        }
        
    }
    
    ALAuthorizationStatus autho =  [ALAssetsLibrary authorizationStatus];
    NSLog(@"Authorisation : %ld", autho);
    
    self.nbEventsToImportFrom = [invitationsToCheck count];
    
    if (self.nbEventsToImportFrom >0) {
        [[MOUtility getNumberOfPhotosToImport:last_upload forInvitations:[invitationsToCheck copy]] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            if (task.error) {
                NSLog(@"Error");
                if (self.hasPhotosToImport) {
                    self.hasPhotosToImport = NO;
                    
                    [UIView beginAnimations:@"myAnimationId" context:nil];
                    
                    [UIView setAnimationDuration:1.0]; // Set duration here
                    
                    [CATransaction begin];
                    [CATransaction setCompletionBlock:^{
                        NSLog(@"Complete!");
                    }];
                    
                    [self.tableView beginUpdates];
                    // my table changes
                    NSArray *insertIndexPaths = [NSArray arrayWithObjects:
                                                 [NSIndexPath indexPathForRow:0 inSection:0],
                                                 nil];
                    [self.tableView deleteRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
                    [self.tableView endUpdates];
                    
                    [CATransaction commit];
                    [UIView commitAnimations];
                }
            }
            else{
                if ([self decryptTotalNbPhotos:task.result]>0) {
                    //NSLog(@"Nombre de photos %@", task.result[@"nb_photos"]);
                    if ((self.hasPhotosToImport)) {
                        self.nbEventsWhichHavePhotos = [self realNumberOfEventsWhichHavePhotos:task.result];
                        self.hasPhotosToImport = YES;
                        self.nbPhotosToImport = [self decryptTotalNbPhotos:task.result];
                        self.previewPhotos = [self getTwoPreviewPhotos:task.result];
                        self.invitationsToImport = [self getInvitationsWhichHaveToImport:task.result];
                        
                        NSArray *insertIndexPaths = [NSArray arrayWithObjects:
                                                     [NSIndexPath indexPathForRow:0 inSection:0],
                                                     nil];
                        
                        [self.tableView reloadRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationNone];
                        
                        
                    }
                    else {
                        self.nbEventsWhichHavePhotos = [self realNumberOfEventsWhichHavePhotos:task.result];
                        self.hasPhotosToImport = YES;
                        self.nbPhotosToImport = [self decryptTotalNbPhotos:task.result];
                        self.previewPhotos = [self getTwoPreviewPhotos:task.result];
                        self.invitationsToImport = [self getInvitationsWhichHaveToImport:task.result];
                        [UIView beginAnimations:@"myAnimationId" context:nil];
                        
                        [UIView setAnimationDuration:1.5]; // Set duration here
                        
                        [CATransaction begin];
                        [CATransaction setCompletionBlock:^{
                            NSLog(@"Complete!");
                        }];
                        
                        [self.tableView beginUpdates];
                        // my table changes
                        NSArray *insertIndexPaths = [NSArray arrayWithObjects:
                                                     [NSIndexPath indexPathForRow:0 inSection:0],
                                                     nil];
                        [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
                        [self.tableView endUpdates];
                        
                        [CATransaction commit];
                        [UIView commitAnimations];
                    }
                    
                }
                
            }
            
            return nil;
        }];
    }
    else{
        self.hasPhotosToImport = NO;
    }
    
    
}

-(NSInteger)realNumberOfEventsWhichHavePhotos:(NSMutableArray *)eventsInfos{
    NSInteger nbEvents = 0;
    
    for(NSMutableDictionary *eventInfo in eventsInfos){
        if ([(NSNumber *)eventInfo[@"nb_photos"] integerValue]>0) {
            nbEvents++;
        }
    }
    
    return nbEvents;
}

-(NSInteger)decryptTotalNbPhotos:(NSMutableArray *)eventsInfos{
    NSInteger nbPhotos = 0;
    
    for(NSMutableDictionary *eventInfo in eventsInfos){
        nbPhotos = nbPhotos + [(NSNumber *)eventInfo[@"nb_photos"] integerValue];
    }
    
    return nbPhotos;
}

-(NSArray *)getInvitationsWhichHaveToImport:(NSMutableArray *)eventsInfos{
    NSMutableArray *invitationsToImport = [[NSMutableArray alloc] init];
    
    for(NSMutableDictionary *eventInfo in eventsInfos){
        if ([(NSNumber *)eventInfo[@"nb_photos"] integerValue]>0) {
            [invitationsToImport addObject:eventInfo[@"invitation"]];
        } 
    }
    
    return [invitationsToImport copy];
}

-(NSArray *)getTwoPreviewPhotos:(NSMutableArray *)eventsInfos{
    NSMutableArray *photosPreview = [[NSMutableArray alloc] init];
    NSInteger nbPhotos = 0;
    
    for(NSMutableDictionary *eventInfo in eventsInfos){
        NSMutableArray *photos = eventInfo[@"photos"];
        nbPhotos = nbPhotos + [photos count];
        
        for(Photo *photo in photos){
            [photosPreview addObject:photo];
        }
        
        if (nbPhotos>2) {
            break;
        }
    }
    
    return [photosPreview mutableCopy];
    
}

-(BFTask *)setMostLikePhoto:(PFObject *)event{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    
    PFQuery *queryPhotos = [PFQuery queryWithClassName:@"Photo"];
    [queryPhotos whereKey:@"event" equalTo:event];
    [queryPhotos orderByDescending:@"nb_likes"];
    queryPhotos.limit = 1;
    queryPhotos.cachePolicy = kPFCachePolicyNetworkElseCache;

    
    [queryPhotos findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [task setResult:objects];
        }
        else{
            [task setError:error];
        }
    }];
    
    
    return task.task;
}


/*
 User selects which events he wants to see
 */

- (IBAction)changeEventsPrinted:(id)sender {
    if ([self.segmentControl selectedSegmentIndex]==0) {
        self.tableViewObjects = self.memoriesInvitations;
    }
    else{
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
        self.tableViewObjects = self.allPastInvitations;
    }
    
    [self isEmptyTableView];
    [self.tableView reloadData];
    
}

- (IBAction)importAction:(id)sender {
    
    [self performSegueWithIdentifier:@"DirectImport" sender:nil];
}

@end

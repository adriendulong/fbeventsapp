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

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

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
    
    PFUser *user = [PFUser currentUser];
    [user refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        NSLog(@"User last upload : %@", user[@"last_upload"]);
        
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
    
    
    [self loadMemoriesFromSever];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    return [self.memoriesInvitations count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    return 173;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    

    static NSString *CellIdentifier = @"Cell";
    
    int indexPosition = indexPath.row;
    
    MemorieCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[MemorieCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    //[self getNbPhotosAtIndex:indexPath forCell:cell];
    
    //Get the event object.
    PFObject *event = [self.memoriesInvitations objectAtIndex:indexPosition][@"event"];
    
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
        cell.nbCommentsLabel.text = event[@"nb_comments"];
    }
    else{
        cell.nbCommentsLabel.text = @"0";
    }
    
    //Likes
    if (event[@"nb_likes"]) {
        cell.nbLikesLabel.text = event[@"nb_likes"];
    }
    else{
        cell.nbLikesLabel.text = @"0";
    }
    
    //Photos
    //Likes
    if (event[@"nb_photos"]) {
        cell.nbPhotosLabel.text = event[@"nb_photos"];
    }
    else{
        cell.nbPhotosLabel.text = @"0";
    }

    
    return cell;
    
    
    
    
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        PFObject *invitation = [self.memoriesInvitations objectAtIndex:(indexPath.row)];
        invitation[@"is_memory"] = @NO;
        [invitation saveEventually];
        
        [self.memoriesInvitations removeObjectAtIndex:(indexPath.row)];
        [self.photosEvent removeObjectAtIndex:(indexPath.row)];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        //Remove from database
        [MOUtility deleteInvitation:invitation.objectId];
        
        [self isEmptyTableView];
        
        
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


#pragma mark - Parse Events

-(void)loadMemoriesFromSever{
    //From local database
    self.memoriesInvitations = [[MOUtility getPastMemories] mutableCopy];
    [self isEmptyTableView];
    [self.tableView reloadData];

    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"start_time" lessThan:[NSDate date]];
    [query whereKey:@"rsvp_status" notContainedIn:@[FacebookEventNotReplied, FacebookEventDeclined]];
    [query whereKey:@"is_memory" notEqualTo:@NO];
    [query includeKey:@"event"];
    [query orderByDescending:@"start_time"];
    
    //Cache then network
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        if (!error) {
            
            self.memoriesInvitations = [objects mutableCopy];
            
            for(PFObject *invitation in objects){
                [MOUtility saveInvitationWithEvent:invitation];
            }
            
            [self getPhotosToUpload];
            
            /*self.photosEvent = [[NSMutableArray alloc] init];
            int i=0;
            for(PFObject *memorieInvit in self.memoriesInvitations){
                NSMutableArray *mutableArrayTemp = [[NSMutableArray alloc] init];
                [self.photosEvent addObject:mutableArrayTemp];
                [self loadPhotosOfEvent:memorieInvit[@"event"] atPosition:i];
                i++;
            }*/
            
            [[Mixpanel sharedInstance].people set:@{@"Memories": [NSNumber numberWithInt:self.memoriesInvitations.count]}];
            
            [self isEmptyTableView];
            [self.tableView reloadData];
        } else {
            // Log details of the failure
            
            NSLog(@"Problème de chargement");
        }
    }];
}

#pragma mark - Load Photos

-(void)loadPhotosOfEvent: (PFObject *)event atPosition:(int)position{
    PFQuery *queryPhotos = [PFQuery queryWithClassName:@"Photo"];
    [queryPhotos whereKey:@"event" equalTo:event];
    [queryPhotos orderByDescending:@"createdAt"];
    queryPhotos.limit = 9;
    queryPhotos.cachePolicy = kPFCachePolicyCacheThenNetwork;

    
    [queryPhotos findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (position<[self.photosEvent count]) {
                [self.photosEvent replaceObjectAtIndex:position withObject:objects];
                
                
                NSArray *visible = [self.tableView indexPathsForVisibleRows];
                for(NSIndexPath *indexPath in visible){
                    if (position == indexPath.row) {
                        [self isEmptyTableView];
                        [self.tableView reloadData];
                    }
                }
            }
            
        }
    }];
}

-(void)loadPhotosAfterUpload:(NSNotification *)note{
    [self loadMemoriesFromSever];
}


#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"DetailEvent"]) {
        [[Mixpanel sharedInstance] track:@"Detail Event" properties:@{@"From": @"Memories View"}];
        
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        //Selected row
        NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
        
        
        PhotosCollectionViewController *photosCollectionViewController = segue.destinationViewController;
        photosCollectionViewController.invitation = [self.memoriesInvitations objectAtIndex:selectedRowIndex.row];
        photosCollectionViewController.hidesBottomBarWhenPushed = YES;
    }
    else if ([segue.identifier isEqualToString:@"ImportEmpty"]) {
        [[Mixpanel sharedInstance] track:@"Click Import" properties:@{@"From": @"Empty"}];
    }
    else if ([segue.identifier isEqualToString:@"ImportTopBar"]) {
        
        [[Mixpanel sharedInstance] track:@"Click Import" properties:@{@"From": @"Top bar"}];
    }

}

-(void)getNbPhotosAtIndex:(NSIndexPath *)index forCell:(MemorieCell *)cell{
    PFObject *event = [self.memoriesInvitations objectAtIndex:index.row][@"event"];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Photo"];
    query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    [query whereKey:@"event" equalTo:event];
    [query countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (!error) {
            cell.nbPhotosLabel.text = [NSString stringWithFormat:NSLocalizedString(@"MemoriesViewController_NbRefoundPhotos", nil), count];
        } else {
            // The request failed
        }
    }];
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

    
    if (!self.memoriesInvitations) {
        self.tableView.backgroundView = viewBack;
        
    }
    else if(self.memoriesInvitations.count==0){
        
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

-(void)getPhotosToUpload{
    NSDate *last_upload = (NSDate *)[PFUser currentUser][@"last_upload"];
    NSMutableArray *eventsToCheck = [[NSMutableArray alloc] init];
    
    for(PFObject *invitation in self.memoriesInvitations){
        NSDate *start_date = (NSDate *)invitation[@"event"][@"start_time"];
        
        //If start time event after last upload
        if ([last_upload compare:start_date]==NSOrderedAscending) {
            NSLog(@"Ajout de l'évènement %@ à checker", invitation[@"event"][@"name"]);
            [eventsToCheck addObject:invitation[@"event"]];
        }
    }
    
    ALAuthorizationStatus autho =  [ALAssetsLibrary authorizationStatus];
    NSLog(@"Authorisation : %d", autho);
    
    [[MOUtility getNumberOfPhotosToImport:last_upload forEvents:[eventsToCheck copy]] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            NSLog(@"Error");
            
        }
        else{
            NSLog(@"Nombre de photos %@", task.result[@"nb_photos"]);
        }
        
        return nil;
    }];
}

-(BFTask *)setMostLikePhoto:(PFObject *)event{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    
    PFQuery *queryPhotos = [PFQuery queryWithClassName:@"Photo"];
    [queryPhotos whereKey:@"event" equalTo:event];
    [queryPhotos orderByDescending:@"createdAt"];
    queryPhotos.limit = 1;
    queryPhotos.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    
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

@end

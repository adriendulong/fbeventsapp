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
    [self.activityIndicator startAnimating];
    [self.activityIndicator setHidden:NO];
    [self loadMemoriesFromSever];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPhotosAfterUpload:) name:UploadPhotoFinished object:nil];
    

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

    return 195;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    

    static NSString *CellIdentifier = @"Cell";
    
    int indexPosition = indexPath.row;
    
    MemorieCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[MemorieCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [self getNbPhotosAtIndex:indexPath forCell:cell];
    
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
    cell.nameLabel.text = event[@"name"];
    cell.placeLabel.text = [NSString stringWithFormat:@"%@", event[@"location"]];
    cell.monthLabel.text = [[NSString stringWithFormat:@"%@", [formatterMonth stringFromDate:start_date]] uppercaseString];
    cell.dayLabel.text = [NSString stringWithFormat:@"%@", [formatterDay stringFromDate:start_date]];
    
    if (self.photosEvent.count >indexPosition) {
        if ([[self.photosEvent objectAtIndex:indexPosition] count]>0) {
            NSMutableArray *arrayPhotos = [[NSMutableArray alloc] init];
            
            for(PFObject *photo in [self.photosEvent objectAtIndex:indexPosition]){
                NSDictionary *dict = @{@"type": @0,
                                       @"photo": photo};
                [arrayPhotos addObject:dict];
                
            }
            
            [cell.coverImage setHidden:YES];
            
            if (arrayPhotos.count < 9) {
                int diff = 9 - arrayPhotos.count;
                UIImage *image = [[UIImage alloc] init];
                for(int i=0;i<diff;i++){
                    if ((i%4)==0) {
                        image = [UIImage imageNamed:@"img1"];
                    }
                    else if((i%4)==1){
                        image = [UIImage imageNamed:@"img2"];
                    }
                    else if((i%4)==2){
                        image = [UIImage imageNamed:@"img3"];
                    }
                    else if((i%4)==3){
                        image = [UIImage imageNamed:@"img4"];
                    }
                    NSDictionary *dict = @{@"type": @1,
                                           @"image": image};
                    [arrayPhotos addObject:dict];
                }
                
                
                //[arrayPhotos shuffle];
            }
            
            for (int i=0; i<9; i++) {
                PFImageView *imageView = (PFImageView *)[cell viewWithTag:i+1];
                
                if (i<[arrayPhotos count]) {
                    
                    
                    [imageView setHidden:NO];
                    if ([arrayPhotos objectAtIndex:i][@"photo"]) {
                        PFObject *photo =[arrayPhotos objectAtIndex:i][@"photo"];
                        if (photo[@"facebookId"]) {
                            [imageView setImageWithURL:photo[@"facebook_url_low"] placeholderImage:[UIImage imageNamed:@"default_cover"]];
                        }
                        else{
                            imageView.image = [UIImage imageNamed:@"default_cover"]; // placeholder image
                            imageView.file = (PFFile *)photo[@"low_image"]; // remote image
                            
                            [imageView loadInBackground];
                        }
                    }
                    else{
                        imageView.image = (UIImage *)[arrayPhotos objectAtIndex:i][@"image"];
                    }
                    
                }
                else{
                    [imageView setHidden:YES];
                }
            }
        }
        else{
            [cell.coverImage setHidden:NO];
            [cell.coverImage setImageWithURL:[NSURL URLWithString:event[@"cover"]]
                            placeholderImage:[UIImage imageNamed:@"default_cover"]];
        }
    }
    
    
    return cell;
    
    /*if (indexPath.row==0) {
        static NSString *CellIdentifier = @"FirstCell";
     
        FirstMemorieCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
     
        if (cell == nil) {
            cell = [[FirstMemorieCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
     
        UIButton *buttonImport = (UIButton *)[cell viewWithTag:100];
        [buttonImport setTitle:NSLocalizedString(@"MemoriesViewController_AutoImportButton", nil) forState:UIControlStateNormal];
        
        return cell;
    }
    else{
        
    }*/
    
    
    
    
    
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
    /*self.photosEvent = [[NSMutableArray alloc] init];
    int i=0;
    for(PFObject *memorieInvit in self.memoriesInvitations){
        NSMutableArray *mutableArrayTemp = [[NSMutableArray alloc] init];
        [self.photosEvent addObject:mutableArrayTemp];
        [self loadPhotosOfEvent:memorieInvit[@"event"] atPosition:i];
        i++;
    }*/
    
    
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
        if (!error) {
            if (self.activityIndicator.isAnimating) {
                [self.activityIndicator stopAnimating];
                [self.activityIndicator setHidden:YES];
            }
            
            self.memoriesInvitations = [objects mutableCopy];
            
            for(PFObject *invitation in objects){
                [MOUtility saveInvitationWithEvent:invitation];
            }
            
            self.photosEvent = [[NSMutableArray alloc] init];
            
            int i=0;
            for(PFObject *memorieInvit in self.memoriesInvitations){
                NSMutableArray *mutableArrayTemp = [[NSMutableArray alloc] init];
                [self.photosEvent addObject:mutableArrayTemp];
                [self loadPhotosOfEvent:memorieInvit[@"event"] atPosition:i];
                i++;
            }
            
            [[Mixpanel sharedInstance].people set:@{@"Memories": [NSNumber numberWithInt:self.memoriesInvitations.count]}];
            
            [self isEmptyTableView];
            [self.tableView reloadData];
        } else {
            // Log details of the failure
            if (self.activityIndicator.isAnimating) {
                [self.activityIndicator stopAnimating];
                [self.activityIndicator setHidden:YES];
            }
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
            [self.photosEvent replaceObjectAtIndex:position withObject:objects];
            
            
            NSArray *visible = [self.tableView indexPathsForVisibleRows];
            for(NSIndexPath *indexPath in visible){
                if (position == indexPath.row) {
                    [self isEmptyTableView];
                    [self.tableView reloadData];
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
    
    //Label
    UILabel *label = [[UILabel alloc] init];
    
    //Button
    UIButton *buttonMemories = [UIButton buttonWithType:UIButtonTypeCustom];
    
    
    //Image
    if (IS_IPHONE_5) {
        imageView.frame = CGRectMake(109, 170, 102, 90);
        label.frame = CGRectMake(20, 300, 280, 60);
        buttonMemories.frame = CGRectMake(20, 450, 280, 40);
    }
    else{
        imageView.frame = CGRectMake(109, 170, 102, 90);
        label.frame = CGRectMake(20, 280, 280, 60);
        buttonMemories.frame = CGRectMake(20, 350, 280, 40);
    }
    
    
    
    [imageView setImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    
    [label setTextColor:[UIColor darkGrayColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setNumberOfLines:1];
    [label setFont:[MOUtility getFontWithSize:18.0]];
    label.text = NSLocalizedString(@"MemoriesViewController_Empty", nil);
    
    
    [buttonMemories setTitle:NSLocalizedString(@"MemoriesViewController_AutoImportButton", nil) forState:UIControlStateNormal];
    [buttonMemories addTarget:self action:@selector(createMemorie) forControlEvents:UIControlEventTouchUpInside];
    [buttonMemories setEnabled:YES];
    
    [buttonMemories setBackgroundImage:[UIImage imageNamed:@"import_auto_infos"] forState:UIControlStateNormal];
    
    [viewBack addSubview:imageView];
    [viewBack addSubview:label];
    [viewBack addSubview:buttonMemories];
    
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

@end

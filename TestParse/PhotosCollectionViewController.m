//
//  PhotosCollectionViewController.m
//  TestParseAgain
//
//  Created by Adrien Dulong on 08/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "PhotosCollectionViewController.h"
#import "MOUtility.h"
#import "EventUtilities.h"
#import "FbEventsUtilities.h"
#import "CameraViewController.h"
#import "PhotoDetailViewController.h"
#import "ChooseLastEventViewController.h"
#import "DetailDescriptionViewController.h"
#import "MapViewController.h"
#import "InvitedListViewController.h"

@interface PhotosCollectionViewController ()

@end

@implementation PhotosCollectionViewController
@synthesize photos;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ShowOrHideDetailsEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AddPhotoToEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UpdateInvitedFinished object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UploadPhotoFinished object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Notification to hide details about the event
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideDetails:) name:ShowOrHideDetailsEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addPhoto:) name:AddPhotoToEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(greatMomentToUpdateInvited:) name:UpdateInvitedFinished object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPhotosAfterUpload:) name:UploadPhotoFinished object:nil];
    
    //Do we sho details about the event
    self.isShowingDetails = YES;
    
    //Appearance
    self.navigationController.navigationBar.tintColor = [UIColor orangeColor];
    //[self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor orangeColor]}];
    
    //Page Title
    PFObject *event = self.invitation[@"event"];
    NSTimeInterval distanceBetweenDates = [event[@"start_time"] timeIntervalSinceDate:[NSDate date]];
    double secondsInAnDays = 86400;
    NSInteger daysBetweenDates = distanceBetweenDates / secondsInAnDays;
    self.title = [NSString stringWithFormat:@"dans %i jours", daysBetweenDates];
    
    //Init images
    //self.photos = [NSArray arrayWithObjects:@"horloge", @"covertest", @"covertest", nil];
    NSDate *startDate = self.invitation[@"event"][@"start_time"];
    if ([startDate compare:[NSDate date]]==NSOrderedAscending) {
        self.isDuringOrAfter = YES;
    }
    else{
        self.isDuringOrAfter = NO;
        self.isShowingDetails = YES;
    }
    
    
    
    
    //Update view
    [self getInvitedFromServer];
    [self updateEventFromFB];
    [self loadPhotos];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Collection View Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [photos count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    //UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:100];
    //recipeImageView.image = [UIImage imageNamed:@"covertest"];
    
    PFImageView *imageView = (PFImageView *)[cell viewWithTag:100];
    
    if ([photos objectAtIndex:indexPath.row][@"facebookId"]) {
        [imageView setImageWithURL:[photos objectAtIndex:indexPath.row][@"facebook_url_low"] placeholderImage:[UIImage imageNamed:@"covertestinfos.png"]];
    }
    else{
        imageView.image = [UIImage imageNamed:@"covertest"]; // placeholder image
        imageView.file = (PFFile *)[photos objectAtIndex:indexPath.row][@"low_image"]; // remote image
        
        [imageView loadInBackground];
    }
    
    
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        self.headerIndexPath = indexPath;
        
        InfoHeaderCollectionView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        headerView.isShowingDetails = YES;
        UIView *toHideView = [headerView viewWithTag:1000];
        
        //Add Google Maps
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.86
                                                                longitude:151.20
                                                                     zoom:6];
        
        //When click on map
        UITapGestureRecognizer *singleFingerTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(touchedMap:)];
        
        headerView.mapView_ = [GMSMapView mapWithFrame:CGRectMake(0, 275, self.view.bounds.size.width, 149) camera:camera];
        [headerView.mapView_ addGestureRecognizer:singleFingerTap];
        headerView.mapView_.myLocationEnabled = YES;
        headerView.mapView_.settings.scrollGestures = NO;
        headerView.mapView_.settings.zoomGestures = NO;
        headerView.mapView_.settings.tiltGestures = NO;
        headerView.mapView_.settings.rotateGestures = NO;
        [toHideView addSubview:headerView.mapView_];
        
        // Creates a marker in the center of the map.
        GMSMarker *marker = [[GMSMarker alloc] init];
        marker.position = CLLocationCoordinate2DMake(-33.86, 151.20);
        marker.title = @"Sydney";
        marker.snippet = @"Australia";
        marker.map = headerView.mapView_;
        
        PFObject *event = self.invitation[@"event"];
        
        headerView.invitation = self.invitation;
        headerView.nameEvent.text = event[@"name"];
        headerView.ownerEvent.text = [NSString stringWithFormat:@"Evènement organisé par %@", event[@"owner"][@"name"]];
        headerView.eventDescription.text = event[@"description"];
        [headerView.coverImage setImageWithURL:event[@"cover"] placeholderImage:[UIImage imageNamed:@"covertestinfos.png"]];
        headerView.locationLabel.text = event[@"location"];
        
        if ([self.invitation[@"rsvp_status"] isEqualToString:FacebookEventAttending]) {
            [headerView.segmentRsvp setSelectedSegmentIndex:0];
        }
        else if ([self.invitation[@"rsvp_status"] isEqualToString:FacebookEventMaybe]){
            [headerView.segmentRsvp setSelectedSegmentIndex:1];
        }
        else if([self.invitation[@"rsvp_status"] isEqualToString:FacebookEventDeclined]){
            [headerView.segmentRsvp setSelectedSegmentIndex:2];
        }
        
        //Date
        NSString *dateFormat;
        NSString *dateComponents = @"EEEEdMMMM";
        NSLocale *prefredLocale = [NSLocale currentLocale];
        dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:prefredLocale];
        NSDateFormatter *dformat = [[NSDateFormatter alloc]init];
        [dformat setDateFormat:dateFormat];
        headerView.dateEvent.text = [NSString stringWithFormat:@"%@", [dformat stringFromDate:event[@"start_time"]]];
        
        if (!self.isDuringOrAfter) {
            [headerView.automaticImport setHidden:YES];
            headerView.constraintButtonPhoto.constant = 35.0f;
            headerView.constraintViewNbPhotos.constant = 0.0f;
            //headerView.separateConstraint.constant = 20.0f;
        }
        else{
            headerView.constraintViewNbPhotos.constant = 0.0f;
        }
        
        //Add button
        //Add import automatic button
        /*UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self
                   action:nil
         forControlEvents:UIControlEventTouchDown];
        [button setBackgroundImage:[UIImage imageNamed:@"btn_automatic_import"] forState:UIControlStateNormal];
        button.frame = CGRectMake(6.0, 760.0, 305.0, 41.0);
        [headerView addSubview:button];
        [headerView addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[headerView]-60-[button]"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:NSDictionaryOfVariableBindings(button, headerView)]];*/
        
        
        
        
        self.headerCollectionView = headerView;
        reusableview = headerView;
    }

    return reusableview;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    
    if (section==0) {
        if (self.isDuringOrAfter) {
            if (self.isShowingDetails) {
                return CGSizeMake(800, 920);
            }
            else{
                return CGSizeMake(800, 368);
            }
        }
        else{
            if (self.isShowingDetails) {
                return CGSizeMake(800, 880);
            }
            else{
                return CGSizeMake(800, 306);
            }
        }
        

    }
    else{
        return CGSizeZero;
    }
    
}

#pragma mark - Photo

-(void)loadPhotos{
    PFQuery *queryPhotos = [PFQuery queryWithClassName:@"Photo"];
    [queryPhotos whereKey:@"event" equalTo:self.invitation[@"event"]];
    [queryPhotos includeKey:@"user"];
    [queryPhotos includeKey:@"prospect"];
    queryPhotos.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [queryPhotos findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            photos = [NSArray arrayWithArray:objects];
            [self.collectionView reloadData];
            //[self.collectionViewLayout invalidateLayout];
        }
    }];
}

-(void)loadPhotosAfterUpload:(NSNotification *)note{
    PFQuery *queryPhotos = [PFQuery queryWithClassName:@"Photo"];
    [queryPhotos whereKey:@"event" equalTo:self.invitation[@"event"]];
    [queryPhotos includeKey:@"user"];
    [queryPhotos includeKey:@"prospect"];
    [queryPhotos findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            photos = [NSArray arrayWithArray:objects];
            [self.collectionView reloadData];
            //[self.collectionViewLayout invalidateLayout];
        }
    }];
}




#pragma mark - Facebook Event

//Update the informations about the event from FB
-(void)updateEventFromFB{
    
    NSString *requestString = [NSString stringWithFormat:@"%@?fields=owner.fields(id,name,picture),name,location,start_time,end_time,cover,updated_time,description,is_date_only,admins.fields(id,name,picture),invited.user(%@)", self.invitation[@"event"][@"eventId"], [PFUser currentUser][@"facebookId"]];
    FBRequest *request = [FBRequest requestForGraphPath:requestString];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            [self updateEvent:result compareTo:self.invitation];
            
            //Get all the invited
            [self getGuestsFromFacebookEvent:self.invitation[@"event"][@"eventId"]];
        }
        else{
            NSLog(@"%@", error);
        }
    }];
    
}

-(void)updateEvent:(NSDictionary *)event compareTo:(PFObject *)eventToCompare{
    NSNull *null = [NSNull null];
    
    //If the update date is superior to the update date of the saved object
    NSDate *updated_time = [MOUtility parseFacebookDate:event[@"updated_time"]  isDateOnly:NO];
    if([updated_time compare:eventToCompare.updatedAt] == NSOrderedDescending){
        if(event[@"name"]){
            eventToCompare[@"name"] = event[@"name"];
        }
        
        //LOCATION
        if(event[@"location"]){
            eventToCompare[@"location"] = event[@"location"];
        }
        else{
            if(eventToCompare[@"location"]){
                eventToCompare[@"location"] = null;
            }
        }
        
        
        //START TIME
        if(event[@"start_time"]){
            NSDate *startDate = [MOUtility parseFacebookDate:event[@"start_time"]  isDateOnly:[event[@"is_date_only"] boolValue]];
            eventToCompare[@"start_time"] = startDate;
        }
        else{
            if(eventToCompare[@"start_time"]){
                eventToCompare[@"start_time"] = null;
            }
        }
        
        //END TIME
        if(event[@"end_time"]){
            NSDate *endDate = [MOUtility parseFacebookDate:event[@"end_time"]  isDateOnly:[event[@"is_date_only"] boolValue]];
            eventToCompare[@"end_time"] = endDate;
        }
        else{
            if(eventToCompare[@"end_time"]){
                eventToCompare[@"end_time"] = null;
            }
        }
        
        //DESCRIPTION
        if(event[@"description"]){
            eventToCompare[@"description"] = event[@"description"];
        }
        else{
            if (eventToCompare[@"description"]) {
                eventToCompare[@"description"] = null;
            }
        }
        
        //COVER
        if(event[@"cover"]){
            eventToCompare[@"cover"] = event[@"cover"][@"source"];
        }
        else{
            if (eventToCompare[@"cover"]) {
                eventToCompare[@"cover"] = null;
            }
        }
        
        //OWNER
        if(event[@"owner"]){
            eventToCompare[@"owner"] = event[@"owner"];
        }
        
        //ADMINS
        if(event[@"admins"]){
            eventToCompare[@"admins"] = event[@"admins"][@"data"];
        }
        
        [eventToCompare saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            self.invitation[@"event"] = eventToCompare;
            //Update the view
            [self updateView];
            
            //Update the invitation
            NSString *rsvp = [event[@"invited"][@"data"] objectAtIndex:0][@"rsvp_status"];
            [self updateInviteUser:[PFUser currentUser] toEvent:eventToCompare withRsvp:rsvp];
            
        }];
    }
    else{
        //Update the invitation
        NSString *rsvp = [event[@"invited"][@"data"] objectAtIndex:0][@"rsvp_status"];
        [self updateInviteUser:[PFUser currentUser] toEvent:eventToCompare withRsvp:rsvp];
    }
    
}

//Update invitation of the user if needed
-(void)updateInviteUser:(PFUser *)user toEvent:(PFObject *)event withRsvp:(NSString *)rsvp{
    BOOL needToUpdate = NO;
    
    if(![self.invitation[@"rsvp_status"] isEqualToString:rsvp]){
        self.invitation[@"rsvp_status"] = rsvp;
        needToUpdate = YES;
    }
    
    
    if([EventUtilities isOwnerOfEvent:event forUser:user])
    {
        if(!self.invitation[@"isOwner"]){
            self.invitation[@"isOwner"] = @YES;
            needToUpdate = YES;
        }
        
    }
    
    if ([EventUtilities isAdminOfEvent:event forUser:user]) {
        if (!self.invitation[@"isAdmin"]) {
            self.invitation[@"isAdmin"] = @YES;
            needToUpdate = YES;
        }
    }
    if (![self.invitation[@"start_time"] isEqualToDate:event[@"start_time"]]) {
        needToUpdate = YES;
        self.invitation[@"start_time"] = event[@"start_time"];
    }
    
    if(needToUpdate){
        [self.invitation saveInBackground];
        //Update the interface
        [self updateView];
    }
    
}



#pragma mark - Invited

-(void)getInvitedFromServer{
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"event" equalTo:self.invitation[@"event"]];
    [query includeKey:@"user"];
    [query includeKey:@"prospect"];
    
    //Cache then network
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"LOADED INVITED");
            self.invited = objects;
            [self updateGuestsView];
        } else {
            // Log details of the failure
            NSLog(@"Problème de chargement");
        }
    }];
    
}


-(void)getGuestsFromFacebookEvent:(NSString *)facebookId{
    NSString *requestString = [NSString stringWithFormat:@"%@?fields=invited.limit(50)", self.invitation[@"event"][@"eventId"]];
    FBRequest *request = [FBRequest requestForGraphPath:requestString];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            //Get all the invited
            NSLog(@"%@", result);
            NSArray *guests = result[@"invited"][@"data"];
            
            self.guestViewUpdated = NO;
            self.nbInvitedToAdd = guests.count;
            self.nbInvitedAlreadyAdded = 0;
            
            for (id guest in guests) {
                NSLog(@"name : %@", guest[@"name"]);
                [self addOrUpdateInvited:guest];
            }
            
        }
        else{
            NSLog(@"%@", error);
        }
    }];
}

-(void)addOrUpdateInvited:(NSDictionary *)invited{
    PFObject *guest;
    PFObject *invitation;
    
    //We see if there is an invitation ofr this user
    for(id invit in self.invited){
        PFObject *tempGuests = [FbEventsUtilities getProspectOrUserFromInvitation:invit];
        if ([tempGuests[@"facebookId"] isEqualToString:invited[@"id"]]) {
            guest = tempGuests;
            invitation = invit;
        }
    }
    
    //We already have an invitation and a guest we just update the invitation
    if (guest) {
        //Update guest or user
        if (![guest[@"name"] isEqualToString:invited[@"name"]]) {
            guest[@"name"] = invited[@"name"];
            [guest saveEventually];
        }
        
        //Update invitation
        if (![invitation[@"rsvp_status"] isEqualToString:invited[@"rsvp_status"]]) {
            invitation[@"rsvp_status"] = invited[@"rsvp_status"];
            [invitation saveEventually];
        }
        
        //We have finished with this user
        [[NSNotificationCenter defaultCenter] postNotificationName:UpdateInvitedFinished object:self userInfo:nil];
    }
    
    //The invitation does not exist
    else{
        //See if a user or a prospect exist
        PFQuery *query = [PFUser query];
        [query whereKey:@"facebookId" equalTo:invited[@"id"]];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!object) {
                ///////
                // PROSPECT EXISTS ??
                //////
                PFQuery *queryProspect = [PFQuery queryWithClassName:@"Prospect"];
                [queryProspect whereKey:@"facebookId" equalTo:invited[@"id"]];
                [queryProspect getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    
                    //If there is no prospect
                    if (!object) {
                        //We create a prospect
                        PFObject *prospectObject = [PFObject objectWithClassName:@"Prospect"];
                        prospectObject[@"facebookId"] = invited[@"id"];
                        prospectObject[@"name"] = invited[@"name"];
                        [prospectObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            //And create invitation
                            [self createInvitation:invited[@"rsvp_status"] forUser:nil forProspect:prospectObject];
                        }];
                    }
                    //A prospect already exist, add invitation
                    else{
                        [self createInvitation:invited[@"rsvp_status"] forUser:nil forProspect:object];
                    }
                }];
            }
            else{
                [self createInvitation:invited[@"rsvp_status"] forUser:(PFUser *)object forProspect:nil];
            }
        }];
        
    }
    
}


-(void)createInvitation:(NSString *)rsvp forUser:(PFUser *)user forProspect:(PFObject *)prospect{
    PFObject *invitation = [PFObject objectWithClassName:@"Invitation"];
    [invitation setObject:self.invitation[@"event"] forKey:@"event"];
    
    invitation[@"isOwner"] = @NO;
    invitation[@"isAdmin"] = @NO;
    
    if (user) {
        [invitation setObject:user forKey:@"user"];
        if([EventUtilities isOwnerOfEvent:self.invitation[@"event"] forUser:user])
        {
            NSLog(@"You are the owner !!");
            invitation[@"isOwner"] = @YES;
        }
        
        if ([EventUtilities isAdminOfEvent:self.invitation[@"event"] forUser:user]) {
            invitation[@"isAdmin"] = @YES;
        }
    }
    else{
        [invitation setObject:prospect forKey:@"prospect"];
        if([EventUtilities isOwnerOfEvent:self.invitation[@"event"] forUser:prospect])
        {
            NSLog(@"You are the owner !!");
            invitation[@"isOwner"] = @YES;
        }
        
        if ([EventUtilities isAdminOfEvent:self.invitation[@"event"] forUser:prospect]) {
            invitation[@"isAdmin"] = @YES;
        }
    }
    
    invitation[@"rsvp_status"] = rsvp;
    invitation[@"start_time"] = self.invitation[@"event"][@"start_time"];
    
    [invitation saveInBackground];
    [[NSNotificationCenter defaultCenter] postNotificationName:UpdateInvitedFinished object:self userInfo:nil];
}



#pragma mark - Interface

-(void)addPhoto:(NSNotification *)note{
    NSLog(@"ADD PHOTO");
}

-(void)hideDetails:(NSNotification *)note{
    if (self.isShowingDetails) {
        [self.headerCollectionView.viewToHide setHidden:YES];
    }
    else{
        [self.headerCollectionView.viewToHide setHidden:NO];
    }
    
    self.isShowingDetails = !self.isShowingDetails;
    [self.collectionViewLayout invalidateLayout];
}

-(void)greatMomentToUpdateInvited:(NSNotification *)note{
    self.nbInvitedAlreadyAdded++;
    
    if (!self.guestViewUpdated) {
        if (self.nbInvitedAlreadyAdded==self.nbInvitedToAdd) {
            [self getInvitedFromServer];
            self.guestViewUpdated = YES;
        }
        else if (self.nbInvitedAlreadyAdded ==5){
            [self getInvitedFromServer];
            self.guestViewUpdated = YES;
        }
    }
    
    
}

-(void)updateView{
    
    PFObject *event = self.invitation[@"event"];
    
    //Title page
    NSTimeInterval distanceBetweenDates = [event[@"start_time"] timeIntervalSinceDate:[NSDate date]];
    double secondsInAnDays = 86400;
    NSInteger daysBetweenDates = distanceBetweenDates / secondsInAnDays;
    self.title = [NSString stringWithFormat:@"dans %i jours", daysBetweenDates];
    
    
    self.headerCollectionView.invitation = self.invitation;
    self.headerCollectionView.nameEvent.text = event[@"name"];
    self.headerCollectionView.ownerEvent.text = [NSString stringWithFormat:@"Evènement organisé par %@", event[@"owner"][@"name"]];
    self.headerCollectionView.eventDescription.text = event[@"description"];
    [self.headerCollectionView.coverImage setImageWithURL:event[@"cover"] placeholderImage:[UIImage imageNamed:@"covertestinfos.png"]];
    
    if ([self.invitation[@"rsvp_status"] isEqualToString:FacebookEventAttending]) {
        [self.headerCollectionView.segmentRsvp setSelectedSegmentIndex:0];
    }
    else if ([self.invitation[@"rsvp_status"] isEqualToString:FacebookEventMaybe]){
        [self.headerCollectionView.segmentRsvp setSelectedSegmentIndex:1];
    }
    else if([self.invitation[@"rsvp_status"] isEqualToString:FacebookEventDeclined]){
        [self.headerCollectionView.segmentRsvp setSelectedSegmentIndex:2];
    }
    
    //Date
    NSString *dateFormat;
    NSString *dateComponents = @"EEEEdMMMM";
    NSLocale *prefredLocale = [NSLocale currentLocale];
    dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:prefredLocale];
    NSDateFormatter *dformat = [[NSDateFormatter alloc]init];
    [dformat setDateFormat:dateFormat];
    self.headerCollectionView.dateEvent.text = [NSString stringWithFormat:@"%@", [dformat stringFromDate:event[@"start_time"]]];
    
    //self.locationLabel.text = event[@"location"];
}

-(void)updateGuestsView{
    NSLog(@"Update Guest View");
    
    //Update Guests
    for (NSInteger i=1; i<6; i++) {
        if (i<=[self.invited count]) {
            PFObject *invitation = [self.invited objectAtIndex:i-1];
            PFObject *guest;
            if (invitation[@"user"]) {
                guest = invitation[@"user"];
            }
            else{
                guest = invitation[@"prospect"];
            }
            
            UIView *guestView = [self.headerCollectionView.viewToHide viewWithTag:i];
            [guestView setHidden:NO];
            UIImageView *photo = (UIImageView *)[guestView viewWithTag:6];
            [photo setImageWithURL:[MOUtility UrlOfFacebooProfileImage:guest[@"facebookId"]]
                  placeholderImage:[UIImage imageNamed:@"covertest.png"]];
            photo.layer.cornerRadius = 23.0f;
            photo.layer.masksToBounds = YES;
        }
        else{
            UIView *guestView = [self.headerCollectionView.viewToHide viewWithTag:i];
            [guestView setHidden:YES];
        }
        
        
        
        //UIImageView *indicator = (UIImageView *)[guestView viewWithTag:2];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"AddPhoto"]) {
        
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        CameraViewController *cameraViewController = [navController.viewControllers objectAtIndex:0];
        cameraViewController.event = self.invitation[@"event"];
    }
    else if ([segue.identifier isEqualToString:@"ShowDetailPhoto"]){
        
        NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
        NSIndexPath *indexPath = [indexPaths objectAtIndex:0];

        PhotoDetailViewController *photoDetailController = (PhotoDetailViewController *)segue.destinationViewController;
        photoDetailController.photo = [self.photos objectAtIndex:indexPath.row];
        
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    else if ([segue.identifier isEqualToString:@"EventType"]){
        
        ChooseLastEventViewController *chooseLastEvent = (ChooseLastEventViewController *)segue.destinationViewController;
        chooseLastEvent.event = self.invitation[@"event"];
        chooseLastEvent.invited = self.invited;
    }
    else if([segue.identifier isEqualToString:@"DescriptionDetail"]){
        DetailDescriptionViewController *detailDescription = (DetailDescriptionViewController *)segue.destinationViewController;
        detailDescription.description = self.invitation[@"event"][@"description"];
    }
    else if([segue.identifier isEqualToString:@"Map"]){
        MapViewController *mapController = (MapViewController *)segue.destinationViewController;
    }
    else if([segue.identifier isEqualToString:@"Invited"]){
        InvitedListViewController *invitedController = (InvitedListViewController *)segue.destinationViewController;
        invitedController.invited = self.invited;
    }
    
}

#pragma mark - MAPS

- (void)touchedMap:(UITapGestureRecognizer *)recognizer {
    NSLog(@"MAP !!");
    [self performSegueWithIdentifier:@"Map" sender:nil];
    
    //Do stuff here...
}

-(void)acessMap:(NSNotification *)note{
    
}

- (IBAction)hideViewTap:(id)sender {
    NSLog(@"TEST TAPPPP");
    
    if (self.isShowingDetails) {
        self.headerCollectionView.labelHide.text = @"Afficher les informations";
        [self.headerCollectionView.viewToHide setHidden:YES];
    }
    else{
        self.headerCollectionView.labelHide.text = @"Masquer les informations";
        [self.headerCollectionView.viewToHide setHidden:NO];
    }
    
    self.isShowingDetails = !self.isShowingDetails;
    [self.collectionView reloadData];
    //[self.collectionViewLayout invalidateLayout];
}
@end

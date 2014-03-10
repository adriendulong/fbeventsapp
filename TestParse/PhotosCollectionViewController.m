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
#import "InvitedListViewController.h"
#import "PhotosImportedViewController.h"
#import <MapKit/MapKit.h>
#import "ListEvents.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "CommentPostViewController.h"
#import <EventKit/EventKit.h>

#define METERS_PER_MILE 1609.344
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

//////////
/// SHARE UIActivityController
//////////

/*
@implementation APActivityProvider
- (id) activityViewController:(UIActivityViewController *)activityViewController
          itemForActivityType:(NSString *)activityType
{
    if ( [activityType isEqualToString:UIActivityTypePostToTwitter] )
        return @"This is a #twitter post!";
    if ( [activityType isEqualToString:UIActivityTypePostToFacebook] )
        return @"This is a facebook post!";
    if ( [activityType isEqualToString:UIActivityTypeMessage] )
        return @"SMS message text";
    if ( [activityType isEqualToString:UIActivityTypeMail] )
        return @"Email text here!";
    return nil;
}
- (id) activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController { return @""; }
@end*/

@implementation APActivityIcon
- (NSString *)activityType { return @"com.moment.addToCalendar"; }
- (NSString *)activityTitle { return NSLocalizedString(@"PhotosCollectionViewController_AddCalendar", nil); }
- (UIImage *) activityImage { return [UIImage imageNamed:@"my_events_off"]; }
- (BOOL) canPerformWithActivityItems:(NSArray *)activityItems { return YES; }
- (void) prepareWithActivityItems:(NSArray *)activityItems { }
- (UIViewController *) activityViewController { return nil; }
- (void) performActivity {
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        // the selector is available, so we must be on iOS 6 or newer
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
                if (error)
                {
                    [self activityDidFinish:YES];
                    // display error message here
                }
                else if (!granted)
                {
                    [self activityDidFinish:YES];
                    // display access denied error message here
                }
                else
                {
                    EKEvent *event = [EKEvent eventWithEventStore:eventStore];
                    event.title = self.nameEvent;
                    event.startDate =  self.start_time; //today
                    if (self.is_date_only) {
                        event.allDay = YES;
                        if (self.has_end_time) {
                            event.endDate = self.end_time;
                        }
                        else{
                            event.endDate = [self.start_time dateByAddingTimeInterval:60*60*24];
                        }
                    }
                    else{
                        event.allDay = NO;
                        
                        if (self.has_end_time) {
                            event.endDate = self.end_time;
                        }
                        else{
                            event.endDate = [self.start_time dateByAddingTimeInterval:60*60*12];
                        }
                    }
                    
                    [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                    NSError *err = nil;
                    [eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&err];
                    if (err) {
                        NSLog(@"error : %@", err);
                    }
                    [self activityDidFinish:YES];
                    // access granted
                    // ***** do the important stuff here *****
                }
        }];
    }
    else
    {
        // this code runs in iOS 4 or iOS 5
        // ***** do the important stuff here *****
    }
}
@end



//////////
/// END SHARE UIActivityController
//////////

@interface PhotosCollectionViewController ()

@end

@implementation PhotosCollectionViewController
@synthesize photos;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ShowOrHideDetailsEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AddPhotoToEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UpdateInvitedFinished object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UploadPhotoFinished object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UpdateClosestEvent object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:@"Event Detail View"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    
    [self setTitle];
    //We are in the tab Bar
    /*if (!self.invitation) {
        self.mustChangeTitle = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateClosestEvent:) name:UpdateClosestEvent object:nil];
        
        ListEvents *listEvents = (ListEvents *)[[[[self.tabBarController viewControllers] objectAtIndex:0] viewControllers] objectAtIndex:0];
        self.invitation = listEvents.closestInvitation;
        
        if (self.invitation) {
            [self setTitle];
            
            
            
            //Init images
            NSDate *startDate = self.invitation[@"event"][@"start_time"];
            if ([startDate compare:[NSDate date]]==NSOrderedAscending) {
                self.isDuringOrAfter = YES;
                self.isShowingDetails = NO;
            }
            else{
                self.isDuringOrAfter = NO;
                self.isShowingDetails = YES;
            }
            
            self.hasUpdatedGuestsFromFB = NO;
            [self.collectionViewLayout invalidateLayout];
            
            
            [[Mixpanel sharedInstance] track:@"Now Event" properties:@{@"has_started": [NSNumber numberWithBool:self.isDuringOrAfter]}];
            //Update view
            [self getInvitedFromServer];
            [self updateEventFromFB];
            [self loadPhotos];
        }
        else{
            [self.tabBarController setSelectedIndex:0];
        }
        
    }
    else{
        [self.navigationController setToolbarHidden:YES];
    }*/
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mustChangeTitle = YES;
    
    
    //Notification to hide details about the event
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideDetails:) name:ShowOrHideDetailsEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addPhoto:) name:AddPhotoToEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(greatMomentToUpdateInvited:) name:UpdateInvitedFinished object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPhotosAfterUpload:) name:UploadPhotoFinished object:nil];
    
    //Do we sho details about the event
    self.isShowingDetails = YES;
    
    self.isMapInit = NO;
    
    self.invited = [[NSMutableArray alloc] init];
    
    //Appearance
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [UIColor whiteColor],NSForegroundColorAttributeName,
                                    [UIColor whiteColor],NSBackgroundColorAttributeName,
                                    [MOUtility getFontWithSize:18.0] , NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    //[self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor orangeColor]}];
    
    if (self.invitation) {
        //[self setTitle];
        
        
        
        //Init images
        NSDate *startDate = self.invitation[@"event"][@"start_time"];
        if ([startDate compare:[NSDate date]]==NSOrderedAscending) {
            self.isDuringOrAfter = YES;
            self.isShowingDetails = NO;
        }
        else{
            self.isDuringOrAfter = NO;
            self.isShowingDetails = YES;
        }
        
        self.hasUpdatedGuestsFromFB = NO;
        
        [[Mixpanel sharedInstance] track:@"Event" properties:@{@"has_started": [NSNumber numberWithBool:self.isDuringOrAfter]}];
        
        //Update view
        [self getInvitedFromServer];
        [self updateEventFromFB];
        [self loadPhotos];
    }

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
    
    PFImageView *imageView = (PFImageView *)[cell viewWithTag:100];
    
    if ([photos objectAtIndex:indexPath.row][@"facebookId"]) {
        [imageView setImageWithURL:[photos objectAtIndex:indexPath.row][@"facebook_url_low"] placeholderImage:[UIImage imageNamed:@"photo_default"]];
    }
    else{
        imageView.image = [UIImage imageNamed:@"photo_default"]; // placeholder image
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
        
        //Init labels
        [headerView.takePhotoButton setTitle:NSLocalizedString(@"PhotosCollectionViewController_TakePhoto", nil) forState:UIControlStateNormal];
        [headerView.automaticImport setTitle:NSLocalizedString(@"PhotosCollectionViewController_AutoImport", nil) forState:UIControlStateNormal];
        [headerView.segmentRsvp setTitle:NSLocalizedString(@"UISegmentRSVP_Going", nil) forSegmentAtIndex:0];
        [headerView.segmentRsvp setTitle:NSLocalizedString(@"UISegmentRSVP_Maybe", nil) forSegmentAtIndex:1];
        [headerView.segmentRsvp setTitle:NSLocalizedString(@"UISegmentRSVP_Decline", nil) forSegmentAtIndex:2];
        
        headerView.isShowingDetails = YES;
        
        PFObject *event = self.invitation[@"event"];
        
        if (!self.isMapInit) {
            CLLocationCoordinate2D zoomLocation;
            if (event[@"venue"][@"latitude"]) {
                zoomLocation.latitude = [event[@"venue"][@"latitude"] doubleValue];
                zoomLocation.longitude= [event[@"venue"][@"longitude"] doubleValue];
                
                MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 2*METERS_PER_MILE, 2*METERS_PER_MILE);
                
                [headerView.mapView setRegion:viewRegion animated:NO];
                
            }
            else{
                [headerView.mapView setHidden:YES];
                [[headerView viewWithTag:999] setHidden:YES];
            }
            
            [headerView.mapView setZoomEnabled:NO];
            [headerView.mapView setExclusiveTouch:YES];
            [headerView.mapView setRotateEnabled:NO];
            [headerView.mapView setScrollEnabled:NO];
            
            self.isMapInit = YES;
            
        }
        
        UITapGestureRecognizer *singleFingerTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(touchedMap:)];
        [headerView.mapView addGestureRecognizer:singleFingerTap];
        
        //button map add gesture recognizer
        UITapGestureRecognizer *singleFingerTapSecond =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(touchedMap:)];
        [headerView.mapButton addGestureRecognizer:singleFingerTapSecond];
        
        
        
        
        headerView.invitation = self.invitation;
        
        if (event[@"summary_guests"]) {
            [self.invitation saveInBackground];
            self.headerCollectionView.nbTotalInvitedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"PhotosCollectionViewController_NbGuests", nil), event[@"summary_guests"][@"count"]];
            self.headerCollectionView.detailInvitedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"PhotosCollectionViewController_NbGuests_NbMaybe", nil), event[@"summary_guests"][@"attending_count"], event[@"summary_guests"][@"maybe_count"]];
        }
        
        headerView.nameEvent.text = event[@"name"];
        headerView.ownerEvent.text = [NSString stringWithFormat:NSLocalizedString(@"PhotosCollectionViewController_OwnerEvent", nil), event[@"owner"][@"name"]];
        headerView.eventDescription.text = event[@"description"];
        [headerView.coverImage setImageWithURL:event[@"cover"] placeholderImage:[UIImage imageNamed:@"default_cover"]];
        if (event[@"location"]) {
            headerView.locationLabel.text = event[@"location"];
        }
        else if(event[@"venue"][@"name"]){
            headerView.locationLabel.text = event[@"venue"][@"name"];
        }
        
        
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
        NSString *dateComponents;
        if([event[@"is_date_only"] boolValue]) {
            dateComponents = @"EEEEdMMMM";
        }
        else{
            dateComponents = [NSString stringWithFormat:@"EEEEdMMMM %@ HH:mm", NSLocalizedString(@"PhotosCollectionViewController_TimeConjonction", nil)];
        }
        dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:[NSLocale currentLocale]];
        NSDateFormatter *dformat = [[NSDateFormatter alloc]init];
        [dformat setDateFormat:dateFormat];
        headerView.dateEvent.text = [NSString stringWithFormat:@"%@", [dformat stringFromDate:event[@"start_time"]]];
        
        //Adapt position buttons
        if (!self.isDuringOrAfter) {
            [headerView.automaticImport setHidden:YES];
            headerView.constraintButtonPhoto.constant = 35.0f;
            headerView.constraintViewNbPhotos.constant = 0.0f;
            
            
            
        }
        else{
            headerView.constraintButtonPhoto.constant = 90.0f;
            headerView.constraintViewNbPhotos.constant = 0.0f;
        }
        
        //Show or not details
        if (!self.isShowingDetails) {
            [headerView.viewToHide setHidden:YES];
            self.headerCollectionView.labelHide.text = NSLocalizedString(@"PhotosCollectionViewController_Show_Label", nil);
            
            CGAffineTransform leftRotationTransform = CGAffineTransformIdentity;
            leftRotationTransform = CGAffineTransformRotate(leftRotationTransform, DEGREES_TO_RADIANS(270));
            self.headerCollectionView.leftArrow.transform = leftRotationTransform;
            
            CGAffineTransform rightRotationTransform = CGAffineTransformIdentity;
            rightRotationTransform = CGAffineTransformRotate(rightRotationTransform, DEGREES_TO_RADIANS(90));
            self.headerCollectionView.rightArrow.transform = rightRotationTransform;
        }
        else{
            self.headerCollectionView.labelHide.text = NSLocalizedString(@"PhotosCollectionViewController_Hide_Label", nil);
        }
        
        self.headerCollectionView = headerView;
        reusableview = headerView;
    }

    return reusableview;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    
    if (section==0) {
        if (self.isDuringOrAfter) {
            if (self.isShowingDetails) {
                if (!self.invitation[@"event"][@"venue"][@"latitude"]) {
                    return CGSizeMake(800, 720);
                }
                else{
                    return CGSizeMake(800, 945);
                }
            }
            else{
                return CGSizeMake(800, 360);
            }
        }
        else{
            if (self.isShowingDetails) {
                if (!self.invitation[@"event"][@"venue"][@"latitude"]) {
                    return CGSizeMake(800, 680);
                }
                else{
                    return CGSizeMake(800, 885);
                }
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

-(void)getNbPhotos{
    PFQuery *query = [PFQuery queryWithClassName:@"Photo"];
    [query whereKey:@"event" equalTo:self.invitation[@"event"]];
    [query countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (!error) {
            if (self.headerCollectionView) {
                self.headerCollectionView.nbPhotosLabel.text = [NSString stringWithFormat:NSLocalizedString(@"PhotosCollectionViewController_NbPhotos", nil), count];
            }
        } else {
            // The request failed
        }
    }];
}

-(void)loadPhotos{
    [self getNbPhotos];
    PFQuery *queryPhotos = [PFQuery queryWithClassName:@"Photo"];
    [queryPhotos whereKey:@"event" equalTo:self.invitation[@"event"]];
    [queryPhotos includeKey:@"user"];
    [queryPhotos includeKey:@"prospect"];
    [queryPhotos orderByDescending:@"createdAt"];
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
    [self getNbPhotos];
    PFQuery *queryPhotos = [PFQuery queryWithClassName:@"Photo"];
    [queryPhotos whereKey:@"event" equalTo:self.invitation[@"event"]];
    [queryPhotos includeKey:@"user"];
    [queryPhotos includeKey:@"prospect"];
    [queryPhotos orderByDescending:@"createdAt"];
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
            [self updateEvent:result compareTo:self.invitation[@"event"]];
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
        
        
        if(event[@"venue"]){
            eventToCompare[@"venue"] = event[@"venue"];
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
        
        //COVER
        if(event[@"cover"]){
            eventToCompare[@"cover"] = event[@"cover"][@"source"];
        }
        
        //OWNER
        if(event[@"owner"]){
            eventToCompare[@"owner"] = event[@"owner"];
        }
        
        //ADMINS
        if(event[@"admins"]){
            eventToCompare[@"admins"] = event[@"admins"][@"data"];
        }
        
        //eventToCompare[@"updateWithFB"] = [NSDate date];
        
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
    if (self.invitation[@"event"]) {
        PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
        [query whereKey:@"event" equalTo:self.invitation[@"event"]];
        [query whereKeyExists:@"user"];
        [query includeKey:@"user"];
        query.limit = 5;
        
        //Cache then network
        query.cachePolicy = kPFCachePolicyNetworkElseCache;
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                
                for (PFObject *guest in objects) {
                    if (guest[@"user"]) {
                        NSDictionary *invitation = @{@"name": guest[@"user"][@"name"], @"facebookId":guest[@"user"][@"facebookId"], @"rsvp_status":guest[@"rsvp_status"]};
                        if (invitation!=nil) {
                            [self.invited addObject:invitation];
                        }
                    }
                }

                [self updateGuestsView];
                
                //Get all the invited
                if (self.invited.count < 5) {
                    [self getGuestsFromFacebookEvent:self.invitation[@"event"][@"eventId"] withLimit:(5-self.invited.count)];
                }
                
                
            } else {
                // Log details of the failure
                NSLog(@"Problème de chargement");
            }
        }];
    }
    
}


-(void)getGuestsFromFacebookEvent:(NSString *)facebookId withLimit:(int)limit{
    NSString *requestString = [NSString stringWithFormat:@"%@/invited?limit=%i&summary=1", self.invitation[@"event"][@"eventId"], limit];
    FBRequest *request = [FBRequest requestForGraphPath:requestString];

    self.hasUpdatedGuestsFromFB = YES;
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            //Get all the invited
            NSLog(@"%@", result);
            NSArray *guests = result[@"data"];
            
            [self setNbGuests:result[@"summary"]];
            
            self.guestViewUpdated = NO;
            self.nbInvitedToAdd = guests.count;
            self.nbInvitedAlreadyAdded = 0;
            
            for (id guest in guests) {
                [self addOrUpdateInvited:guest];
            }
            
            [self updateGuestsView];
            
        }
        else{
            NSLog(@"%@", error);
        }
    }];
}

-(void)addOrUpdateInvited:(NSDictionary *)invited{
    NSDictionary *invitation = @{@"name": invited[@"name"], @"facebookId":invited[@"id"], @"rsvp_status":invited[@"rsvp_status"]};
    [self.invited addObject:invitation];
    
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

/*
 Update the main view (header of collection voew)
 */

-(void)updateView{
    
    PFObject *event = self.invitation[@"event"];
    
    [self setTitle];
    
    
    self.headerCollectionView.invitation = self.invitation;
    self.headerCollectionView.nameEvent.text = event[@"name"];
    self.headerCollectionView.ownerEvent.text = [NSString stringWithFormat:NSLocalizedString(@"PhotosCollectionViewController_OwnerEvent", nil), event[@"owner"][@"name"]];
    self.headerCollectionView.eventDescription.text = event[@"description"];
    [self.headerCollectionView.coverImage setImageWithURL:event[@"cover"] placeholderImage:[UIImage imageNamed:@"default_cover"]];
    
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
    NSString *dateComponents;
    if([event[@"is_date_only"] boolValue]) {
        dateComponents = @"EEEEdMMMM";
    }
    else{
        dateComponents = [NSString stringWithFormat:@"EEEEdMMMM %@ HH:mm", NSLocalizedString(@"PhotosCollectionViewController_TimeConjonction", nil)];
    }
    NSLocale *prefredLocale = [NSLocale currentLocale];
    dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:prefredLocale];
    NSDateFormatter *dformat = [[NSDateFormatter alloc]init];
    [dformat setDateFormat:dateFormat];
    self.headerCollectionView.dateEvent.text = [NSString stringWithFormat:@"%@", [dformat stringFromDate:event[@"start_time"]]];
    
    //self.locationLabel.text = event[@"location"];
}


/*
 Update view with all the guests
 */

-(void)updateGuestsView{
    
    //Update Guests
    for (NSInteger i=1; i<6; i++) {
        if (i<=[self.invited count]) {
            NSDictionary *invitation = [self.invited objectAtIndex:i-1];

            
            UIView *guestView = [self.headerCollectionView.viewToHide viewWithTag:i];
            [guestView setHidden:NO];
            UIImageView *photo = (UIImageView *)[guestView viewWithTag:6];
            [photo setImageWithURL:[MOUtility UrlOfFacebooProfileImage:invitation[@"facebookId"] withResolution:FacebookLargeProfileImage]
                  placeholderImage:[UIImage imageNamed:@"profil_default"]];
            photo.layer.cornerRadius = 23.0f;
            photo.layer.masksToBounds = YES;
            
            UIImageView *iconGo = (UIImageView *)[guestView viewWithTag:7];
            if ([invitation[@"rsvp_status"] isEqualToString:FacebookEventMaybe]) {
                [iconGo setImage:[UIImage imageNamed:@"maybe"]];
            }
            else if ([invitation[@"rsvp_status"] isEqualToString:FacebookEventAttending]){
                [iconGo setImage:[UIImage imageNamed:@"go"]];
            }
            else{
                [iconGo setHidden:YES];
            }
        }
        else{
            UIView *guestView = [self.headerCollectionView.viewToHide viewWithTag:i];
            [guestView setHidden:YES];
        }
        
        
        
        //UIImageView *indicator = (UIImageView *)[guestView viewWithTag:2];
    }
}


#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"AddPhoto"]) {
        [[Mixpanel sharedInstance] track:@"Take Photo" properties:@{@"has_started": [NSNumber numberWithBool:self.isDuringOrAfter], @"Where" : @"Collection View"}];
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        CameraViewController *cameraViewController = [navController.viewControllers objectAtIndex:0];
        cameraViewController.event = self.invitation[@"event"];
    }
    else if ([segue.identifier isEqualToString:@"AddPhotoBarItem"]) {
        [[Mixpanel sharedInstance] track:@"Take Photo" properties:@{@"has_started": [NSNumber numberWithBool:self.isDuringOrAfter], @"Where" : @"Top Bar"}];
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        CameraViewController *cameraViewController = [navController.viewControllers objectAtIndex:0];
        cameraViewController.event = self.invitation[@"event"];
    }
    else if ([segue.identifier isEqualToString:@"ShowDetailPhoto"]){
        
        [[Mixpanel sharedInstance] track:@"Detail Photo"];
        
        NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
        NSIndexPath *indexPath = [indexPaths objectAtIndex:0];

        PhotoDetailViewController *photoDetailController = (PhotoDetailViewController *)segue.destinationViewController;
        photoDetailController.photo = [self.photos objectAtIndex:indexPath.row];
        
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    else if ([segue.identifier isEqualToString:@"EventType"]){
        
        ChooseLastEventViewController *chooseLastEvent = (ChooseLastEventViewController *)segue.destinationViewController;
        chooseLastEvent.event = self.invitation[@"event"];
        chooseLastEvent.invited = [self.invited mutableCopy];
        
        if (!self.mustChangeTitle) {
            chooseLastEvent.levelRoot = 0;
        }
        else{
            chooseLastEvent.levelRoot = 1;
        }
        
    }
    #warning Direct if end time for event (update type ??)
    else if ([segue.identifier isEqualToString:@"DirectImport"]){
        
        PhotosImportedViewController *photoImported = (PhotosImportedViewController *)segue.destinationViewController;
        photoImported.event = self.invitation[@"event"];
        photoImported.levelRoot = 1;
    }
    else if([segue.identifier isEqualToString:@"DescriptionDetail"]){
        
        DetailDescriptionViewController *detailDescription = (DetailDescriptionViewController *)segue.destinationViewController;
        detailDescription.description = self.invitation[@"event"][@"description"];
    }
    else if([segue.identifier isEqualToString:@"Invited"]){
        
        InvitedListViewController *invitedController = (InvitedListViewController *)segue.destinationViewController;
        invitedController.invited = [self.invited mutableCopy];
        invitedController.event = self.invitation[@"event"];
    }
    else if([segue.identifier isEqualToString:@"Discussions"]){
        CommentPostViewController *postViewController = (CommentPostViewController *)segue.destinationViewController;
        postViewController.idEvent = self.invitation[@"event"][@"eventId"];
        //invitedController.event = self.invitation[@"event"];
    }
    
}

#pragma mark - MAPS

- (void)touchedMap:(UITapGestureRecognizer *)recognizer {
    
    NSString *placeGoodFormat;
    if (self.invitation[@"event"][@"location"]) {
        placeGoodFormat = [[self.invitation[@"event"][@"location"] capitalizedString] stringByReplacingOccurrencesOfString:@" " withString: @"+"];
    }
    else if(self.invitation[@"event"][@"venue"][@"name"]){
        placeGoodFormat = [[self.invitation[@"event"][@"venue"][@"name"] capitalizedString] stringByReplacingOccurrencesOfString:@" " withString: @"+"];
    }
    
    placeGoodFormat = [MOUtility removeAccentuation:placeGoodFormat];
    
    if ([[UIApplication sharedApplication] canOpenURL:
              [NSURL URLWithString:@"comgooglemaps://"]]) {
        
        NSString *request = [NSString stringWithFormat:@"comgooglemaps://?q=%@", placeGoodFormat];

        if(![[UIApplication sharedApplication] openURL:
            [NSURL URLWithString:request]]){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PhotosCollectionViewController_Error", nil) message:NSLocalizedString(@"PhotosCollectionViewController_Error_GMaps", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"PhotosCollectionViewController_OK", nil), nil];
            [alert show];
        }
    } else {
        NSString *request = [NSString stringWithFormat:@"http://maps.apple.com/?q=%@", placeGoodFormat];
        
        if(![[UIApplication sharedApplication] openURL:
             [NSURL URLWithString:request]]){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PhotosCollectionViewController_Error", nil) message:NSLocalizedString(@"PhotosCollectionViewController_Error_Maps", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"PhotosCollectionViewController_OK", nil), nil];
            [alert show];
        }
    }
    
    
    //Do stuff here...
}



/*
 Go to the discussions view
 */
- (IBAction)showDiscussions:(id)sender {
    NSLog(@"Discussions");
    [self performSegueWithIdentifier:@"Discussions" sender:nil];
}

- (IBAction)autoImport:(id)sender {
    NSLog(@"auto Import");
    if (self.invitation[@"event"][@"end_time"]) {
        [[Mixpanel sharedInstance] track:@"Import Photo Auto" properties:@{@"has_end_time": @YES, @"has_started": [NSNumber numberWithBool:self.isDuringOrAfter]}];
        [self performSegueWithIdentifier:@"DirectImport" sender:nil];
    }
    else{
        [[Mixpanel sharedInstance] track:@"Import Photo Auto" properties:@{@"has_end_time": @NO, @"has_started": [NSNumber numberWithBool:self.isDuringOrAfter]}];
        [self performSegueWithIdentifier:@"EventType" sender:nil];
        
    }
}

/*
 Hide or show the information when tap on the top button
 */

- (IBAction)hideViewTap:(id)sender {
    
    if (self.isShowingDetails) {
        self.headerCollectionView.labelHide.text = NSLocalizedString(@"PhotosCollectionViewController_Show_Label", nil);
        [self.headerCollectionView.viewToHide setHidden:YES];
        
        CGAffineTransform leftRotationTransform = CGAffineTransformIdentity;
        leftRotationTransform = CGAffineTransformRotate(leftRotationTransform, DEGREES_TO_RADIANS(270));
        self.headerCollectionView.leftArrow.transform = leftRotationTransform;
        
        CGAffineTransform rightRotationTransform = CGAffineTransformIdentity;
        rightRotationTransform = CGAffineTransformRotate(rightRotationTransform, DEGREES_TO_RADIANS(90));
        self.headerCollectionView.rightArrow.transform = rightRotationTransform;
    }
    else{
        self.headerCollectionView.labelHide.text = NSLocalizedString(@"PhotosCollectionViewController_Hide_Label", nil);
        [self.headerCollectionView.viewToHide setHidden:NO];
        
        CGAffineTransform leftRotationTransform = CGAffineTransformIdentity;
        leftRotationTransform = CGAffineTransformRotate(leftRotationTransform, DEGREES_TO_RADIANS(0));
        self.headerCollectionView.leftArrow.transform = leftRotationTransform;
        
        CGAffineTransform rightRotationTransform = CGAffineTransformIdentity;
        rightRotationTransform = CGAffineTransformRotate(rightRotationTransform, DEGREES_TO_RADIANS(0));
        self.headerCollectionView.rightArrow.transform = rightRotationTransform;
    }
    
    self.isShowingDetails = !self.isShowingDetails;
    [self.collectionView reloadData];
    //[self.collectionViewLayout invalidateLayout];
}


/*
 Share the event
 */

- (IBAction)share:(id)sender {
    //APActivityProvider *ActivityProvider = [[APActivityProvider alloc] init];
    
    NSString *message;
    NSString *urlEvent = [NSString stringWithFormat:@"http://woovent.com/e/%@", ((PFObject *)self.invitation[@"event"]).objectId];
    if ([self.headerCollectionView.nbPhotosLabel.text intValue]>3) {
        message = [NSString stringWithFormat:NSLocalizedString(@"PhotosCollectionViewController_ShareMessageMultiple", nil), [self.headerCollectionView.nbPhotosLabel.text intValue], self.invitation[@"event"][@"name"], urlEvent];
    }
    else{
        message = [NSString stringWithFormat:NSLocalizedString(@"PhotosCollectionViewController_ShareMessageFew", nil), self.invitation[@"event"][@"name"], urlEvent];
    }
   
    NSArray *urlToShare = [NSArray arrayWithObjects:message, nil];
    
    
    //Custom Save Date
    APActivityIcon *ca = [[APActivityIcon alloc] init];
    ca.nameEvent = self.invitation[@"event"][@"name"];
    ca.is_date_only = [self.invitation[@"event"][@"is_date_only"] boolValue];
    if(self.invitation[@"event"][@"end_time"]){
        ca.has_end_time = YES;
        ca.end_time = (NSDate *)self.invitation[@"event"][@"end_time"];
    }
    ca.start_time = (NSDate *)self.invitation[@"event"][@"start_time"];
    NSArray *Acts = @[ca];
    
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:urlToShare applicationActivities:Acts];
    [controller setValue:self.invitation[@"event"][@"name"] forKey:@"subject"];
    NSArray *excludedActivities = @[UIActivityTypePostToWeibo,
                                    UIActivityTypeAirDrop,
                                    UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                                    UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,
                                    UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
    controller.excludedActivityTypes = excludedActivities;
    
    controller.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (completed) {
            [[Mixpanel sharedInstance] track:@"Share Event" properties:@{@"type": activityType}];
        }
    };
    
    [self presentViewController:controller animated:YES completion:nil];
    
    
    
}


-(void)setTitle{
    //Page Title
    
    if (self.mustChangeTitle) {
        PFObject *event = self.invitation[@"event"];
        
        NSDate *today = [MOUtility setDateTime:[NSDate date] withTime:0];
        NSDate *start_date_event = [MOUtility setDateTime:(NSDate *)event[@"start_time"] withTime:0];
        
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [gregorianCalendar components:NSDayCalendarUnit
                                                            fromDate:today
                                                              toDate:start_date_event
                                                             options:0];
        
        NSLog(@"Date interval %i", components.day);
        
        
        if (components.day > 1) {
            self.title = [NSString stringWithFormat:NSLocalizedString(@"PhotosCollectionViewController_Title_Future", nil), components.day];
        } else if (components.day == 1) {
            self.title = NSLocalizedString(@"PhotosCollectionViewController_Title_Tomorrow", nil);
        } else if (components.day == 0) {
            self.title = NSLocalizedString(@"PhotosCollectionViewController_Title_Today", nil);
        } else {
            if (abs(components.day) > 1) {
                self.title = [NSString stringWithFormat:NSLocalizedString(@"PhotosCollectionViewController_Title_Past", nil), abs(components.day)];
            } else {
                self.title = NSLocalizedString(@"PhotosCollectionViewController_Title_Yesterday", nil);
            }
        }
    }
    else{
        self.title = NSLocalizedString(@"UITabBar_Title_FourthPosition", nil);
    }
    
}

-(void)setNbGuests:(NSDictionary *)summary{
    NSLog(@"Attending : %@", summary[@"attending_count"]);
    self.invitation[@"event"][@"summary_guests"] = summary;
    [self.invitation saveInBackground];
    self.headerCollectionView.nbTotalInvitedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"PhotosCollectionViewController_NbGuests", nil), (int)summary[@"count"]];
    self.headerCollectionView.detailInvitedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"PhotosCollectionViewController_NbGuests_NbMaybe", nil), summary[@"attending_count"], summary[@"maybe_count"]];
}


@end

//
//  EventDetailViewController.m
//  TestParseAgain
//
//  Created by Adrien Dulong on 04/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "EventDetailViewController.h"
#import "MOUtility.h"
#import "EventUtilities.h"
#import "FbEventsUtilities.h"

@interface EventDetailViewController ()
@end

@implementation EventDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.tintColor = [UIColor orangeColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor orangeColor]}];
    self.title = NSLocalizedString(@"EventDetailViewController_Title", nil);
    
    //Init
    self.isShowingDetails = YES;
    
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate -33.86,151.20 at zoom level 6.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.86
                                                            longitude:151.20
                                                                 zoom:6];
    self.mapView_ = [GMSMapView mapWithFrame:CGRectMake(0, 238, self.view.bounds.size.width, 160) camera:camera];
    self.mapView_.myLocationEnabled = YES;
    self.mapView_.settings.scrollGestures = NO;
    self.mapView_.settings.zoomGestures = NO;
    [self.toHideView addSubview:self.mapView_];
    
    // Creates a marker in the center of the map.
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(-33.86, 151.20);
    marker.title = NSLocalizedString(@"EventDetailViewController_Marker_Title", nil);
    marker.snippet = NSLocalizedString(@"EventDetailViewController_Marker_snippet", nil);
    marker.map = self.mapView_;
    
    
    self.myScrolly.contentSize = CGSizeMake(320, 1000);
    
    MKMapView *map = [[MKMapView alloc] initWithFrame:CGRectMake(0, 395, self.view.bounds.size.width, 160)];
    [map setShowsUserLocation:YES];
    [map setExclusiveTouch:NO];
    //[self.myScrolly addSubview:map];
    
    NSLog(@"%@", self.invitation[@"event"][@"name"]);
    
    //Facebook And Server Requests
    [self updateEventFromFB];
    [self getInvitedFromServer];
    [self updatePosts];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateView{
    PFObject *event = self.invitation[@"event"];
    
    //View Title
    #warning Inter
    NSTimeInterval distanceBetweenDates = [event[@"start_time"] timeIntervalSinceDate:[NSDate date]];
    double secondsInAnDays = 86400;
    NSInteger daysBetweenDates = distanceBetweenDates / secondsInAnDays;
    self.title = [NSString stringWithFormat:NSLocalizedString(@"EventDetailViewController_Countdown", nil), daysBetweenDates];
    
    self.nameEvent.text = event[@"name"];
    self.ownerEvent.text = [NSString stringWithFormat:NSLocalizedString(@"EventDetailViewController_OwnerEvent", nil), event[@"owner"][@"name"]];
    self.descriptionLabel.text = event[@"description"];
    [self.coverImage setImageWithURL:event[@"cover"] placeholderImage:[UIImage imageNamed:@"covertestinfos.png"]];
    
    //Date
    NSString *dateFormat;
    NSString *dateComponents = @"EEEEdMMMM";
    NSLocale *prefredLocale = [NSLocale currentLocale];
    dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:prefredLocale];
    NSDateFormatter *dformat = [[NSDateFormatter alloc]init];
    [dformat setDateFormat:dateFormat];
    self.dateEvent.text = [NSString stringWithFormat:@"%@", [dformat stringFromDate:event[@"start_time"]]];
    
    self.locationLabel.text = event[@"location"];
    
   
    
}

-(void)updateGuestsView{
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
            
            UIView *guestView = [self.myScrolly viewWithTag:i];
            [guestView setHidden:NO];
            UIImageView *photo = (UIImageView *)[guestView viewWithTag:6];
            [photo setImageWithURL:[MOUtility UrlOfFacebooProfileImage:guest[@"facebookId"]]
                  placeholderImage:[UIImage imageNamed:@"covertest.png"]];
            photo.layer.cornerRadius = 23.0f;
            photo.layer.masksToBounds = YES;
        }
        else{
            UIView *guestView = [self.myScrolly viewWithTag:i];
            [guestView setHidden:YES];
        }
        
        
        
        //UIImageView *indicator = (UIImageView *)[guestView viewWithTag:2];
    }
}

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

-(void)getGuestsFromFacebookEvent:(NSString *)facebookId{
    NSString *requestString = [NSString stringWithFormat:@"%@?fields=invited.limit(50)", self.invitation[@"event"][@"eventId"]];
    FBRequest *request = [FBRequest requestForGraphPath:requestString];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            //Get all the invited
            NSArray *guests = result[@"invited"][@"data"];

            for (id guest in guests) {
                NSLog(@"name : %@", guest[@"name"]);
                [self addOrUpdateInvited:guest];
            }
            
            //Now update from server
            [self getInvitedFromServer];
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

-(void)updatePosts{
    NSString *requestString = [NSString stringWithFormat:@"%@/feed", self.invitation[@"event"][@"eventId"]];
    FBRequest *request = [FBRequest requestForGraphPath:requestString];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            NSArray *posts = result[@"data"];
            self.nbTotalPost = [posts count];
            self.nbPostUpdated = 0;
            NSLog(@"NB posts : %i", [posts count]);
            
            for(id post in posts){
                NSLog(@"Boucle");
                [self createOrUpdatePost:post];
            }
            
            
        }
        else{
            NSLog(@"%@", error);
        }
    }];
}

-(void)createOrUpdatePost:(NSDictionary *)post{
    if (post[@"message"]) {
        NSLog(@"Message : %@", post[@"message"]);
    }
    if ([post[@"type"] isEqualToString:@"photo"]) {
        NSLog(@"Picture : %@", post[@"picture"]);
    }
    
    PFObject *postToSave = [PFObject objectWithClassName:@"Post"];
    [postToSave setObject:self.invitation[@"event"] forKey:@"event"];
    postToSave[@"from"] = post[@"from"];
    postToSave[@"type"] = post[@"type"];
    postToSave[@"postId"] = post[@"id"];
    
    if(post[@"message"]){
        postToSave[@"message"] = post[@"message"];
    }
    if ([post[@"type"] isEqualToString:@"photo"]) {
        postToSave[@"picture"] = post[@"picture"];
        postToSave[@"link"] = post[@"link"];
        
    }
    if (post[@"story"]) {
        postToSave[@"story"] = post[@"story"];
    }
    
    NSLog(@"Story : %@", post[@"story"]);
    
    [postToSave saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if(error){
            NSLog(@"Error : %@", [error userInfo]);
        }
        self.nbPostUpdated++;
        
        if (self.nbPostUpdated == self.nbTotalPost) {
            NSLog(@"SAVE FINISHED");
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
    }
    
    //The invitation does not exist
    else{
        //See if a user or a prospect exist
        PFQuery *query = [PFQuery queryWithClassName:@"User"];
        [query whereKey:@"facebookId" equalTo:invited[@"id"]];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            //No user
            if (!object) {
                
                //We create a prospect
                PFObject *prospectObject = [PFObject objectWithClassName:@"Prospect"];
                prospectObject[@"facebookId"] = invited[@"id"];
                prospectObject[@"name"] = invited[@"name"];
                [prospectObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    //And create invitation
                    [self createInvitation:invited[@"rsvp_status"] forUser:nil forProspect:prospectObject];
                }];
                
            //A user we create invitation
            } else {
                [self createInvitation:invited[@"rsvp_status"] forUser:(PFUser *)object forProspect:nil];
            }
        }];
        
    }
    
}

-(void)getInvitedFromServer{
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"event" equalTo:self.invitation[@"event"]];
    [query includeKey:@"user"];
    [query includeKey:@"prospect"];
    
    //Cache then network
    #warning Modify Cache Policy
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
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

//Hide or Show details about the event

- (IBAction)hideShowDetails:(id)sender {
    if (self.isShowingDetails) {
        self.labelHide.text = @"Détails";
        self.arrowHide.image = [UIImage imageNamed:@"next_gris.png"];
        [self.toHideView setHidden:YES];
        self.isShowingDetails = NO;
    }
    else{
        self.labelHide.text = @"Masquer";
        self.arrowHide.image = [UIImage imageNamed:@"down.png"];
        [self.toHideView setHidden:NO];
        self.isShowingDetails = YES;
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
}

@end

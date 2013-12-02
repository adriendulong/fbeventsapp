//
//  EventDetailViewController.h
//  TestParseAgain
//
//  Created by Adrien Dulong on 04/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface EventDetailViewController : UIViewController

@property (strong, nonatomic) PFObject *invitation;
@property (strong, nonatomic) NSArray *invited;
@property (nonatomic, assign) int nbTotalPost;
@property (nonatomic, assign) int nbPostUpdated;
@property (weak, nonatomic) IBOutlet UIScrollView *myScrolly;
@property (weak,nonatomic) GMSMapView *mapView_;
@property (weak, nonatomic) IBOutlet UIView *toHideView;
@property (weak, nonatomic) IBOutlet UILabel *nameEvent;
@property (weak, nonatomic) IBOutlet UILabel *ownerEvent;
@property (weak, nonatomic) IBOutlet UILabel *dateEvent;
@property (weak, nonatomic) IBOutlet UITextView *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *guestsLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *testImage;
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;
@property (weak, nonatomic) IBOutlet UILabel *labelHide;
@property (weak, nonatomic) IBOutlet UIImageView *arrowHide;
@property (nonatomic, assign) BOOL isShowingDetails;


- (IBAction)hideShowDetails:(id)sender;
-(void)updateEvent:(NSDictionary *)event compareTo:(PFObject *)eventToCompare;
-(void)updateInviteUser:(PFUser *)user toEvent:(PFObject *)event withRsvp:(NSString *)rsvp;
-(void)updateView;

@end

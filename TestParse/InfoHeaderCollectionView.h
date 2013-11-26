//
//  InfoHeaderCollectionView.h
//  TestParseAgain
//
//  Created by Adrien Dulong on 08/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <GoogleMaps/GoogleMaps.h>

@interface InfoHeaderCollectionView : UICollectionReusableView

@property (strong, nonatomic) PFObject *invitation;
@property (strong, nonatomic) NSArray *invited;
@property (weak, nonatomic) IBOutlet UIView *viewToHide;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentRsvp;
@property (weak, nonatomic) IBOutlet UILabel *dateEvent;
@property (weak, nonatomic) IBOutlet UITextView *eventDescription;
@property (weak, nonatomic) IBOutlet UILabel *nameEvent;
@property (weak, nonatomic) IBOutlet UILabel *ownerEvent;
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;
@property (weak,nonatomic) GMSMapView *mapView_;
@property (nonatomic, assign) BOOL isShowingDetails;
@property (weak, nonatomic) IBOutlet UIImageView *arrowHide;
@property (weak, nonatomic) IBOutlet UILabel *labelHide;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *automaticImport;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintButtonPhoto;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintViewNbPhotos;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separateConstraint;


- (IBAction)rsvpChanged:(id)sender;
- (IBAction)hideView:(id)sender;
@end

//
//  PhotosCollectionViewController.h
//  TestParseAgain
//
//  Created by Adrien Dulong on 08/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfoHeaderCollectionView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <CoreLocation/CoreLocation.h>

/*@interface APActivityProvider : UIActivityItemProvider <UIActivityItemSource>
@end*/
@interface APActivityIcon : UIActivity
@property (strong, nonatomic) NSDate *start_time;
@property (strong, nonatomic) NSDate *end_time;
@property (strong, nonatomic) NSString *nameEvent;
@property (nonatomic, assign) BOOL has_end_time;
@property (nonatomic, assign) BOOL is_date_only;
@end

@interface PhotosCollectionViewController : UICollectionViewController

@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) PFObject *invitation;
@property (strong, nonatomic) NSMutableArray *invited;
@property (strong, nonatomic) InfoHeaderCollectionView *headerCollectionView;
@property (strong, nonatomic) NSIndexPath *headerIndexPath;
@property (nonatomic, assign) BOOL isShowingDetails;
@property (nonatomic, assign) int nbInvitedToAdd;
@property (nonatomic, assign) int nbInvitedAlreadyAdded;
@property (nonatomic, assign) BOOL guestViewUpdated;
@property (nonatomic, assign) BOOL hasUpdatedGuestsFromFB;
@property (nonatomic, assign) BOOL isDuringOrAfter;
@property (nonatomic, assign) int nbAttending;
@property (nonatomic, assign) int nbMaybe;
@property (nonatomic, assign) int nbTotal;
@property (nonatomic, assign) BOOL isMapInit;
@property (assign, nonatomic) BOOL mustChangeTitle;
- (IBAction)showDiscussions:(id)sender;

- (IBAction)autoImport:(id)sender;
- (IBAction)hideViewTap:(id)sender;
- (IBAction)share:(id)sender;
@end

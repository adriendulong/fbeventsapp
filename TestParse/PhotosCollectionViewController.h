//
//  PhotosCollectionViewController.h
//  TestParseAgain
//
//  Created by Adrien Dulong on 08/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "InfoHeaderCollectionView.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface PhotosCollectionViewController : UICollectionViewController

@property (strong, nonatomic) NSArray *photos;
@property (weak,nonatomic) GMSMapView *mapView_;
@property (strong, nonatomic) PFObject *invitation;
@property (strong, nonatomic) NSArray *invited;
@property (strong, nonatomic) InfoHeaderCollectionView *headerCollectionView;
@property (strong, nonatomic) NSIndexPath *headerIndexPath;
@property (nonatomic, assign) BOOL isShowingDetails;
@property (nonatomic, assign) int nbInvitedToAdd;
@property (nonatomic, assign) int nbInvitedAlreadyAdded;
@property (nonatomic, assign) BOOL guestViewUpdated;
@property (nonatomic, assign) BOOL isDuringOrAfter;;

- (IBAction)hideViewTap:(id)sender;
@end

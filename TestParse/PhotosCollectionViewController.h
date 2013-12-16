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

@interface PhotosCollectionViewController : UICollectionViewController

@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) PFObject *invitation;
@property (strong, nonatomic) NSArray *invited;
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

- (IBAction)autoImport:(id)sender;
- (IBAction)hideViewTap:(id)sender;
@end

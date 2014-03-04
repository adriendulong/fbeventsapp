//
//  PhotosAlbumViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 28/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "WYStoryboardPopoverSegue.h"
#import "WYPopoverController.h"
#import "PhotosDatasourceViewController.h"
#import "MXLMediaView.h"

@interface PhotosAlbumViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, WYPopoverControllerDelegate, PhotosDatasourceViewControllerDelegate, MXLMediaViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, assign, getter=isTapLongGesture) BOOL tapLongGesture;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;

//@property (nonatomic) ALAssetsGroupType assetsGroupType;
@property (nonatomic) NSString *selectedGroupPersistentID;
@property (nonatomic, strong) NSMutableArray *assetsGroupList;

@property (nonatomic, strong) NSMutableArray *datasourceAutomatic;
@property (nonatomic, strong) NSMutableArray *datasourceComplete;
//@property (nonatomic, strong) NSMutableArray *photosHash;
@property (strong, nonatomic) PFObject *event;

@property (nonatomic) int nbAutomaticPhotos;

@property (nonatomic, strong) WYPopoverController *photosDatasourcePopoverController;
//@property (nonatomic) NSInteger selectedDatasource;
@property (nonatomic, strong) UIButton *titleViewButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerConstraint;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *validateButton;


- (IBAction)selectPhotos:(id)sender;

@end

//
//  PhotosAlbumViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 28/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotosAlbumViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;

@property (nonatomic, strong) NSMutableArray *datasourceAutomatic;
@property (nonatomic, strong) NSMutableArray *datasourceComplete;
@property (nonatomic, strong) NSMutableArray *photosHash;
@property (strong, nonatomic) PFObject *event;

@property (nonatomic) int nbAutomaticPhotos;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerConstraint;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *validateButton;


- (IBAction)selectPhotos:(id)sender;

@end

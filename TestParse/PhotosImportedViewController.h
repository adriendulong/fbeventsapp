//
//  PhotosImportedViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 22/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PhotosImportedViewController : UICollectionViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSMutableArray *imagesFound;
@property (assign, nonatomic) int numberOfPhotosSelectedPhone;
@property (assign, nonatomic) int numberOfPhotosSelectedFB;
@property (strong, nonatomic) NSDictionary *event;
@property (strong, nonatomic) NSDate *endDate;

@property (assign, nonatomic) int levelRoot;
@property (assign, nonatomic) BOOL isLoadingFromPhone;
@property (assign, nonatomic) BOOL isLoadingFromFB;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *validateButton;


- (IBAction)finishImport:(UIBarButtonItem *)sender;

@end

//
//  UploadFilesAutomaticViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 25/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface UploadFilesAutomaticViewController : UIViewController

@property (strong, nonatomic) NSArray *photosToUpload;
@property (strong, nonatomic) PFObject *event;
@property (assign, nonatomic) int nbOfPhotosUploaded;

@property (weak, nonatomic) IBOutlet UILabel *nbPhotosLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progessView;

@property (assign, nonatomic) int levelRoot;
@end

//
//  CameraViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 13/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomBadge.h"


@interface CameraViewController : UIViewController //<PhotosAlbumSelectionViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIButton *switchCamera;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIButton *takePhoto;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UIView *toolboxView;
@property (weak, nonatomic) IBOutlet UIImageView *flashIcon;
@property (strong, nonatomic) UIImage *takenImage;
@property (strong, nonatomic) PFObject *event;

@property (strong, nonatomic) UIView *camFocus;

@property (strong, nonatomic) NSURL *assetUrl;
@property (weak, nonatomic) IBOutlet UIButton *albumButton;
@property (weak, nonatomic) IBOutlet CustomBadge *badge;

- (IBAction)cancel:(UIButton *)sender;
- (IBAction)takePhoto:(UIButton *)sender;
- (IBAction)switchFlashMode:(UIButton *)sender;
- (IBAction)switchCamera:(UIButton *)sender;
@end

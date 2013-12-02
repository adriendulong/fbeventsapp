//
//  CameraViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 13/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomBadge.h"


@interface CameraViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *switchCamera;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIButton *takePhoto;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UILabel *labelFlash;
@property (strong, nonatomic) UIImage *takenImage;
@property (strong, nonatomic) PFObject *event;

@property (strong, nonatomic) NSURL *assetUrl;
@property (weak, nonatomic) IBOutlet UIButton *albumButton;
@property (weak, nonatomic) IBOutlet CustomBadge *badge;

- (IBAction)cancel:(id)sender;
- (IBAction)takePhoto:(id)sender;
- (IBAction)switchFlashMode:(id)sender;
- (IBAction)switchCamera:(id)sender;
@end

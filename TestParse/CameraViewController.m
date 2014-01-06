//
//  CameraViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 13/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "CameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SharePhotoViewController.h"
#import "MOUtility.h"
#import "PhotosAlbumViewController.h"
#import "CameraFocusSquare.h"
#import <AudioToolbox/AudioToolbox.h>

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@interface CameraViewController (){
    @private
    int photosMatched;
    BOOL flashMenuOpen;
}

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) UIImageView *pictureShowing;
@property (nonatomic) BOOL isPictureTaken;

@property (nonatomic, strong) NSArray *photosToUpload;

@property (strong, nonatomic) UIButton *yesButton;
@property (strong, nonatomic) UIButton *noButton;

@property (nonatomic) SystemSoundID soundToPlay;

@end

@implementation CameraViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    
    self.badge.hidden = YES;

    
    self.isPictureTaken = NO;
    photosMatched = 0;
    flashMenuOpen = NO;
    
    CALayer *imageLayer = self.albumButton.layer;
    [imageLayer setCornerRadius:25];
    [imageLayer setMasksToBounds:YES];
    
    [self setLatestPhotoOnAlbumButton];
    [self getCountPhotosMatchedWithEventDate];
}

-(void)viewWillAppear:(BOOL)animated{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:@"Camera View"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    if (!IS_IPHONE_5) {
        [self.navigationController setNavigationBarHidden:YES];
        self.toolboxView.alpha = 1.0;
    }
    
    //init
    self.title = NSLocalizedString(@"CameraViewController_Title", nil);
    
}

-(void)viewDidAppear:(BOOL)animated{
    if (self.session==nil) {
        [self activeCameraWithPosition:AVCaptureDevicePositionBack];
    }
    else if (!self.session.isRunning) {
        [self.session startRunning];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Camera 
- (void)activeCameraWithPosition:(AVCaptureDevicePosition)position
{
    self.session = [[AVCaptureSession alloc] init];
    //session.sessionPreset = AVCaptureSessionPresetMedium;
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //captureVideoPreviewLayer.bounds = bounds;
    //captureVideoPreviewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    captureVideoPreviewLayer.frame = self.cameraView.bounds;
    [self.cameraView.layer addSublayer:captureVideoPreviewLayer];
    
    UIView *view = [self cameraView];
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    
    CGRect bounds = [view bounds];
    [captureVideoPreviewLayer setFrame:bounds];
    
    
    self.device = (position == AVCaptureDevicePositionBack) ? [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] : [self frontCamera];
    /*if ([self.device hasFlash]){
        [self.device lockForConfiguration:nil];
        [self.device setFlashMode:AVCaptureFlashModeOff];
        [self.device unlockForConfiguration];
        self.labelFlash.text = @"Off";
    }*/
    
    if (![self.device hasFlash]) {
        self.flashIcon.hidden = YES;
        self.flashButton.hidden = YES;
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    if (!input)
    {
        //[Utilities alertDisplay:@"Error" message:@"Camera not found. Please use Photo Gallery instead."];
        NSLog(@"Camera not found. Please use Photo Gallery instead.");
    }
    
    [self.session addInput:input];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    [self.session addOutput:self.stillImageOutput];
    
    [self.session startRunning];
}

- (AVCaptureDevice *)frontCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}


- (IBAction)cancel:(UIButton *)sender {
    if (self.isPictureTaken) {
        self.toolboxView.alpha = 0.80;
        [self.previewImage setHidden:YES];
        self.isPictureTaken = NO;
        [self.takePhoto setImage:[UIImage imageNamed:@"btn_photo"] forState:UIControlStateNormal];
        [self.cancelButton setImage:[UIImage imageNamed:@"btn_cancel"] forState:UIControlStateNormal];
    } else {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (IBAction)takePhoto:(UIButton *)sender {
    
    if (!self.isPictureTaken) {
        
        [self.top_camera_shutter setHidden:NO];
        [self.bottom_camera_shutter setHidden:NO];
        
        self.toolboxView.alpha = 1.0;
        
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"shutter-photo" ofType:@"caf"];
        NSURL *soundPathURL = [NSURL fileURLWithPath:soundPath];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundPathURL, &_soundToPlay);
        AudioServicesPlaySystemSound(_soundToPlay);
        
        // ANIMATION
        [UIView animateWithDuration:0.375f
                         animations:^{
                             
                             CGRect frameTop = self.top_camera_shutter.frame;
                             frameTop.origin.y += 162.0f;
                             self.top_camera_shutter.frame = frameTop;
                             
                             CGRect frameBot = self.bottom_camera_shutter.frame;
                             frameBot.origin.y -= 160.0f;
                             self.bottom_camera_shutter.frame = frameBot;
                             
                         } completion:^(BOOL finished) {
                             
                             [UIView animateWithDuration:0.375f
                                                   delay:0.9f
                                                 options:UIViewAnimationOptionTransitionNone
                                              animations:^{
                                                  
                                                  CGRect frameTop = self.top_camera_shutter.frame;
                                                  frameTop.origin.y -= 162.0f;
                                                  self.top_camera_shutter.frame = frameTop;
                                                  
                                                  CGRect frameBot = self.bottom_camera_shutter.frame;
                                                  frameBot.origin.y += 160.0f;
                                                  self.bottom_camera_shutter.frame = frameBot;
                                                  
                                              } completion:^(BOOL finished) {
                                                  
                                                  if (finished) {
                                                      [self.top_camera_shutter setHidden:YES];
                                                      [self.bottom_camera_shutter setHidden:YES];
                                                  }
                                              }];
                         }];
        
        
        AVCaptureConnection *videoConnection = nil;
        for (AVCaptureConnection *connection in self.stillImageOutput.connections)
        {
            for (AVCaptureInputPort *port in [connection inputPorts])
            {
                if ([[port mediaType] isEqual:AVMediaTypeVideo] )
                {
                    videoConnection = connection;
                    break;
                }
            }
            if (videoConnection) { break; }
        }
        
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
         {
             
             
             
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             UIImage *image = [[UIImage alloc] initWithData:imageData];
             
             UIGraphicsBeginImageContext(CGSizeMake(960, 1278));
             [image drawInRect: CGRectMake(0, 0, 960, 1278)];
             UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
             UIGraphicsEndImageContext();
             
             CGRect cropRect = CGRectMake(0, 229, 960, 960);
             CGImageRef imageRef = CGImageCreateWithImageInRect([smallImage CGImage], cropRect);
             
             UIImage *finalImage = [UIImage imageWithCGImage:imageRef
                                                       scale:1.0
                                                 orientation:UIImageOrientationUp];
             [self.previewImage setImage:finalImage];
             
             
             
             //Graphical modifs
             [self.previewImage setHidden:NO];
             [self.takePhoto setImage:[UIImage imageNamed:@"validate_photo"] forState:UIControlStateNormal];
             [self.cancelButton setImage:[UIImage imageNamed:@"back_stream"] forState:UIControlStateNormal];
             self.isPictureTaken = YES;
             //Save locally
             self.takenImage = finalImage;

             CGImageRelease(imageRef);
             
             
             
             
         }];
    }
    else{
        //Go to the next screen
        [self performSegueWithIdentifier:@"PhotoValidate" sender:nil];
    }
    
    
    
}

- (void)openFlashMenu
{
    // YES BUTTON
    self.yesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.yesButton.tag = 1;
    [self.yesButton addTarget:self
                       action:@selector(switchFlashMode:)
             forControlEvents:UIControlEventTouchDown];
    [self.yesButton setTitle:NSLocalizedString(@"CameraViewController_Yes", nil) forState:UIControlStateNormal];
    self.yesButton.titleLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:13];
    self.yesButton.frame = CGRectMake(self.flashButton.frame.origin.x+45, self.flashButton.frame.origin.y, self.flashButton.frame.size.width, self.flashButton.frame.size.height);
    [self.view addSubview:self.yesButton];
    
    
    // NO BUTTON
    self.noButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.noButton.tag = 2;
    [self.noButton addTarget:self
                      action:@selector(switchFlashMode:)
            forControlEvents:UIControlEventTouchDown];
    [self.noButton setTitle:NSLocalizedString(@"CameraViewController_No", nil) forState:UIControlStateNormal];
    self.noButton.titleLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:13];
    self.noButton.frame = CGRectMake(self.yesButton.frame.origin.x+45, self.yesButton.frame.origin.y, self.yesButton.frame.size.width, self.yesButton.frame.size.height);
    [self.view addSubview:self.noButton];
    
    
    // ANIMATION
    [UIView animateWithDuration:0.16f
                     animations:^{
                         
                         [self.yesButton.layer addAnimation:[self fadeAnimationToOpen:YES]
                                                     forKey:@"animateOpacity"];
                         [self.noButton.layer addAnimation:[self fadeAnimationToOpen:YES]
                                                    forKey:@"animateOpacity"];
                         
                         
                         self.yesButton.frame = CGRectMake(self.yesButton.frame.origin.x+20, self.yesButton.frame.origin.y, self.yesButton.frame.size.width, self.yesButton.frame.size.height);
                         self.noButton.frame = CGRectMake(self.noButton.frame.origin.x+40, self.noButton.frame.origin.y, self.noButton.frame.size.width, self.noButton.frame.size.height);
                         
                     } completion:nil];
    
    flashMenuOpen = YES;
}

- (void)closeFlashMenu
{
    
    [UIView animateWithDuration:0.16f
                     animations:^{
                         
                         [self.yesButton.layer addAnimation:[self fadeAnimationToOpen:NO]
                                                     forKey:@"animateOpacity"];
                         [self.noButton.layer addAnimation:[self fadeAnimationToOpen:NO]
                                                    forKey:@"animateOpacity"];
                         
                         self.yesButton.frame = CGRectMake(self.yesButton.frame.origin.x-20, self.yesButton.frame.origin.y, self.yesButton.frame.size.width, self.yesButton.frame.size.height);
                         self.noButton.frame = CGRectMake(self.noButton.frame.origin.x-40, self.noButton.frame.origin.y, self.noButton.frame.size.width, self.noButton.frame.size.height);
                         
                         
                         self.yesButton.alpha = 0.0;
                         self.noButton.alpha = 0.0;
                         
                     } completion:^(BOOL finished) {
                         [self.yesButton removeFromSuperview];
                         [self.noButton removeFromSuperview];
                     }];
    
    //[self.yesButton removeFromSuperview];
    //[self.noButton removeFromSuperview];
    
    flashMenuOpen = NO;
}

- (IBAction)switchFlashMode:(UIButton *)sender
{
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasFlash]) {
        
        
        [device lockForConfiguration:nil];
        
        
        if (flashMenuOpen) {
            [self closeFlashMenu];
        } else {
            [self openFlashMenu];
        }
        
        
        switch (sender.tag) {
            default:
            case 0: {
                [self.flashButton setTitle:NSLocalizedString(@"CameraViewController_Auto", nil) forState:UIControlStateNormal];
                [device setFlashMode:AVCaptureFlashModeAuto];
                break;
            }
                
            case 1: {
                [self.flashButton setTitle:NSLocalizedString(@"CameraViewController_Yes", nil) forState:UIControlStateNormal];
                [device setFlashMode:AVCaptureFlashModeOn];
                break;
            }
                
            case 2: {
                [self.flashButton setTitle:NSLocalizedString(@"CameraViewController_No", nil) forState:UIControlStateNormal];
                [device setFlashMode:AVCaptureFlashModeOff];
                break;
            }
        }
        
        [device unlockForConfiguration];
    }
}

- (IBAction)switchCamera:(UIButton *)sender
{
    
    NSIndexSet *indexSet = [self.cameraView.layer.sublayers indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
        return [obj isMemberOfClass:[AVCaptureVideoPreviewLayer class]];
    }];
    
    NSArray *cameraLayers = [self.cameraView.layer.sublayers objectsAtIndexes:indexSet];
    for (AVCaptureVideoPreviewLayer *cameraLayer in cameraLayers) {
        [cameraLayer removeFromSuperlayer];
    }
    
    switch (self.device.position) {
        case AVCaptureDevicePositionBack:
            if( [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront ])
            {
                
                if (flashMenuOpen) {
                    [self closeFlashMenu];
                }
                
                [UIView animateWithDuration:0.16f
                                 animations:^{
                                     
                                     [self.flashIcon.layer addAnimation:[self fadeAnimationToOpen:NO]
                                                                 forKey:@"animateOpacity"];
                                     [self.flashButton.layer addAnimation:[self fadeAnimationToOpen:NO]
                                                                   forKey:@"animateOpacity"];
                                     
                                     
                                     self.flashIcon.alpha = 0.0;
                                     self.flashButton.alpha = 0.0;
                                     
                                 } completion:^(BOOL finished) {
                                     
                                     if (finished) {
                                         self.flashIcon.hidden = YES;
                                         self.flashButton.hidden = YES;
                                     }
                                 }];
                
                [self activeCameraWithPosition:AVCaptureDevicePositionFront];
                
            }
            break;
            
        case AVCaptureDevicePositionFront:
            if( [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear ])
            {
                
                [UIView animateWithDuration:0.16f
                                 animations:^{
                                     
                                     [self.flashIcon.layer addAnimation:[self fadeAnimationToOpen:YES]
                                                                 forKey:@"animateOpacity"];
                                     [self.flashButton.layer addAnimation:[self fadeAnimationToOpen:YES]
                                                                   forKey:@"animateOpacity"];
                                     
                                     
                                     self.flashIcon.alpha = 1.0;
                                     self.flashButton.alpha = 1.0;
                                     
                                 } completion:^(BOOL finished) {
                                     
                                     if (finished) {
                                         self.flashIcon.hidden = NO;
                                         self.flashButton.hidden = NO;
                                     }
                                 }];
                
                [self activeCameraWithPosition:AVCaptureDevicePositionBack];
                
            }
            break;
            
        default:
        case AVCaptureDevicePositionUnspecified:
            break;
    }
}



#pragma mark - Work on Album

- (void)setLatestPhotoOnAlbumButton
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        if (group.numberOfAssets > 0) {
            
            [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:group.numberOfAssets-1] options:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                
                if (result) {
                    CGImageRef representation = [result thumbnail];
                    UIImage *latestPhoto = [UIImage imageWithCGImage:representation];
                    
                    [self.albumButton setImage:latestPhoto forState:UIControlStateNormal];
                    
                    latestPhoto = nil;
                }
            }];
        }
    } failureBlock: ^(NSError *error) {
    }];
}


- (void)getCountPhotosMatchedWithEventDate
{
    NSDate *startDate = [(NSDate *)self.event[@"start_time"] dateByAddingTimeInterval:-6*3600];
    NSDate *endDate = [MOUtility getEndDateEvent:self.event];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        @autoreleasepool {
            if (group) {
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    if (result) {
                        
                        NSDate *photoDate = (NSDate *)[result valueForProperty:ALAssetPropertyDate];
                        
                        if (startDate && endDate) {
                            
                            if ([MOUtility date:photoDate isBetweenDate:startDate andDate:endDate]) {
                                
                                photosMatched++;
                            }
                            
                        }
                        
                        if (photosMatched > 0) {
                            self.badge.hidden = NO;
                            [self.badge updateBadgeWithNumber:photosMatched];
                        }
                    }
                }];
            }
        }
        
    } failureBlock:^(NSError *error) {
    }];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [self.navigationController setNavigationBarHidden:NO];
    
    if ([segue.identifier isEqualToString:@"PhotoValidate"]) {
        
        
        //Remove image preview from this screen if come back
        [self.previewImage setHidden:YES];
        self.isPictureTaken = NO;
        [self.takePhoto setImage:[UIImage imageNamed:@"btn_photo"] forState:UIControlStateNormal];
        [self.cancelButton setImage:[UIImage imageNamed:@"btn_cancel"] forState:UIControlStateNormal];
        
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
        
        SharePhotoViewController *photosCollectionViewController = segue.destinationViewController;
        photosCollectionViewController.takenPhoto = self.takenImage;
        photosCollectionViewController.event = self.event;
    }
    else if ([segue.identifier isEqualToString:@"PhotosAlbum"]) {
        
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
        
        PhotosAlbumViewController *photosAlbums = segue.destinationViewController;
        photosAlbums.event = self.event;
        photosAlbums.nbAutomaticPhotos = photosMatched;
    }
}

#pragma mark - Photo Focus

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchPoint = [touch locationInView:self.cameraView];
    [self focus:touchPoint];
    
    if (self.camFocus)
    {
        [self.camFocus removeFromSuperview];
    }
    if ([touch.view isEqual:self.cameraView])
    {
        self.camFocus = [[CameraFocusSquare alloc] initWithFrame:CGRectMake(touchPoint.x-40, touchPoint.y-40, 80, 80)];
        [self.camFocus setBackgroundColor:[UIColor clearColor]];
        [self.cameraView addSubview:self.camFocus];
        [self.camFocus setNeedsDisplay];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:1.5];
        [self.camFocus setAlpha:0.0];
        [UIView commitAnimations];
    }
}

- (void)focus:(CGPoint)aPoint;
{
    if ([self.device isKindOfClass:[AVCaptureDevice class]]) {
        
        if([self.device isFocusPointOfInterestSupported] &&
           [self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            
            CGRect screenRect = self.cameraView.frame;
            double screenWidth = screenRect.size.width;
            double screenHeight = screenRect.size.height;
            double focus_x = aPoint.x/screenWidth;
            double focus_y = aPoint.y/screenHeight;
            if ([self.device lockForConfiguration:nil]) {
                [self.device setFocusPointOfInterest:CGPointMake(focus_x,focus_y)];
                [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
                if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose]){
                    [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
                }
                /*if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                    [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
                }*/
                [self.device unlockForConfiguration];
            }
        }
    }
}

#pragma mark - Animations

- (CABasicAnimation *)fadeAnimationToOpen:(BOOL)isOpened
{
    CABasicAnimation *theAnimation;
    
    theAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    theAnimation.duration = 0.15;
    
    if (isOpened) {
        theAnimation.fromValue = [NSNumber numberWithFloat:0.0];
        theAnimation.toValue = [NSNumber numberWithFloat:1.0];
    } else {
        theAnimation.fromValue = [NSNumber numberWithFloat:1.0];
        theAnimation.toValue = [NSNumber numberWithFloat:0.0];
    }
    
    return theAnimation;
}


@end

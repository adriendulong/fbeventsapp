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
//#import "UIImage+Resize.h"

@interface CameraViewController ()

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) UIImageView *pictureShowing;
@property (nonatomic) BOOL isPictureTaken;

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
    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
    [self activeCameraWithPosition:AVCaptureDevicePositionBack];
    
    self.isPictureTaken = NO;
}

-(void)viewWillAppear:(BOOL)animated{
    if (!self.session.isRunning) {
        [self.session startRunning];
    }
    NSLog(@"APPEAR COUCOU");
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
    NSLog(@"CREATE FLUX");
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
    
    NSLog(@"Position = %d", position);
    
    self.device = (position == AVCaptureDevicePositionBack) ? [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] : [self frontCamera];
    if ([self.device hasFlash]){
        [self.device lockForConfiguration:nil];
        [self.device setFlashMode:AVCaptureFlashModeOff];
        [self.device unlockForConfiguration];
        self.labelFlash.text = @"Off";
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


- (IBAction)cancel:(id)sender {
    if (self.isPictureTaken) {
        [self.previewImage setHidden:YES];
        self.isPictureTaken = NO;
        [self.takePhoto setImage:[UIImage imageNamed:@"btn_photo"] forState:UIControlStateNormal];
        [self.cancelButton setImage:[UIImage imageNamed:@"btn_cancel"] forState:UIControlStateNormal];
    } else {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (IBAction)takePhoto:(id)sender {
    
    if (!self.isPictureTaken) {
        AVCaptureConnection *videoConnection = nil;
        for (AVCaptureConnection *connection in self.stillImageOutput.connections)
        {
            for (AVCaptureInputPort *port in [connection inputPorts])
            {
                //NSLog(@"port = %@", port.mediaType);
                if ([[port mediaType] isEqual:AVMediaTypeVideo] )
                {
                    videoConnection = connection;
                    break;
                }
            }
            if (videoConnection) { break; }
        }
        
        NSLog(@"about to request a capture from: %@", self.stillImageOutput);
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
         {
             /*CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
              if (exifAttachments)
              {
              // Do something with the attachments.
              NSLog(@"attachements: %@", exifAttachments);
              }
              else
              NSLog(@"no attachments");*/
             
             
             
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             UIImage *image = [[UIImage alloc] initWithData:imageData];
             
             NSLog(@"Width %f, Height %f", image.size.width, image.size.height);
             
             UIGraphicsBeginImageContext(CGSizeMake(960, 1278));
             [image drawInRect: CGRectMake(0, 0, 960, 1278)];
             UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
             UIGraphicsEndImageContext();
             
             CGRect cropRect = CGRectMake(0, 229, 960, 960);
             CGImageRef imageRef = CGImageCreateWithImageInRect([smallImage CGImage], cropRect);
             
             UIImage *finalImage = [UIImage imageWithCGImage:imageRef
                                                       scale:1.0
                                                 orientation: UIImageOrientationUp];
             [self.previewImage setImage:finalImage];
             
             
             
             /*
              imageData = nil;
              
              UIImage *tempImage = nil;
              CGSize targetSize = CGSizeMake(600,600);
              UIGraphicsBeginImageContext(targetSize);
              
              CGRect thumbnailRect = CGRectMake(0, 0, 0, 0);
              thumbnailRect.origin = CGPointMake(0.0,0.0);
              thumbnailRect.size.width  = targetSize.width;
              thumbnailRect.size.height = targetSize.height;
              
              [image drawInRect:thumbnailRect];
              
              tempImage = UIGraphicsGetImageFromCurrentImageContext();
              
              UIGraphicsEndImageContext();*/
             
             /*if (exifAttachments)
              exifAttachments = nil;*/
             
             // Resize the image from the camera
             /*UIImage *scaledImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
              bounds:CGSizeMake(600, 600)
              interpolationQuality:kCGInterpolationHigh];*/
             // Crop the image to a square (yikes, fancy!)
             //UIImage *croppedImage = [scaledImage croppedImage:CGRectMake((scaledImage.size.width -photo.frame.size.width)/2, (scaledImage.size.height -photo.frame.size.height)/2, photo.frame.size.width, photo.frame.size.height)];
             //UIImage *croppedImage = [image croppedImage:CGRectMake((scaledImage.size.width - self.frame.size.width)/2, (scaledImage.size.height - photo.frame.size.height)/2, photo.frame.size.width, photo.frame.size.height)];
             
             /*self.pictureShowing = [[UIImageView alloc] initWithImage:tempImage];
              self.pictureShowing.frame = self.cameraView.frame;
              [self.cameraView addSubview:self.pictureShowing];*/
             //self.previewImage.image = tempImage;
             
             //Graphical modifs
             [self.previewImage setHidden:NO];
             [self.takePhoto setImage:[UIImage imageNamed:@"validate_photo"] forState:UIControlStateNormal];
             [self.cancelButton setImage:[UIImage imageNamed:@"back_stream"] forState:UIControlStateNormal];
             self.isPictureTaken = YES;
             //Save locally
             self.takenImage = finalImage;
             
             NSLog(@"Image rotation %d", [finalImage imageOrientation]);
             
             /*
             ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
             [library writeImageToSavedPhotosAlbum:imageRef
                                       orientation:(ALAssetOrientation)[finalImage imageOrientation]
                                   completionBlock:^(NSURL *assetURL, NSError *error) {
                                       if (error) {
                                           //[self displayErrorOnMainQueue:error withMessage:@"Save to camera roll failed"];
                                           
                                       } else {
                                           
                                           self.assetUrl = assetURL;
                                           NSLog(@"self.assetUrl = %@", self.assetUrl.absoluteString);
                                       }
                                   }];*/
             CGImageRelease(imageRef);
             
             
             
             
         }];
    }
    else{
        //Go to the next screen
        [self performSegueWithIdentifier:@"PhotoValidate" sender:nil];
    }
    
    
    
}

- (IBAction)switchFlashMode:(id)sender {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasFlash]){
        
        [device lockForConfiguration:nil];
        if (device.flashMode == AVCaptureFlashModeOn) {
            [device setFlashMode:AVCaptureFlashModeAuto];
            self.labelFlash.text = @"Auto";
        } else if(device.flashMode == AVCaptureFlashModeOff) {
            [device setFlashMode:AVCaptureFlashModeOn];
            self.labelFlash.text = @"On";
        }
        else{
            [device setFlashMode:AVCaptureFlashModeOff];
            self.labelFlash.text = @"Off";
        }
        [device unlockForConfiguration];
    }
}

- (IBAction)switchCamera:(id)sender {
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
                NSLog(@"On est avec celle de derrière. On active celle de devant !");
                [self activeCameraWithPosition:AVCaptureDevicePositionFront];
            }
            break;
            
        case AVCaptureDevicePositionFront:
            if( [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear ])
            {
                NSLog(@"On est avec celle de devant. On active celle de derrière !");
                [self activeCameraWithPosition:AVCaptureDevicePositionBack];
            }
            break;
            
        default:
        case AVCaptureDevicePositionUnspecified:
            break;
    }
}



#pragma mark - Work on Image
/*
- (void) processImage:(UIImage *)image { //process captured image, crop, resize and rotate
    haveImage = YES;
    
    if([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) { //Device is ipad
        // Resize image
        UIGraphicsBeginImageContext(CGSizeMake(768, 1022));
        [image drawInRect: CGRectMake(0, 0, 768, 1022)];
        UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CGRect cropRect = CGRectMake(0, 130, 768, 768);
        CGImageRef imageRef = CGImageCreateWithImageInRect([smallImage CGImage], cropRect);
        //or use the UIImage wherever you like
        
        [captureImage setImage:[UIImage imageWithCGImage:imageRef]];
        
        CGImageRelease(imageRef);
        
    }else{ //Device is iphone
        // Resize image
        UIGraphicsBeginImageContext(CGSizeMake(320, 426));
        [image drawInRect: CGRectMake(0, 0, 320, 426)];
        UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CGRect cropRect = CGRectMake(0, 55, 320, 320);
        CGImageRef imageRef = CGImageCreateWithImageInRect([smallImage CGImage], cropRect);
        
        [captureImage setImage:[UIImage imageWithCGImage:imageRef]];
        
        CGImageRelease(imageRef);
    }
    
    //adjust image orientation based on device orientation
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) {
        NSLog(@"landscape left image");
        
        [UIView beginAnimations:@"rotate" context:nil];
        [UIView setAnimationDuration:0.5];
        captureImage.transform = CGAffineTransformMakeRotation(DegreesToRadians(-90));
        [UIView commitAnimations];
        
    }
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        NSLog(@"landscape right");
        
        [UIView beginAnimations:@"rotate" context:nil];
        [UIView setAnimationDuration:0.5];
        captureImage.transform = CGAffineTransformMakeRotation(DegreesToRadians(90));
        [UIView commitAnimations];
        
    }
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) {
        NSLog(@"upside down");
        [UIView beginAnimations:@"rotate" context:nil];
        [UIView setAnimationDuration:0.5];
        captureImage.transform = CGAffineTransformMakeRotation(DegreesToRadians(180));
        [UIView commitAnimations];
        
    }
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait) {
        NSLog(@"upside upright");
        [UIView beginAnimations:@"rotate" context:nil];
        [UIView setAnimationDuration:0.5];
        captureImage.transform = CGAffineTransformMakeRotation(DegreesToRadians(0));
        [UIView commitAnimations];
    }    
}
 
 
 - (UIImage *)fixOrientation {
 
 // No-op if the orientation is already correct
 if (self.imageOrientation == UIImageOrientationUp) return self;
 
 // We need to calculate the proper transformation to make the image upright.
 // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
 CGAffineTransform transform = CGAffineTransformIdentity;
 
 switch (self.imageOrientation) {
 case UIImageOrientationDown:
 case UIImageOrientationDownMirrored:
 transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
 transform = CGAffineTransformRotate(transform, M_PI);
 break;
 
 case UIImageOrientationLeft:
 case UIImageOrientationLeftMirrored:
 transform = CGAffineTransformTranslate(transform, self.size.width, 0);
 transform = CGAffineTransformRotate(transform, M_PI_2);
 break;
 
 case UIImageOrientationRight:
 case UIImageOrientationRightMirrored:
 transform = CGAffineTransformTranslate(transform, 0, self.size.height);
 transform = CGAffineTransformRotate(transform, -M_PI_2);
 break;
 case UIImageOrientationUp:
 case UIImageOrientationUpMirrored:
 break;
 }
 
 switch (self.imageOrientation) {
 case UIImageOrientationUpMirrored:
 case UIImageOrientationDownMirrored:
 transform = CGAffineTransformTranslate(transform, self.size.width, 0);
 transform = CGAffineTransformScale(transform, -1, 1);
 break;
 
 case UIImageOrientationLeftMirrored:
 case UIImageOrientationRightMirrored:
 transform = CGAffineTransformTranslate(transform, self.size.height, 0);
 transform = CGAffineTransformScale(transform, -1, 1);
 break;
 case UIImageOrientationUp:
 case UIImageOrientationDown:
 case UIImageOrientationLeft:
 case UIImageOrientationRight:
 break;
 }
 
 // Now we draw the underlying CGImage into a new context, applying the transform
 // calculated above.
 CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
 CGImageGetBitsPerComponent(self.CGImage), 0,
 CGImageGetColorSpace(self.CGImage),
 CGImageGetBitmapInfo(self.CGImage));
 CGContextConcatCTM(ctx, transform);
 switch (self.imageOrientation) {
 case UIImageOrientationLeft:
 case UIImageOrientationLeftMirrored:
 case UIImageOrientationRight:
 case UIImageOrientationRightMirrored:
 // Grr...
 CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
 break;
 
 default:
 CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
 break;
 }
 
 // And now we just create a new UIImage from the drawing context
 CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
 UIImage *img = [UIImage imageWithCGImage:cgimg];
 CGContextRelease(ctx);
 CGImageRelease(cgimg);
 return img;
 }
 */


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
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
}

@end

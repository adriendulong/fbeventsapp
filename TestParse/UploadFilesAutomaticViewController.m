//
//  UploadFilesAutomaticViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 25/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "UploadFilesAutomaticViewController.h"
#import "Photo.h"
#import "PhotosCollectionViewController.h"
#import "MOUtility.h"
#import "UIImage+ResizeAdditions.h"

@interface UploadFilesAutomaticViewController ()

@end

@implementation UploadFilesAutomaticViewController

-(void)viewWillAppear:(BOOL)animated{
    self.labelMarmotte.text = NSLocalizedString(@"UploadFilesAutomaticViewController_TextMarmotte", nil);
}

-(void)viewDidAppear:(BOOL)animated{
    [self uploadPhotos];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"UploadFilesAutomaticViewController_Title", nil);
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    NSLog(@"NOMBre de photos : %i", [self.photosToUpload count]);
    self.nbOfPhotosUploaded = 0;
    self.photosReallyUploaded = 0;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.progessView setProgress:0.0f];
    self.nbPhotosLabel.text = [NSString stringWithFormat:NSLocalizedString(@"UploadFilesAutomaticViewController_PhotosCount", nil), 0, self.photosToUpload.count];
    
    
    //Go marmote
    self.counterTimer = 0;
    self.marmoteTimer = [NSTimer scheduledTimerWithTimeInterval:0.3  target:self selector:@selector(actionTimer) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)uploadPhotos{
    
    
    Photo *photoToUpload = [self.photosToUpload objectAtIndex:self.nbOfPhotosUploaded];
    
    //Photo Facebook
    if (photoToUpload.facebookId) {
        self.percentIndicator.text = @"100%";
        
        
        PFQuery *queryFacebookPhoto = [PFQuery queryWithClassName:@"Photo"];
        [queryFacebookPhoto whereKey:@"facebookId" equalTo:photoToUpload.facebookId];
        [queryFacebookPhoto whereKey:@"event" equalTo:self.event];
        [queryFacebookPhoto getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                NSLog(@"Already exist for this evenet, don't upload");
                self.nbOfPhotosUploaded++;
                
                self.nbPhotosLabel.text = [NSString stringWithFormat:NSLocalizedString(@"UploadFilesAutomaticViewController_PhotosCount", nil), self.nbOfPhotosUploaded, self.photosToUpload.count];
                [self.progessView setProgress:1];
                
                if (self.nbOfPhotosUploaded<self.photosToUpload.count) {
                    [self uploadPhotos];
                }
                else{
                    [self finishedUpload];
                }
            }
            
            //The photos does not exixt for this event, we save it
            else if(error && error.code == kPFErrorObjectNotFound){
                if (photoToUpload.ownerPhoto) {
                    PFObject *photoServer = [PFObject objectWithClassName:@"Photo"];
                    photoServer[@"user"] = photoToUpload.ownerPhoto;
                    photoServer[@"event"] = self.event;
                    photoServer[@"facebookId"] = photoToUpload.facebookId;
                    photoServer[@"facebook_url_full"] = photoToUpload.sourceUrl;
                    photoServer[@"facebook_url_low"] = photoToUpload.pictureUrl;
                    photoServer[@"created_time"] = photoToUpload.date;
                    photoServer[@"width"] = photoToUpload.width;
                    photoServer[@"height"] = photoToUpload.height;
                    
                    [photoServer saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        self.nbOfPhotosUploaded++;
                        self.photosReallyUploaded ++;
                        
                        self.nbPhotosLabel.text = [NSString stringWithFormat:NSLocalizedString(@"UploadFilesAutomaticViewController_PhotosCount", nil), self.nbOfPhotosUploaded, self.photosToUpload.count];
                        [self.progessView setProgress:(float)(self.nbOfPhotosUploaded/self.photosToUpload.count)];
                        
                        if (self.nbOfPhotosUploaded<self.photosToUpload.count) {
                            [self uploadPhotos];
                        }
                        else{
                            [self finishedUpload];
                        }
                    }];
                }
                else{
                    //We see if a user exists in order to associate him with the photo
                    PFQuery *queryUser = [PFUser query];
                    [queryUser whereKey:@"facebookId" equalTo:photoToUpload.userId];
                    [queryUser getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                        if (!error) {
                            NSLog(@"UN USER !");
                            
                            //WE HAVE A USER //
                            //////////////////
                            
                            PFObject *photoServer = [PFObject objectWithClassName:@"Photo"];
                            photoServer[@"user"] = object;
                            photoServer[@"event"] = self.event;
                            photoServer[@"facebookId"] = photoToUpload.facebookId;
                            photoServer[@"facebook_url_full"] = photoToUpload.sourceUrl;
                            photoServer[@"facebook_url_low"] = photoToUpload.pictureUrl;
                            photoServer[@"created_time"] = photoToUpload.date;
                            photoServer[@"width"] = photoToUpload.width;
                            photoServer[@"height"] = photoToUpload.height;
                            
                            [photoServer saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                self.nbOfPhotosUploaded++;
                                self.photosReallyUploaded ++;
                                
                                self.nbPhotosLabel.text = [NSString stringWithFormat:NSLocalizedString(@"UploadFilesAutomaticViewController_PhotosCount", nil), self.nbOfPhotosUploaded, self.photosToUpload.count];
                                [self.progessView setProgress:(float)(self.nbOfPhotosUploaded/self.photosToUpload.count)];
                                
                                if (self.nbOfPhotosUploaded<self.photosToUpload.count) {
                                    [self uploadPhotos];
                                }
                                else{
                                    [self finishedUpload];
                                }
                            }];
                            
                        }
                        else if(error && error.code == kPFErrorObjectNotFound){
                            
                            //See if there is a prospect
                            PFQuery *queryProspect = [PFQuery queryWithClassName:@"Prospect"];
                            [queryProspect whereKey:@"facebookId" equalTo:photoToUpload.userId];
                            [queryProspect getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                if (!error) {
                                    
                                    /// WE HAVE A PROSPECT ///
                                    //////////////////////////
                                    
                                    NSLog(@"UN PROSPECT");
                                    
                                    PFObject *photoServer = [PFObject objectWithClassName:@"Photo"];
                                    photoServer[@"prospect"] = object;
                                    photoServer[@"event"] = self.event;
                                    photoServer[@"facebookId"] = photoToUpload.facebookId;
                                    photoServer[@"facebook_url_full"] = photoToUpload.sourceUrl;
                                    photoServer[@"facebook_url_low"] = photoToUpload.pictureUrl;
                                    photoServer[@"created_time"] = photoToUpload.date;
                                    photoServer[@"width"] = photoToUpload.width;
                                    photoServer[@"height"] = photoToUpload.height;
                                    
                                    [photoServer saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                        self.nbOfPhotosUploaded++;
                                        self.photosReallyUploaded++;
                                        
                                        self.nbPhotosLabel.text = [NSString stringWithFormat:NSLocalizedString(@"UploadFilesAutomaticViewController_PhotosCount", nil), self.nbOfPhotosUploaded, self.photosToUpload.count];
                                        [self.progessView setProgress:1];
                                        
                                        if (self.nbOfPhotosUploaded<self.photosToUpload.count) {
                                            [self uploadPhotos];
                                        }
                                        else{
                                            [self finishedUpload];
                                        }
                                    }];
                                    
                                    
                                }
                                else if(error && error.code == kPFErrorObjectNotFound){
                                    //If no prospect create it
                                    PFObject *prospect = [PFObject objectWithClassName:@"Prospect"];
                                    prospect[@"facebookId"] = photoToUpload.userId;
                                    prospect[@"name"] = photoToUpload.userFBName;
                                    
                                    
                                    // CREATE A PROSPECT //
                                    ///////////////////////
                                    
                                    [prospect saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                        if (succeeded) {
                                            PFObject *photoServer = [PFObject objectWithClassName:@"Photo"];
                                            photoServer[@"prospect"] = prospect;
                                            photoServer[@"event"] = self.event;
                                            photoServer[@"facebookId"] = photoToUpload.facebookId;
                                            photoServer[@"facebook_url_full"] = photoToUpload.sourceUrl;
                                            photoServer[@"facebook_url_low"] = photoToUpload.pictureUrl;
                                            photoServer[@"created_time"] = photoToUpload.date;
                                            photoServer[@"width"] = photoToUpload.width;
                                            photoServer[@"height"] = photoToUpload.height;
                                            
                                            [photoServer saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                self.nbOfPhotosUploaded++;
                                                self.photosReallyUploaded++;
                                                
                                                self.nbPhotosLabel.text = [NSString stringWithFormat:NSLocalizedString(@"UploadFilesAutomaticViewController_PhotosCount", nil), self.nbOfPhotosUploaded, self.photosToUpload.count];
                                                [self.progessView setProgress:(float)(self.nbOfPhotosUploaded/self.photosToUpload.count)];
                                                
                                                if (self.nbOfPhotosUploaded<self.photosToUpload.count) {
                                                    [self uploadPhotos];
                                                }
                                                else{
                                                    [self finishedUpload];
                                                }
                                            }];
                                        }
                                    }];
                                    
                                    
                                }
                            }];
                        }
                    }];
                }

            }
        }];
        
    }
    else{
        
        self.nbOfPhotosUploaded++;

        //Thumbnail
        NSData *thumbnailImageData = UIImagePNGRepresentation(photoToUpload.thumbnail);
        PFFile *thumbnailFile = [PFFile fileWithData:thumbnailImageData];
        
        //Good quality photo
        [self getUIImageFromAssetURL:photoToUpload.assetUrl withEnded:^(UIImage *image) {
            UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:[MOUtility newBoundsForMaxSize:1000.0f andActualSize:image.size] interpolationQuality:kCGInterpolationHigh];
            NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.8f);
            
            
            __block float width = resizedImage.size.width;
            __block float height = resizedImage.size.height;
            PFFile *imageFile = [PFFile fileWithData:imageData];
            
            [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            NSLog(@"THumbnail Ok");
                            PFObject *eventPhoto = [PFObject objectWithClassName:@"Photo"];
                            eventPhoto[@"full_image"] = imageFile;
                            eventPhoto[@"low_image"] = thumbnailFile;
                            eventPhoto[@"width"] = [NSNumber numberWithFloat:width];;
                            eventPhoto[@"height"] = [NSNumber numberWithFloat:height];
                            eventPhoto[@"user"] = [PFUser currentUser];
                            eventPhoto[@"event"] = self.event;
                            [eventPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                if (succeeded) {
                                    self.photosReallyUploaded++;
                                }
                                
                                if (self.nbOfPhotosUploaded<self.photosToUpload.count) {
                                    [self uploadPhotos];
                                }
                                else{
                                    [self finishedUpload];
                                }
                            }];
                        }
                    }];
                    
                }
                else{
                    if (self.nbOfPhotosUploaded<self.photosToUpload.count) {
                        [self uploadPhotos];
                    }
                    else{
                        [self finishedUpload];
                    }
                }
            } progressBlock:^(int percentDone) {
                // Update your progress spinner here. percentDone will be between 0 and 100.
                self.percentIndicator.text = [NSString stringWithFormat:@"%i%%", percentDone];
                
                [self.progessView setProgress:(float)percentDone/100];
                self.nbPhotosLabel.text = [NSString stringWithFormat:NSLocalizedString(@"UploadFilesAutomaticViewController_PhotosCount", nil), self.nbOfPhotosUploaded, self.photosToUpload.count];
            }];
        }];
        
        
    }
    
    
}



- (void)getUIImageFromAssetURL:(NSURL *)assetUrl withEnded:(void (^) (UIImage *image) )block
{
    if (block) {
        
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary assetForURL:assetUrl resultBlock: ^(ALAsset *asset) {
            
            if (asset) {
                
                @autoreleasepool {
                    ALAssetRepresentation *representation = [asset defaultRepresentation];
                    CGImageRef fullResImage = representation.fullResolutionImage;
                    
                    NSString *adjustment = representation.metadata[@"AdjustmentXMP"];
                    
                    if (adjustment) {
                        NSData *xmpData = [adjustment dataUsingEncoding:NSUTF8StringEncoding];
                        CIImage *image = [CIImage imageWithCGImage:fullResImage];
                        
                        NSError *error = nil;
                        NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:xmpData
                                                                     inputImageExtent:image.extent
                                                                                error:&error];
                        CIContext *context = [CIContext contextWithOptions:nil];
                        if (filterArray && !error) {
                            for (CIFilter *filter in filterArray) {
                                [filter setValue:image forKey:kCIInputImageKey];
                                image = [filter outputImage];
                            }
                            fullResImage = [context createCGImage:image fromRect:[image extent]];
                        }
                    }
                    
                    
                    
                    UIImage *img = [UIImage imageWithCGImage:fullResImage
                                                       scale:representation.scale
                                                 orientation:(UIImageOrientation)representation.orientation];
                    
                    fullResImage = nil;
                    
                    //NSData *photoData = UIImageJPEGRepresentation(img, 0.8);

                    
                    block(img);
                }
            }
            
        } failureBlock:^(NSError *error) {
            NSLog(@"Error: %@", error.localizedDescription);
            
            block(nil);
        }];
    }
}


-(void)finishedUpload{
    [self.marmoteTimer invalidate];
    self.marmoteTimer = nil;
    
    [self pushEveryInvited:self.photosReallyUploaded];
    
    NSString *message;
    if (self.photosReallyUploaded>1) {
        message = [NSString stringWithFormat:NSLocalizedString(@"SharePhotoViewController_SharedPhoto2", nil), self.photosReallyUploaded];;
    }
    else{
        message = NSLocalizedString(@"SharePhotoViewController_SharedPhoto3", nil);
    }
    
    NSString *url = [NSString stringWithFormat:@"http://www.woovent.com/e/%@", self.event.objectId];
    [MOUtility postLinkOnFacebookEventWall:self.event[@"eventId"] withUrl:url withMessage:message];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UploadPhotoFinished object:self userInfo:nil];
    [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:self.levelRoot] animated:NO];
}

//Push notif
-(void)pushEveryInvited:(int)nbPhotos{
    [[Mixpanel sharedInstance] track:@"Photos Uploaded" properties:@{@"Nb Photos": [NSNumber numberWithInt:nbPhotos], @"From" : @"Auto Import"}];
    [PFCloud callFunctionInBackground:@"pushnewphotos" withParameters:@{@"nbphotos": [NSNumber numberWithInt:nbPhotos], @"eventid" : self.event.objectId} block:^(id object, NSError *error) {
        NSLog(@"Push sent");
    }];
}

-(void)actionTimer{
    if (self.counterTimer%3==0) {
        self.marmoteImage.image = [UIImage imageNamed:@"marmote1"];
    }
    else if(self.counterTimer%3==1){
        self.marmoteImage.image = [UIImage imageNamed:@"marmote2"];
    }
    else{
        self.marmoteImage.image = [UIImage imageNamed:@"marmote3"];
    }
    
    self.counterTimer++;

}



@end

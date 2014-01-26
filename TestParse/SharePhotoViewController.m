//
//  SharePhotoViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 14/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "SharePhotoViewController.h"
#import "UIImage+ResizeAdditions.h"
#import "Photo.h"
#import "MOUtility.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@interface SharePhotoViewController ()

@end

@implementation SharePhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:@"Share Photo View"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!IS_IPHONE_5) {
        self.verticalConstraintPost.constant = 8.0;
    }
    
    //Keyboard dismiss
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    //Listen when text change in textfield
    //set notification for when a key is pressed.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector: @selector(keyPressed:)
                                                 name: UITextViewTextDidChangeNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];


    
    //Init
    self.hasCLickOnPost = NO;
    self.hasFInishedUpload = NO;
    self.hintIsWritten = YES;
    
    //Top bar
    self.navigationController.navigationBar.tintColor = [UIColor orangeColor];
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"SharePhotoViewController_Title", nil);
    
    self.previewImage.image = self.takenPhoto;
	// Do any additional setup after loading the view.
    
    //start upload
    if (self.takenPhoto) {
        self.title = NSLocalizedString(@"SharePhotoViewController_Title_One", nil);
        self.titlePhoto.text = NSLocalizedString(@"SharePhotoViewController_AddLegend", nil);
        [self.postButton setTitle:NSLocalizedString(@"SharePhotoViewController_Title_One", nil) forState:UIControlStateNormal];
        
        
        [self postFileInBackground];
    }
    else{
        self.nbPhotosUploaded = 0;
        self.photosUploaded = [[NSMutableArray alloc] init];
        self.labelPhotosUploaded.text = [NSString stringWithFormat:@"%i/%i", self.nbPhotosUploaded+1, self.photosArray.count];
        
        //Change text in order to match with several photos
        self.title = NSLocalizedString(@"SharePhotoViewController_Title", nil);
        self.titlePhoto.text = NSLocalizedString(@"SharePhotoViewController_AddLegend2", nil);
        [self.postButton setTitle:NSLocalizedString(@"SharePhotoViewController_Title", nil) forState:UIControlStateNormal];
        
        //Hide element that fit for one photo
        [self.collectionView setHidden:NO];
        [[self.view viewWithTag:1] setHidden:YES];
        [[self.view viewWithTag:2] setHidden:YES];
        
        [self postArrayOfFilesInBackground:0];
        
        
        
    }
    
}


#pragma mark - UICollectionView delegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photosArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PhotosAlbumCellIdentifier";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UIImageView *photoView = (UIImageView *)[cell viewWithTag:10];
    
    Photo *photo = [self.photosArray objectAtIndex:indexPath.row];
    photoView.image = photo.thumbnail;
    
    return cell;
}


- (IBAction)facebookShare:(id)sender {
    if (self.facebookButton.isSelected) {
        [self.facebookButton setSelected:NO];
        [self.fbLogo setImage:[UIImage imageNamed:@"fb_off_share"]];
    }
    else{
        [self.facebookButton setSelected:YES];
        [self.fbLogo setImage:[UIImage imageNamed:@"fb_on_share"]];
    }
}

- (IBAction)twitterShare:(id)sender {
    if (self.twitterButton.isSelected) {
        [self.twitterButton setSelected:NO];
        [self.twLogo setImage:[UIImage imageNamed:@"tw_off_share"]];
    }
    else{
        [self.twitterButton setSelected:YES];
        [self.twLogo setImage:[UIImage imageNamed:@"tw_on_share"]];
    }
}

- (IBAction)postPhoto:(id)sender {
    
    if (!self.hasCLickOnPost) {
        
        [self.navigationItem setHidesBackButton:YES];
        //Progress
        [self.progressView setHidden:NO];
        
        if (self.takenPhoto) {
            //Facebook share
            if (self.facebookButton.isSelected) {
                FBRequest *request = [FBRequest requestWithGraphPath:@"/me/photos" parameters:@{@"source": self.takenPhoto, @"message":self.labelPhotosUploaded.text, @"ref":@"photoshare"} HTTPMethod:@"POST"];
                [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (!error) {
                        NSLog(@"PHOTO SHARED ON FACEBOOK");
                        [[Mixpanel sharedInstance] track:@"Share" properties:@{@"Platform": @"Facebook", @"From" : @"ShareView"}];
                    }
                }];
            }
            if (self.twitterButton.isSelected) {
                [MOUtility postImage:self.takenPhoto withStatus:@"test"];
                [[Mixpanel sharedInstance] track:@"Share" properties:@{@"Platform": @"Twitter", @"From" : @"ShareView"}];
            }
            
            if(!self.thumbnailFile || self.imageFile){
                PFObject *eventPhoto = [PFObject objectWithClassName:@"Photo"];
                eventPhoto[@"full_image"] = self.imageFile;
                eventPhoto[@"low_image"] = self.thumbnailFile;
                eventPhoto[@"user"] = [PFUser currentUser];
                eventPhoto[@"event"] = self.event;
                
                //Add title if has written something
                if (!self.hintIsWritten) {
                    NSString *uniText = [NSString stringWithUTF8String:[self.titlePhoto.text UTF8String]];
                    NSData *msgData = [uniText dataUsingEncoding:NSNonLossyASCIIStringEncoding];
                    NSString *goodMsg = [[NSString alloc] initWithData:msgData encoding:NSUTF8StringEncoding] ;
                    
                    NSDictionary *title = @{@"name": [PFUser currentUser][@"name"],
                                            @"id": [PFUser currentUser].objectId,
                                            @"date": [NSDate date],
                                            @"comment":goodMsg};
                    NSArray *comments = [NSArray arrayWithObjects:title, nil];
                    eventPhoto[@"comments"] = comments;
                }
                
                [eventPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        self.hasCLickOnPost = YES;
                        if (self.hasFInishedUpload) {
                            //Post on facebook event wall
                            [self hasFinishedUpload];
                        }
                    }
                    else{
                        NSLog(@"%@", [error userInfo]);
                        NSLog(@"Photo failed to save: %@", error);
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Title_Photo_Error", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
                        [alert show];
                    }
                }];
            }
            else{
                
            }
        }
        //Multiple photos
        else{
            //Show check photos
            
            
            __block int addedPhotos = 0;
            self.hasCLickOnPost = YES;
            [self.labelPhotosUploaded setHidden:NO];
            
            for(NSDictionary *info in self.photosUploaded){
                if (info[@"success"]) {
                    PFObject *eventPhoto = [PFObject objectWithClassName:@"Photo"];
                    eventPhoto[@"full_image"] = info[@"file"];
                    eventPhoto[@"low_image"] = info[@"thumbnail"];
                    eventPhoto[@"user"] = [PFUser currentUser];
                    eventPhoto[@"event"] = self.event;
                    eventPhoto[@"width"] = info[@"width"];
                    eventPhoto[@"height"] = info[@"height"];
                    
                    //Add title if has written something
                    if (!self.hintIsWritten) {
                        NSDictionary *title = @{@"name": [PFUser currentUser][@"name"],
                                                @"id": [PFUser currentUser].objectId,
                                                @"date": [NSDate date],
                                                @"comment":self.titlePhoto.text};
                        NSArray *comments = [NSArray arrayWithObjects:title, nil];
                        eventPhoto[@"comments"] = comments;
                    }
                    
                    [eventPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        //SUIVANTE
                        if (succeeded) {
                        }
                        
                        addedPhotos++;
                        //If all the files uploaded
                        if (addedPhotos == self.photosArray.count) {
                            [self hasFinishedUpload];
                        }
                    }];
                }
                else{
                    
                    addedPhotos++;
                    //If all the files uploaded
                    if (addedPhotos == self.photosArray.count) {
                        [self hasFinishedUpload];
                    }
                    
                }
            }
            
            
            [self.photosUploaded removeAllObjects];
        }

    }
    
    
    

    
    
}


//Post when only one image
-(void)postFileInBackground{
    
    //Good quality photo
    NSData *imageData = UIImageJPEGRepresentation(self.takenPhoto, 0.8f);
    self.imageFile = [PFFile fileWithData:imageData];
    
    //Thumbnail
    UIImage *thumbnail= [self.takenPhoto thumbnailImage:150.0f transparentBorder:0.0f cornerRadius:0.0f interpolationQuality:kCGInterpolationDefault];
    NSData *thumbnailImageData = UIImagePNGRepresentation(thumbnail);
    self.thumbnailFile = [PFFile fileWithData:thumbnailImageData];
    
    //Progress
    [self.progressView setProgress:0.0f];
    //[self.progressView setHidden:NO];
    
    [self.imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self.thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    NSLog(@"THumbnail Ok");
                    self.hasFInishedUpload = YES;
                    
                    if (self.hasCLickOnPost) {
                        //Post on facebook event wall
                        [self hasFinishedUpload];
                    }
                }
            }];
            
        }
        else{
            NSLog(@"Problem Uploading");
        }
    } progressBlock:^(int percentDone) {
        // Update your progress spinner here. percentDone will be between 0 and 100.
        [self.progressView setProgress:(float)percentDone/100];
    }];
}


-(void)postArrayOfFilesInBackground:(int)position{
    
    
    Photo *photo = [self.photosArray objectAtIndex:position];
    
    NSData *thumbnailImageData = UIImagePNGRepresentation(photo.thumbnail);
    PFFile *thumbnailFile = [PFFile fileWithData:thumbnailImageData];
    thumbnailImageData = nil;
    
    //Good quality photo
    [self getUIImageFromAssetURL:photo.assetUrl withEnded:^(UIImage *image) {
        UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:[MOUtility newBoundsForMaxSize:1000.0f andActualSize:image.size] interpolationQuality:kCGInterpolationHigh];
        NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.8f);
        
        
        __block float width = resizedImage.size.width;
        __block float height = resizedImage.size.height;
        PFFile *imageFile = [PFFile fileWithData:imageData];
        imageData = nil;
        
        
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        NSLog(@"THumbnail Ok");
                        
                        //The user has clicked on the button, we can associate it with an object and save the object
                        if (self.hasCLickOnPost) {
                            PFObject *eventPhoto = [PFObject objectWithClassName:@"Photo"];
                            eventPhoto[@"full_image"] = imageFile;
                            eventPhoto[@"low_image"] = thumbnailFile;
                            eventPhoto[@"user"] = [PFUser currentUser];
                            eventPhoto[@"event"] = self.event;
                            eventPhoto[@"width"] = [NSNumber numberWithFloat:width];;
                            eventPhoto[@"height"] = [NSNumber numberWithFloat:height];
                            
                            //Add title if has written something
                            if (!self.hintIsWritten) {
                                NSDictionary *title = @{@"name": [PFUser currentUser][@"name"],
                                                        @"id": [PFUser currentUser].objectId,
                                                        @"date": [NSDate date],
                                                        @"comment":self.titlePhoto.text};
                                NSArray *comments = [NSArray arrayWithObjects:title, nil];
                                eventPhoto[@"comments"] = comments;
                            }
                            
                            [eventPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                if (succeeded) {
                                    //CHECK AND NB PHOTOS UPLOADED
                                    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:position inSection:0]];
                                    UIImageView *imageCheck = (UIImageView *)[cell viewWithTag:20];
                                    [imageCheck setHidden:NO];
                                    
                                }
                                
                                //SUIVANTE
                                self.nbPhotosUploaded++;
                                self.labelPhotosUploaded.text = [NSString stringWithFormat:@"%i/%i", self.nbPhotosUploaded+1, self.photosArray.count];
                                if (self.nbPhotosUploaded < self.photosArray.count) {
                                    [self postArrayOfFilesInBackground:self.nbPhotosUploaded];
                                }
                                else{
                                    if (self.hasCLickOnPost) {
                                        //Push
                                        [self hasFinishedUpload];
                                    }
                                    
                                }
                            }];
                            
                        }
                        else{
                            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:position inSection:0]];
                            UIImageView *imageCheck = (UIImageView *)[cell viewWithTag:20];
                            [imageCheck setHidden:NO];
                            
                            NSDictionary *photoUploaded = @{@"file": imageFile,
                                                    @"thumbnail": thumbnailFile,
                                                    @"success": @YES,
                                                    @"width":[NSNumber numberWithFloat:width],
                                                    @"height":[NSNumber numberWithFloat:height]};
                            [self.photosUploaded addObject:photoUploaded];
                            //SUIVANTE
                            self.nbPhotosUploaded++;
                            self.labelPhotosUploaded.text = [NSString stringWithFormat:@"%i/%i", self.nbPhotosUploaded+1, self.photosArray.count];
                            if (self.nbPhotosUploaded < self.photosArray.count) {
                                [self postArrayOfFilesInBackground:self.nbPhotosUploaded];
                            }
                        }
                        
                    }
                    else{
                        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:position inSection:0]];
                        UIImageView *imageCheck = (UIImageView *)[cell viewWithTag:20];
                        [imageCheck setHidden:NO];
                        imageCheck.image = [UIImage imageNamed:@"btn_cancel"];
                        
                        NSDictionary *photoUploaded = @{@"file": imageFile,
                                                        @"thumbnail": thumbnailFile,
                                                        @"success": @NO,
                                                        @"width":[NSNumber numberWithFloat:width],
                                                        @"height":[NSNumber numberWithFloat:height]};
                        [self.photosUploaded addObject:photoUploaded];
                        
                        self.nbPhotosUploaded++;
                        self.labelPhotosUploaded.text = [NSString stringWithFormat:@"%i/%i", self.nbPhotosUploaded+1, self.photosArray.count];
                        if (self.nbPhotosUploaded < self.photosArray.count) {
                            [self postArrayOfFilesInBackground:self.nbPhotosUploaded];
                        }
                        else{
                            if (self.hasCLickOnPost) {
                                [self hasFinishedUpload];
                            }
                            
                        }
                    }
                }];
            }
            else{
                UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:position inSection:0]];
                UIImageView *imageCheck = (UIImageView *)[cell viewWithTag:20];
                [imageCheck setHidden:NO];
                imageCheck.image = [UIImage imageNamed:@"btn_cancel"];
                
                NSDictionary *photoUploaded = @{@"file": imageFile,
                                                @"thumbnail": thumbnailFile,
                                                @"success": @NO,
                                                @"width":[NSNumber numberWithFloat:width],
                                                @"height":[NSNumber numberWithFloat:height]};
                [self.photosUploaded addObject:photoUploaded];
                NSLog(@"Problem Uploading");
                self.nbPhotosUploaded++;
                self.labelPhotosUploaded.text = [NSString stringWithFormat:@"%i/%i", self.nbPhotosUploaded+1, self.photosArray.count];
                if (self.nbPhotosUploaded < self.photosArray.count) {
                    [self postArrayOfFilesInBackground:self.nbPhotosUploaded];
                }
                else{
                    if (self.hasCLickOnPost) {
                        [self hasFinishedUpload];
                    }
                }
            }
        } progressBlock:^(int percentDone) {
            // Update your progress spinner here. percentDone will be between 0 and 100.
            
            [self.progressView setProgress:(float)percentDone/100];
            //self.nbPhotosLabel.text = [NSString stringWithFormat:@"%i/%i", self.nbOfPhotosUploaded, self.photosToUpload.count];
        }];
    }];
}



#pragma mark - IOS Resources
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



#pragma mark - TextField
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

-(void)keyboardWillShow:(NSNotification *)note{
    NSLog(@"Keyboad Show");
    if (self.hintIsWritten) {
        self.hintIsWritten = NO;
        [self.titlePhoto setTextColor:[UIColor blackColor]];
        self.titlePhoto.text = @"";
    }
}

-(void)keyboardWillHide:(NSNotification *)note{
    NSLog(@"Keyboad Hide");
    if (self.titlePhoto.text.length == 0) {
        self.hintIsWritten = YES;
        [self.titlePhoto setTextColor:[UIColor grayColor]];
        self.titlePhoto.text = NSLocalizedString(@"SharePhotoViewController_AddLegend", nil);
    }
}

-(void)dismissKeyboard {
    [self.titlePhoto resignFirstResponder];
}

-(void)keyPressed:(NSNotification *)note{
    //NSLog(@"%@", self.titlePhoto.text);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex]) {
        [self dismissViewControllerAnimated:NO completion:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:UploadPhotoFinished object:self userInfo:nil];
    }else{
        NSString *message = [[NSString alloc] init];
        
        if (self.photosArray) {
            message = [NSString stringWithFormat:NSLocalizedString(@"SharePhotoViewController_SharedPhoto2", nil), self.photosArray.count];
            [self pushEveryInvited:self.photosArray.count];
        }
        else{
            message = NSLocalizedString(@"SharePhotoViewController_SharedPhoto3", nil);
            [self pushEveryInvited:1];
        }
        
        NSString *url = [NSString stringWithFormat:@"http://www.woovent.com/e/%@", self.event.objectId];
        [MOUtility postLinkOnFacebookEventWall:self.event[@"eventId"] withUrl:url withMessage:message];
        
        
        
        [self dismissViewControllerAnimated:NO completion:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:UploadPhotoFinished object:self userInfo:nil];
    }
}

#pragma mark - FInish upload

-(void)hasFinishedUpload{
    
    NSString *message = [[NSString alloc] init];
    
    if (self.photosArray) {
        message = [NSString stringWithFormat:NSLocalizedString(@"SharePhotoViewController_SharedPhoto2", nil), self.photosArray.count];
        [self pushEveryInvited:self.photosArray.count];
    }
    else{
        message = NSLocalizedString(@"SharePhotoViewController_SharedPhoto3", nil);
        [self pushEveryInvited:1];
    }
    
    if (([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound)|| ([FBSession.activeSession.permissions indexOfObject:@"publish_stream"] == NSNotFound)) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Auth_Title", nil)
                                                            message:NSLocalizedString(@"UIAlertView_postPhotoFacebook", nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"UIAlertView_Cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
        [alertView show];
    }
    else{
        NSString *url = [NSString stringWithFormat:@"http://www.woovent.com/e/%@", self.event.objectId];
        [MOUtility postLinkOnFacebookEventWall:self.event[@"eventId"] withUrl:url withMessage:message];
        
        
        
        [self dismissViewControllerAnimated:NO completion:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:UploadPhotoFinished object:self userInfo:nil];
    }
    
    
    
}


//Push notif
-(void)pushEveryInvited:(int)nbPhotos{
    [[Mixpanel sharedInstance] track:@"Photos Uploaded" properties:@{@"Nb Photos": [NSNumber numberWithInt:nbPhotos], @"From" : @"Share Photo", @"Twitter Share":[NSNumber numberWithBool:self.twitterButton.isSelected], @"Facebook Share": [NSNumber numberWithBool:self.facebookButton.isSelected], @"Legend" : [NSNumber numberWithInt:self.titlePhoto.text.length]}];
    
    [PFCloud callFunction:@"pushnewphotos" withParameters:@{@"nbphotos": [NSNumber numberWithInt:nbPhotos], @"eventid" : self.event.objectId}];
}



@end

//
//  SharePhotoViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 14/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SharePhotoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UIImage *takenPhoto;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UIImageView *fbLogo;
@property (weak, nonatomic) IBOutlet UIImageView *twLogo;
@property (strong, nonatomic) PFObject *event;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) UIImage *imageSent;
@property (strong, nonatomic) UIImage *thumbnailSent;
@property (strong, nonatomic) PFFile *thumbnailFile;
@property (strong, nonatomic) PFFile *imageFile;
@property (nonatomic, assign) BOOL hasCLickOnPost;
@property (nonatomic, assign) BOOL hasFInishedUpload;
@property (nonatomic, assign) BOOL hintIsWritten;
@property (weak, nonatomic) IBOutlet UITextView *titlePhoto;



- (IBAction)facebookShare:(id)sender;
- (IBAction)twitterShare:(id)sender;
- (IBAction)postPhoto:(id)sender;
@end

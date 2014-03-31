//
//  UploadFilesAutomaticViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 25/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface UploadFilesAutomaticViewController : UIViewController <UIAlertViewDelegate>

@property (strong, nonatomic) NSMutableArray *photosToUpload;
@property (strong, nonatomic) NSMutableArray *photosAlreadyUploaded;
@property (strong, nonatomic) NSArray *invitations;

@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@property (weak, nonatomic) IBOutlet UIView *viewPhotosUploading;
@property (weak, nonatomic) IBOutlet UILabel *labelPhotosUploading;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

- (IBAction)inviteFriends:(id)sender;


@end

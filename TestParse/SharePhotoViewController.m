//
//  SharePhotoViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 14/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "SharePhotoViewController.h"
#import "UIImage+ResizeAdditions.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    [self postFilesInBackground];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    //Progress
    [self.progressView setHidden:NO];

    if(!self.thumbnailFile || self.imageFile){
        PFObject *eventPhoto = [PFObject objectWithClassName:@"Photo"];
        eventPhoto[@"full_image"] = self.imageFile;
        eventPhoto[@"low_image"] = self.thumbnailFile;
        eventPhoto[@"user"] = [PFUser currentUser];
        eventPhoto[@"event"] = self.event;
        
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
                self.hasCLickOnPost = YES;
                if (self.hasFInishedUpload) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:UploadPhotoFinished object:self userInfo:nil];
                    [self dismissViewControllerAnimated:NO completion:nil];
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

-(void)postFilesInBackground{
    
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
                        [self dismissViewControllerAnimated:NO completion:nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:UploadPhotoFinished object:self userInfo:nil];
                    }
                }
            }];
            
            /*
            PFObject *eventPhoto = [PFObject objectWithClassName:@"Photo"];
            eventPhoto[@"full_image"] = imageFile;
            eventPhoto[@"user"] = [PFUser currentUser];
            eventPhoto[@"event"] = self.event;
            [eventPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [self dismissViewControllerAnimated:NO completion:nil];
                }
                else{
                    NSLog(@"%@", [error userInfo]);
                }
            }];*/
        }
        else{
            NSLog(@"Problem Uploading");
        }
    } progressBlock:^(int percentDone) {
        // Update your progress spinner here. percentDone will be between 0 and 100.
        [self.progressView setProgress:(float)percentDone/100];
    }];
}

#pragma mark - TextField

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
    NSLog(@"%@", self.titlePhoto.text);
}

@end

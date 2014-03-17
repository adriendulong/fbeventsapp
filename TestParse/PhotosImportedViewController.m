
//
//  PhotosImportedViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 22/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "PhotosImportedViewController.h"
#import "HeaderSectionsCollectionView.h"
#import "MOUtility.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Photo.h"
#import "PhotosSelectionCell.h"
#import "NSMutableArray+Reverse.h"
#import "EventUtilities.h"
#import "MOUtility.h"
#import "UploadFilesAutomaticViewController.h"

@interface PhotosImportedViewController ()

@end

@implementation PhotosImportedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [self.validateButton setTitle:NSLocalizedString(@"UIBArButtonItem_Validate", nil)];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SelectAllPhotosPhone object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SelectAllPhotosFacebook object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSLog(@"self.events BEFORE = %@", self.events);
    [self addCustomDebugEvent];
    
    
    
    
    
    [self.validateButton setEnabled:NO];
    
    [self getFriendsInvited];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeSelectFacebook:) name:SelectAllPhotosFacebook object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeSelectPhone:) name:SelectAllPhotosPhone object:nil];
    
    //NSArray *photosFromPhone = [[NSArray alloc] init];
    //NSArray *photosFromFB = [[NSArray alloc] init];
    self.imagesFound = [[NSMutableArray alloc] init];
    //[self.imagesFound addObject:photosFromPhone];
    //[self.imagesFound addObject:photosFromFB];
    
    //self.numberOfPhotosSelectedFB = 0;
    self.numberOfPhotosSelectedPhone = 0;
    
    [self addLongPressGestureRecognizer];
    
    //Load photos from phone
    [self loadPhotos];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Collection Functions

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        HeaderSectionsCollectionView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        
        
        NSDate *startDate = (NSDate *)self.events[indexPath.section][@"event"][@"start_time"];
        
        NSDateFormatter* myFormatter = [[NSDateFormatter alloc] init];
        [myFormatter setDateFormat:@"dd/MM/yyyy"];
        NSString *formattedDateString = [myFormatter stringFromDate:startDate];
        
        headerView.viewHeader.backgroundColor = [UIColor orangeColor];
        headerView.eventName.text = self.events[indexPath.section][@"event"][@"name"];
        headerView.imageLogo.image = [UIImage imageNamed:@"camera_app"];
        headerView.dateEvent.text = formattedDateString;
        
        /*if (self.numberOfPhotosSelectedPhone == [[self.imagesFound objectAtIndex:indexPath.section] count]) {
            [headerView.modifySelectionButton setSelected:YES];
        }
        else{
            [headerView.modifySelectionButton setSelected:NO];
        }*/
        
        //Phone
        /*if (indexPath.section == 0) {
            
            NSDate *startDate = (NSDate *)self.event[@"event"][@"start_time"];
            
            NSDateFormatter* myFormatter = [[NSDateFormatter alloc] init];
            [myFormatter setDateFormat:@"dd/MM/yyyy"];
            NSString *formattedDateString = [myFormatter stringFromDate:startDate];
            
            headerView.viewHeader.backgroundColor = [UIColor orangeColor];
            headerView.eventName.text = self.event[@"event"][@"name"];
            headerView.imageLogo.image = [UIImage imageNamed:@"camera_app"];
            headerView.dateEvent.text = formattedDateString;
            
            if (self.numberOfPhotosSelectedPhone == [[self.imagesFound objectAtIndex:0] count]) {
                [headerView.modifySelectionButton setSelected:YES];
            }
            else{
                [headerView.modifySelectionButton setSelected:NO];
            }
            
            headerView.position = 0;
            
        }*/
        //Facebook
        /*else if(indexPath.section == 1){
            headerView.viewHeader.backgroundColor = [MOUtility colorWithHexString:FacebookFirstBlue];
            headerView.eventName.text = NSLocalizedString(@"PhotosImportedViewController_OnFacebook", nil);
            headerView.imageLogo.image = [UIImage imageNamed:@"facebook_logo_white"];
            headerView.dateEvent.text = [NSString stringWithFormat:NSLocalizedString(@"PhotosImportedViewController_NbPhotoFind", nil), [[self.imagesFound objectAtIndex:1] count]];
            
            if (self.numberOfPhotosSelectedFB == [[self.imagesFound objectAtIndex:1] count]) {
                [headerView.modifySelectionButton setSelected:YES];
            }
            else{
                [headerView.modifySelectionButton setSelected:NO];
            }
            
            headerView.position = 1;
        }*/
        
        
        reusableview = headerView;
    }
    else if (kind == UICollectionElementKindSectionFooter){
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        
        /*if (indexPath.section == 0) {
            if (!self.isLoadingFromPhone) {
                [footerView setHidden:YES];
            }
            
        }
        else if (indexPath.section == 1){
            if (!self.isLoadingFromFB) {
                [footerView setHidden:YES];
            }
        }*/
        reusableview = footerView;
    }

    
    return reusableview;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
    
    /*if (section==0) {
        if (!self.isLoadingFromPhone) {
            return CGSizeMake(320, 0);
        }
        else{
            return CGSizeMake(320, 50);
        }
    }
    else{
        if (!self.isLoadingFromFB) {
            return CGSizeMake(320, 0);
        }
        else{
            return CGSizeMake(320, 50);
        }
    }*/
    
    if (!self.isLoadingFromPhone) {
        return CGSizeMake(320, 0);
    }
    else{
        return CGSizeMake(320, 50);
    }
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    //return [[self.imagesFound objectAtIndex:section] count];
    return [[[self.events objectAtIndex:section] objectForKey:@"photos"] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    //return [self.imagesFound count];
    return [self.events count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"Cell";
    
    PhotosSelectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];

    //Photo *selectedPhoto = (Photo *)[[self.imagesFound objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
    Photo *selectedPhoto = (Photo *)[[[self.events objectAtIndex:indexPath.section] objectForKey:@"photos"] objectAtIndex:indexPath.item];
    
    if (indexPath.section == 0) {
        cell.imagePhoto.image = selectedPhoto.thumbnail;
    }
    else{
        [cell.imagePhoto setImageWithURL:[NSURL URLWithString:selectedPhoto.pictureUrl]
                        placeholderImage:[UIImage imageNamed:@"photo_default"]];
    }
    
    if (selectedPhoto.isSelected) {
        cell.checkIndicator.image = [UIImage imageNamed:@"check"];
    }
    else{
        cell.checkIndicator.image = [UIImage imageNamed:@"uncheck"];
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    //NSLog(@"index path %i, row %i", indexPath.section, indexPath.item);
    
    //Photo *photo = [[self.imagesFound objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
    Photo *photo = [[[self.events objectAtIndex:indexPath.section] objectForKey:@"photos"] objectAtIndex:indexPath.item];
    
    if (photo.isSelected) {
        photo.isSelected = NO;
        if (indexPath.section == 0) {
            self.numberOfPhotosSelectedPhone--;
        }
        else{
           self.numberOfPhotosSelectedFB--;
        }
    }
    else{
        photo.isSelected = YES;
        
        if (indexPath.section == 0) {
            self.numberOfPhotosSelectedPhone++;
        }
        else{
            self.numberOfPhotosSelectedFB++;
        }
    }
    
    [self.collectionView reloadData];
    
}

#pragma mark - Long press gesture recognizer

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.collectionView];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    if (indexPath == nil) {
        //NSLog(@"long press on collectionView but not on a item");
    } else {
        //NSLog(@"long press on collectionView at item %d", indexPath.item);
        
        if (!self.isTapLongGesture) {
            [self showFullScreenPhotoFromIndexPath:indexPath];
        }
    }
}

-(void)addLongPressGestureRecognizer
{
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.3; //seconds
    lpgr.delegate = self;
    [self.collectionView addGestureRecognizer:lpgr];
    
    self.tapLongGesture = NO;
}

-(void)showFullScreenPhotoFromIndexPath:(NSIndexPath *)indexPath
{
    self.tapLongGesture = YES;
    
    //Photo *selectedPhoto = (Photo *)[[self.imagesFound objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
    Photo *selectedPhoto = (Photo *)[[[self.events objectAtIndex:indexPath.section] objectForKey:@"photos"] objectAtIndex:indexPath.item];
    
    [MOUtility getUIImageFromAssetURL:selectedPhoto.assetUrl withEnded:^(UIImage *image) {
        
        if (image) {
            MXLMediaView *mediaView = [[MXLMediaView alloc] init];
            [mediaView setDelegate:self];
            
            [mediaView showImage:image inParentView:self.navigationController.view completion:nil];
        }
    }];
}

#pragma mark MXLMediaViewDelegate Methods

-(void)mediaView:(MXLMediaView *)mediaView didReceiveLongPressGesture:(id)gesture {
    //NSLog(@"MXLMediaViewDelgate: Long pressed received");
    
    UIActionSheet *shareActionSheet = [[UIActionSheet alloc] initWithTitle:@"Partager la photo"
                                                                  delegate:nil
                                                         cancelButtonTitle:@"Annuler"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:@"Twitter", @"Facebook", @"Instagram", nil];
    [shareActionSheet showInView:self.view];
}

-(void)mediaViewWillDismiss:(MXLMediaView *)mediaView {
    //NSLog(@"MXLMediaViewDelgate: Will dismiss");
}

-(void)mediaViewDidDismiss:(MXLMediaView *)mediaView {
    //NSLog(@"MXLMediaViewDelgate: Did dismiss");
    
    self.tapLongGesture = NO;
}

#pragma mark - Load photos

-(void)loadPhotos
{
    
    for (NSMutableDictionary *event in self.events) {
        
        NSLog(@"event NAME = %@", event[@"event"][@"name"]);
        
        NSDate *startDate = [(NSDate *)event[@"event"][@"start_time"] dateByAddingTimeInterval:-6*3600];
        NSDate *endDate = event[@"end_time_woovent"];
        NSLog(@"PhotosImported - end_time_woovent = %@", endDate);
        
        self.isLoadingFromPhone = YES;
        
        NSMutableArray *photosFoundLibrary = [[NSMutableArray alloc] init];
        self.numberOfPhotosSelectedPhone = 0;
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            
            @autoreleasepool {
                if (group) {
                    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                        if (result) {
                            
                            NSDate *photoDate = (NSDate *)[result valueForProperty:ALAssetPropertyDate];
                            
                            if ([MOUtility date:photoDate isBetweenDate:startDate andDate:endDate]) {
                                
                                Photo *photo = [[Photo alloc] init];
                                photo.thumbnail = [UIImage imageWithCGImage:result.aspectRatioThumbnail];
                                photo.assetUrl = [result valueForProperty:ALAssetPropertyAssetURL];
                                photo.date = photoDate;
                                photo.ownerPhoto = [PFUser currentUser];
                                photo.isSelected = YES;
                                
                                self.numberOfPhotosSelectedPhone++;
                                
                                [photosFoundLibrary addObject:photo];
                            }
                            
                        }
                    }];
                    
                    [photosFoundLibrary reverse];
                }
            }
            
            NSArray *photosLibrary = [photosFoundLibrary copy];
            //[self.imagesFound setObject:photosLibrary atIndexedSubscript:0];
            [event setValue:photosLibrary forKey:@"photos"];
            
            self.isLoadingFromPhone = NO;
            
            if (!self.isLoadingFromFB && !self.isLoadingFromFB) {
                [self.validateButton setEnabled:YES];
            }
            
            if (self.numberOfPhotosSelectedFB+self.numberOfPhotosSelectedPhone == 0) {
                [self.validateButton setTitle:NSLocalizedString(@"PhotosImportedViewController_Finish", nil)];
            }
            
            [self.collectionView reloadData];
            //[self updateNavBar];
        } failureBlock:^(NSError *error) {
            NSLog(@"Failed.");
        }];
    }
    
 }

/*-(void)changeSelectPhone:(NSNotification *)note{
    
    if ([[note.userInfo objectForKey:@"new_state"] isEqualToString:@"0"]) {
        for (int i=0; i<[[self.imagesFound objectAtIndex:0] count]; i++) {
            Photo *photo = (Photo *)[[self.imagesFound objectAtIndex:0] objectAtIndex:i];
            if (photo.isSelected) {
                photo.isSelected = NO;
                self.numberOfPhotosSelectedPhone--;
            }
        }
    }
    else{
        for (int i=0; i<[[self.imagesFound objectAtIndex:0] count]; i++) {
            Photo *photo = (Photo *)[[self.imagesFound objectAtIndex:0] objectAtIndex:i];
            if (!photo.isSelected) {
                photo.isSelected = YES;
                self.numberOfPhotosSelectedPhone++;
            }
        }
    }
    
    [self.collectionView reloadData];
}*/

/*-(void)changeSelectFacebook:(NSNotification *)note{
    if ([[note.userInfo objectForKey:@"new_state"] isEqualToString:@"0"]) {
        for (int i=0; i<[[self.imagesFound objectAtIndex:1] count]; i++) {
            Photo *photo = (Photo *)[[self.imagesFound objectAtIndex:1] objectAtIndex:i];
            
            if (photo.isSelected) {
                photo.isSelected = NO;
                self.numberOfPhotosSelectedFB--;
            }
            
        }
    }
    else{
        for (int i=0; i<[[self.imagesFound objectAtIndex:1] count]; i++) {
            Photo *photo = (Photo *)[[self.imagesFound objectAtIndex:1] objectAtIndex:i];
            
            if (!photo.isSelected) {
                photo.isSelected = YES;
                self.numberOfPhotosSelectedFB++;
            }
            
        }
    }
    
    [self.collectionView reloadData];
}*/


#pragma mark - Facebook

//Get all the friends of the user who was at this event
-(void)getFriendsInvited {
    self.isLoadingFromFB = YES;
    
    __block int nbUsersToRequest = 0;
    __block int nbOfUserAlreadyDone = 0;
    
    NSMutableArray *resultsPhotos = [[NSMutableArray alloc] init];
    
    for (NSDictionary *event in self.events) {
        
        NSDate *startDate = [(NSDate *)event[@"event"][@"start_time"] dateByAddingTimeInterval:-6*3600];
        NSDate *endDate = event[@"end_time_woovent"];
        
        int startTimeInterval = (int)[startDate timeIntervalSince1970];
        NSString *startDateString = [NSString stringWithFormat:@"%i", startTimeInterval];
        
        NSLog(@"Start Date %@, End date %@", startDate, endDate);
        int endTimeInterval = (int)[endDate timeIntervalSince1970];
        NSString *endDateString = [NSString stringWithFormat:@"%i", endTimeInterval];
        
        
        //FQL request
        NSString *requestFql = [NSString stringWithFormat:@"SELECT uid  FROM event_member WHERE eid=%@ and uid IN (SELECT uid2 FROM friend WHERE uid1 = me());", event[@"event"][@"eventId"]];
        
        //Make request
        FBRequest *request = [FBRequest requestForGraphPath:@"fql"];
        [request.parameters setObject:requestFql forKey:@"q"];
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (result) {
                
                ///////
                // For each friend we get the photos uploaded and where they are tagged
                ///////
                NSArray *resultsFB = (NSArray *)result[@"data"];
                nbUsersToRequest = [resultsFB count];
                
                /////////
                //PHOTOS uploaded by the user himself
                ////////
                
                NSString *photosUploadedPerso = [NSString stringWithFormat:@"/me/photos?fields=from,source,width,height,created_time,picture&until=%@&since=%@&type=uploaded", endDateString, startDateString];
                FBRequest *request = [FBRequest requestForGraphPath:photosUploadedPerso];
                
                
                [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (result) {
                        NSLog(@"RESULT %@", result);
                        for(id photoFb in result[@"data"]){
                            Photo *photo = [[Photo alloc] init];
                            photo.facebookId = photoFb[@"id"];
                            photo.pictureUrl = photoFb[@"picture"];
                            photo.sourceUrl = photoFb[@"source"];
                            photo.width = [NSNumber numberWithInt:[photoFb[@"width"] intValue]];
                            photo.height = [NSNumber numberWithInt:[photoFb[@"height"] intValue]];
                            photo.ownerPhoto = [PFUser currentUser];
                            photo.date = [MOUtility parseFacebookDate:photoFb[@"created_time"] isDateOnly:NO];
                            photo.isSelected = YES;
                            
                            self.numberOfPhotosSelectedFB++;
                            
                            [resultsPhotos addObject:photo];
                            
                        }
                        
                        nbOfUserAlreadyDone++;
                        if (((nbUsersToRequest+1)*2) == nbOfUserAlreadyDone) {
                            //[self.imagesFound setObject:[resultsPhotos copy] atIndexedSubscript:1];
                            self.isLoadingFromFB = NO;
                            
                            if (!self.isLoadingFromFB && !self.isLoadingFromFB) {
                                [self.validateButton setEnabled:YES];
                            }
                            
                            [self.collectionView reloadData];
                            
                        }
                    }
                    else{
                        NSLog(@"ERROR Photo %@", [error userInfo]);
                    }
                }];
                
                
                
                /////////
                //PHOTOS where the user is tagged
                ////////
                
                
                NSString *photoTaggedRequest = [NSString stringWithFormat:@"/me/photos?fields=from,source,width,height,created_time,picture&until=%@&since=%@&type=tagged", endDateString, startDateString];
                FBRequest *requestTagged = [FBRequest requestForGraphPath:photoTaggedRequest];
                
                [requestTagged startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (result) {
                        NSLog(@"RESULT %@", result);
                        for(id photoFb in result[@"data"]){
                            Photo *photo = [[Photo alloc] init];
                            photo.facebookId = photoFb[@"id"];
                            photo.pictureUrl = photoFb[@"picture"];
                            photo.sourceUrl = photoFb[@"source"];
                            photo.width = [NSNumber numberWithInt:[photoFb[@"width"] intValue]];
                            photo.height = [NSNumber numberWithInt:[photoFb[@"height"] intValue]];
                            photo.ownerPhoto = [PFUser currentUser];
                            photo.date = [MOUtility parseFacebookDate:photoFb[@"created_time"] isDateOnly:NO];
                            photo.isSelected = YES;
                            
                            self.numberOfPhotosSelectedFB++;
                            
                            [resultsPhotos addObject:photo];
                            
                        }
                        
                        nbOfUserAlreadyDone++;
                        if (((nbUsersToRequest+1)*2) == nbOfUserAlreadyDone) {
                            //[self.imagesFound setObject:[resultsPhotos copy] atIndexedSubscript:1];
                            self.isLoadingFromFB = NO;
                            
                            if (!self.isLoadingFromFB && !self.isLoadingFromFB) {
                                [self.validateButton setEnabled:YES];
                            }
                            
                            [self.collectionView reloadData];
                            
                        }
                    }
                    else{
                        NSLog(@"ERROR Photo %@", [error userInfo]);
                    }
                }];
                
                for(id friend in result[@"data"]){
                    //Get all the photos uploaded by the user
                    
                    NSString *photoUplodedRequest = [NSString stringWithFormat:@"/%@/photos?fields=from,source,width,height,created_time,picture&until=%@&since=%@&type=uploaded", friend[@"uid"], endDateString, startDateString];
                    FBRequest *request = [FBRequest requestForGraphPath:photoUplodedRequest];
                    
                    
                    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                        if (result) {
                            NSLog(@"RESULT %@", result);
                            for(id photoFb in result[@"data"]){
                                Photo *photo = [[Photo alloc] init];
                                photo.facebookId = photoFb[@"id"];
                                photo.pictureUrl = photoFb[@"picture"];
                                photo.sourceUrl = photoFb[@"source"];
                                photo.width = [NSNumber numberWithInt:[photoFb[@"width"] intValue]];
                                photo.height = [NSNumber numberWithInt:[photoFb[@"height"] intValue]];
                                photo.userFBName = photoFb[@"from"][@"name"];
                                photo.userId = photoFb[@"from"][@"id"];
                                photo.date = [MOUtility parseFacebookDate:photoFb[@"created_time"] isDateOnly:NO];
                                photo.isSelected = YES;
                                
                                self.numberOfPhotosSelectedFB++;
                                
                                [resultsPhotos addObject:photo];
                                
                            }
                            
                            nbOfUserAlreadyDone++;
                            if (((nbUsersToRequest+1)*2) == nbOfUserAlreadyDone) {
                                //[self.imagesFound setObject:[resultsPhotos copy] atIndexedSubscript:1];
                                self.isLoadingFromFB = NO;
                                
                                if (!self.isLoadingFromFB && !self.isLoadingFromFB) {
                                    [self.validateButton setEnabled:YES];
                                }
                                
                                [self.collectionView reloadData];
                                
                            }
                        }
                        else{
                            NSLog(@"ERROR Photo %@", [error userInfo]);
                        }
                    }];
                    
                    //Photos wher the user is tagged
                    
                    NSString *photoTaggedRequest = [NSString stringWithFormat:@"/%@/photos?fields=from,source,width,height,created_time,picture&until=%@&since=%@&type=tagged", friend[@"uid"], endDateString, startDateString];
                    FBRequest *requestTagged = [FBRequest requestForGraphPath:photoTaggedRequest];
                    
                    [requestTagged startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                        if (result) {
                            NSLog(@"RESULT %@", result);
                            for(id photoFb in result[@"data"]){
                                Photo *photo = [[Photo alloc] init];
                                photo.facebookId = photoFb[@"id"];
                                photo.pictureUrl = photoFb[@"picture"];
                                photo.sourceUrl = photoFb[@"source"];
                                photo.width = [NSNumber numberWithInt:[photoFb[@"width"] intValue]];
                                photo.height = [NSNumber numberWithInt:[photoFb[@"height"] intValue]];
                                photo.userFBName = photoFb[@"from"][@"name"];
                                photo.userId = photoFb[@"from"][@"id"];
                                photo.date = [MOUtility parseFacebookDate:photoFb[@"created_time"] isDateOnly:NO];
                                photo.isSelected = YES;
                                
                                self.numberOfPhotosSelectedFB++;
                                
                                [resultsPhotos addObject:photo];
                                
                            }
                            
                            nbOfUserAlreadyDone++;
                            if (((nbUsersToRequest+1)*2) == nbOfUserAlreadyDone) {
                                //[self.imagesFound setObject:[resultsPhotos copy] atIndexedSubscript:1];
                                self.isLoadingFromFB = NO;
                                
                                if (!self.isLoadingFromFB && !self.isLoadingFromFB) {
                                    [self.validateButton setEnabled:YES];
                                }
                                
                                [self.collectionView reloadData];
                                
                            }
                        }
                        else{
                            NSLog(@"ERROR Photo %@", [error userInfo]);
                        }
                    }];
                }
                
            }
            else{
                NSLog(@"ERROR : %@", [error userInfo]);
            }
        }];
    }
    
}



-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"UploadPhotos"]) {
        
        NSMutableArray *selectedPhotos = [[NSMutableArray alloc] init];
        
        int photosPhone=0;
        for(Photo *photo in [self.imagesFound objectAtIndex:0]){
            if (photo.isSelected){
                [selectedPhotos addObject:photo];
                photosPhone++;
            }
        }
        
        int photosFB=0;
        /*for(Photo *photo in [self.imagesFound objectAtIndex:1]){
            if (photo.isSelected){
                [selectedPhotos addObject:photo];
                photosFB++;
            }
        }*/
        
        [[Mixpanel sharedInstance] track:@"Upload Auto Photos" properties:@{@"Nb Photos Phone": [NSNumber numberWithInt:photosPhone],@"Nb Photos Facebook": [NSNumber numberWithInt:photosFB] }];
        
        UploadFilesAutomaticViewController *photoCollectionController = (UploadFilesAutomaticViewController *)segue.destinationViewController;
        photoCollectionController.photosToUpload = [selectedPhotos copy];
        //photoCollectionController.event = self.event[@"event"];
        photoCollectionController.levelRoot = self.levelRoot;
    }
    
}

#pragma mark - Action
- (IBAction)finishImport:(UIBarButtonItem *)sender {
    
    if (self.numberOfPhotosSelectedFB+self.numberOfPhotosSelectedPhone == 0) {
        //Notif in order to update the root view with the new event
        [[NSNotificationCenter defaultCenter] postNotificationName:UploadPhotoFinished object:self userInfo:nil];
        [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:self.levelRoot] animated:YES];
    } else {
        [self performSegueWithIdentifier:@"UploadPhotos" sender:self];
    }
}







#pragma mark - DEBUG
- (void)addCustomDebugEvent
{
    ///// DEBUG /////
    
    /*
     
     end_time_woovent = "2014-03-11 22:00:00 +0000"
     event
     {
     description = "Rien.."
     end_time = "2014-03-11 22:00:00 +0000"
     eventId = 1502264633333428
     is_date_only = 0
     location = "Aquitaine Europe Communication"
     name = "EVENT DEBUG"
     owner {
     id = 1718504689
     name = "J\\U00e9r\\U00e9my Carrat"
     picture {
     data {
     is_silhouette = 0
     url = "https://fbcdn-profile-a.akamaihd.net/hprofile-ak-ash1/t5/371816_1718504689_1971522980_q.jpg"
     }
     }
     }
     start_time = "2014-03-10 10:30:00 +0000"
     type = 1
     venue {
     city = Bordeaux
     country = France
     id = 159075617444630
     latitude = "44.8703635422"
     longitude = "-0.5479523192620001"
     state = ""
     street = ""
     zip = ""
     }
     }
     nb_photos = 10
     
     */
    
    
    
    NSMutableDictionary *eventCustom = [NSMutableDictionary dictionary];
    
    PFObject *eventDebug = [PFObject objectWithClassName:@"Event"];
    eventDebug[@"end_time"] = [MOUtility parseFacebookDate:@"2014-03-11 22:00:00 +0000" isDateOnly:NO];
    eventDebug[@"eventId"] = @"1502264633333428000000000";
    eventDebug[@"start_time"] = [MOUtility parseFacebookDate:@"2014-03-10 10:30:00 +0000" isDateOnly:NO];
    eventDebug[@"name"] = @"Event DEBUG";
    //[eventDebug save];
    
    [eventCustom setValue:[MOUtility parseFacebookDate:@"2014-03-11 22:00:00 +0000" isDateOnly:NO] forKey:@"end_time_woovent"];
    [eventCustom setValue:eventDebug forKey:@"event"];
    [eventCustom setValue:[NSNumber numberWithInt:10] forKey:@"nb_photos"];
    
    
    
    NSLog(@"eventCustom = %@", eventCustom);
    
    
    [self.events addObject:eventCustom];
    
    //eventCustom[@"event"] = eventDebug;
    
    NSLog(@"self.events AFTER = %@", self.events);
    
    ///// DEBUG /////
}


@end

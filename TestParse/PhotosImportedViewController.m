
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SelectAllPhotosPhone object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SelectAllPhotosFacebook object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self getFriendsInvited];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeSelectFacebook:) name:SelectAllPhotosFacebook object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeSelectPhone:) name:SelectAllPhotosPhone object:nil];
    
    NSArray *photosFromPhone = [NSArray arrayWithObjects: nil];
    NSArray *photosFromFB = [NSArray arrayWithObjects: nil];
    self.imagesFound = [[NSMutableArray alloc] init];
    [self.imagesFound addObject:photosFromPhone];
    [self.imagesFound addObject:photosFromFB];
    
    self.numberOfPhotosSelectedFB = 0;
    self.numberOfPhotosSelectedPhone = 0;
    
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
        
        //Phone
        if (indexPath.section == 0) {
            headerView.viewHeader.backgroundColor = [UIColor orangeColor];
            headerView.typeOfSource.text = @"Sur mon iPhone";
            headerView.imageLogo.image = [UIImage imageNamed:@"camera_app"];
            headerView.numberPhotos.text = [NSString stringWithFormat:@"%i photos de l'évènement touvées", [[self.imagesFound objectAtIndex:0] count]];
            
            if (self.numberOfPhotosSelectedPhone == [[self.imagesFound objectAtIndex:0] count]) {
                [headerView.modifySelectionButton setSelected:YES];
            }
            else{
                [headerView.modifySelectionButton setSelected:NO];
            }
            
            headerView.position = 0;
            
        }
        //Facebook
        else if(indexPath.section == 1){
            headerView.viewHeader.backgroundColor = [MOUtility colorWithHexString:FacebookFirstBlue];
            headerView.typeOfSource.text = @"Sur Facebook";
            headerView.imageLogo.image = [UIImage imageNamed:@"facebook_logo_white"];
            headerView.numberPhotos.text = [NSString stringWithFormat:@"%i photos de l'évènement touvées", [[self.imagesFound objectAtIndex:1] count]];
            
            if (self.numberOfPhotosSelectedFB == [[self.imagesFound objectAtIndex:1] count]) {
                [headerView.modifySelectionButton setSelected:YES];
            }
            else{
                [headerView.modifySelectionButton setSelected:NO];
            }
            
            headerView.position = 1;
        }
        
        
        reusableview = headerView;
    }

    
    return reusableview;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [[self.imagesFound objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self.imagesFound count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"Cell";
    
    PhotosSelectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];

    Photo *selectedPhoto = (Photo *)[[self.imagesFound objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if (indexPath.section == 0) {
        cell.imagePhoto.image = selectedPhoto.thumbnail;
    }
    else{
        [cell.imagePhoto setImageWithURL:[NSURL URLWithString:selectedPhoto.pictureUrl]
                            placeholderImage:[UIImage imageNamed:@"covertest.png"]];
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
    NSLog(@"index path %i, row %i", indexPath.section, indexPath.row);
    
    Photo *photo = [[self.imagesFound objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
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


#pragma mark - Photos from iPhone

#pragma mark - Load photos

-(void)loadPhotos
{
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
                        
                        if ([MOUtility date:photoDate isBetweenDate:[[NSDate date] dateByAddingTimeInterval:-3600*48] andDate:[NSDate date]]) {
                            
                            Photo *photo = [[Photo alloc] init];
                            photo.thumbnail = [UIImage imageWithCGImage:result.thumbnail];
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
        [self.imagesFound setObject:photosLibrary atIndexedSubscript:0];
        
        [self.collectionView reloadData];
        //[self updateNavBar];
    } failureBlock:^(NSError *error) {
        NSLog(@"Failed.");
    }];
    
 }

-(void)changeSelectPhone:(NSNotification *)note{
    
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
}

-(void)changeSelectFacebook:(NSNotification *)note{
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
}


#pragma mark - Facebook

//Get all the friends of the user who was at this event
-(void)getFriendsInvited{
    
    __block int nbUsersToRequest = 0;
    __block int nbOfUserAlreadyDone = 0;
    
    NSMutableArray *resultsPhotos = [[NSMutableArray alloc] init];
    
    //Start Date
    NSDate *start_date = [(NSDate *)self.event[@"start_time"] dateByAddingTimeInterval:-3600*6];
    int startTimeInterval = (int)[self.event[@"start_time"] timeIntervalSince1970];
    NSString *startDateString = [NSString stringWithFormat:@"%i", startTimeInterval];
    
    //End Date
    NSDate *endDate = [EventUtilities endDateForStart:start_date withType:self.event[@"type"] andLast:self.event[@"last"]];
    NSLog(@"Start Date %@, End date %@", start_date, endDate);
    int endTimeInterval = (int)[endDate timeIntervalSince1970];
    NSString *endDateString = [NSString stringWithFormat:@"%i", endTimeInterval];
    
    //FQL request
    NSString *requestFql = [NSString stringWithFormat:@"SELECT uid  FROM event_member WHERE eid=%@ and uid IN (SELECT uid2 FROM friend WHERE uid1 = me());", self.event[@"eventId"]];
    
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
                        photo.width = (int)photoFb[@"width"];
                        photo.width = (int)photoFb[@"height"];
                        photo.ownerPhoto = [PFUser currentUser];
                        photo.date = [MOUtility parseFacebookDate:photoFb[@"created_time"] isDateOnly:NO];
                        photo.isSelected = YES;
                        
                        self.numberOfPhotosSelectedFB++;
                        
                        [resultsPhotos addObject:photo];
                        
                    }
                    
                    nbOfUserAlreadyDone++;
                    if (((nbUsersToRequest+1)*2) == nbOfUserAlreadyDone) {
                        [self.imagesFound setObject:[resultsPhotos copy] atIndexedSubscript:1];
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
                        photo.width = (int)photoFb[@"width"];
                        photo.width = (int)photoFb[@"height"];
                        photo.ownerPhoto = [PFUser currentUser];
                        photo.date = [MOUtility parseFacebookDate:photoFb[@"created_time"] isDateOnly:NO];
                        photo.isSelected = YES;
                        
                        self.numberOfPhotosSelectedFB++;
                        
                        [resultsPhotos addObject:photo];
                        
                    }
                    
                    nbOfUserAlreadyDone++;
                    if (((nbUsersToRequest+1)*2) == nbOfUserAlreadyDone) {
                        [self.imagesFound setObject:[resultsPhotos copy] atIndexedSubscript:1];
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
                            photo.width = (int)photoFb[@"width"];
                            photo.width = (int)photoFb[@"height"];
                            photo.userFBName = photoFb[@"from"][@"name"];
                            photo.userId = photoFb[@"from"][@"id"];
                            photo.date = [MOUtility parseFacebookDate:photoFb[@"created_time"] isDateOnly:NO];
                            photo.isSelected = YES;
                            
                            self.numberOfPhotosSelectedFB++;
                            
                            [resultsPhotos addObject:photo];
                            
                        }
                        
                        nbOfUserAlreadyDone++;
                        if (((nbUsersToRequest+1)*2) == nbOfUserAlreadyDone) {
                            [self.imagesFound setObject:[resultsPhotos copy] atIndexedSubscript:1];
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
                            photo.width = (int)photoFb[@"width"];
                            photo.width = (int)photoFb[@"height"];
                            photo.userFBName = photoFb[@"from"][@"name"];
                            photo.userId = photoFb[@"from"][@"id"];
                            photo.date = [MOUtility parseFacebookDate:photoFb[@"created_time"] isDateOnly:NO];
                            photo.isSelected = YES;
                            
                            self.numberOfPhotosSelectedFB++;
                            
                            [resultsPhotos addObject:photo];
                            
                        }
                        
                        nbOfUserAlreadyDone++;
                        if (((nbUsersToRequest+1)*2) == nbOfUserAlreadyDone) {
                            [self.imagesFound setObject:[resultsPhotos copy] atIndexedSubscript:1];
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



-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"UploadPhotos"]) {
        
        NSMutableArray *selectedPhotos = [[NSMutableArray alloc] init];
        
        for(Photo *photo in [self.imagesFound objectAtIndex:0]){
            if (photo.isSelected){
                [selectedPhotos addObject:photo];
            }
        }
        
        for(Photo *photo in [self.imagesFound objectAtIndex:1]){
            if (photo.isSelected){
                [selectedPhotos addObject:photo];
            }
        }
        
        UploadFilesAutomaticViewController *photoCollectionController = (UploadFilesAutomaticViewController *)segue.destinationViewController;
        photoCollectionController.photosToUpload = [selectedPhotos copy];
        photoCollectionController.event = self.event;
    }
    
}

@end

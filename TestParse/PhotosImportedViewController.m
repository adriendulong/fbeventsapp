
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
#import "FbEventsUtilities.h"

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
    
    
    
    if ([self.navigationController.viewControllers count]==1) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                 target:self action:@selector(finish)];
        [self.navigationItem.leftBarButtonItem setTintColor:[UIColor whiteColor]];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [self loadPhotos];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SelectAllPhotosPhone object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SelectAllPhotosFacebook object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.validateButton setEnabled:NO];
    

    self.imagesFound = [[NSMutableArray alloc] init];
    for(PFObject *invitation in self.invitations){
        NSMutableArray *tempMutableArray = [[NSMutableArray alloc] init];
        [self.imagesFound addObject:tempMutableArray];
    }
    
    [self addLongPressGestureRecognizer];
    
    //Load photos from phone
    
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
        
        
        
        NSDate *startDate = (NSDate *)self.invitations[indexPath.section][@"start_time"];
        
        NSDateFormatter* myFormatter = [[NSDateFormatter alloc] init];
        [myFormatter setDateFormat:@"dd/MM/yyyy"];
        NSString *formattedDateString = [myFormatter stringFromDate:startDate];

        headerView.eventName.text = self.invitations[indexPath.section][@"event"][@"name"];
        //headerView.imageLogo.image = [UIImage imageNamed:@"camera_app"];
        headerView.dateEvent.text = formattedDateString;
        [headerView.modifySelectionButton setTag:indexPath.section];
        
        for(Photo *photo in [self.imagesFound objectAtIndex:indexPath.section]){
            if (!photo.isSelected) {
                [headerView.modifySelectionButton setSelected:NO];
                break;
            }
            else{
                [headerView.modifySelectionButton setSelected:YES];
            }
        }

        
        reusableview = headerView;
    }
    else if (kind == UICollectionElementKindSectionFooter){
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        reusableview = footerView;
    }

    
    return reusableview;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{

    
    if (!self.isLoadingFromPhone) {
        return CGSizeMake(320, 0);
    }
    else{
        return CGSizeMake(320, 50);
    }
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    //return [[self.imagesFound objectAtIndex:section] count];
    return [[self.imagesFound objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    //return [self.imagesFound count];
    return [self.invitations count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"Cell";
    
    PhotosSelectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];

    //Photo *selectedPhoto = (Photo *)[[self.imagesFound objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
    Photo *selectedPhoto = (Photo *)[[self.imagesFound objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
    

    cell.imagePhoto.image = selectedPhoto.thumbnail;

    
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
    Photo *photo = (Photo *)[[self.imagesFound objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
    
    if (photo.isSelected) {
        photo.isSelected = NO;
    }
    else{
        photo.isSelected = YES;
    }
    
    [self updateValidateButton];
    
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
    lpgr.minimumPressDuration = 0.2; //seconds
    lpgr.delegate = self;
    [self.collectionView addGestureRecognizer:lpgr];
    
    self.tapLongGesture = NO;
}

-(void)showFullScreenPhotoFromIndexPath:(NSIndexPath *)indexPath
{
    self.tapLongGesture = YES;
    
    //Photo *selectedPhoto = (Photo *)[[self.imagesFound objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
    Photo *selectedPhoto = (Photo *)[[self.imagesFound objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
    
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

    [[self findPhotosForInvitations:self.invitations] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            NSLog(@"Error finding photos");
        }
        else{
            self.imagesFound = task.result;
            [self updateValidateButton];
            [self.collectionView reloadData];
            
            //Start Upload
            self.operationUpload = [[NSOperation alloc] init];
            
            [[self uploadPhotosInBack:self.operationUpload] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                if (task.error) {
                    NSLog(@"Error");
                    
                }
                else{
                    NSLog(@"Total Success !!");
                    
                }
                
                return nil;
            }];
        }
        
        return nil;
    }];
    
    
 }


//Upload all the photos in background
-(BFTask *)uploadPhotosInBack:(NSOperation *)cancellationToken{
    BFTaskCompletionSource *taskUploadBack = [BFTaskCompletionSource taskCompletionSource];
    
    if (cancellationToken.isCancelled) {
        return [BFTask cancelledTask];
    }
    
    dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(aQueue, ^{
        
        NSMutableArray *tasks = [NSMutableArray array];
        
        for(NSMutableArray *images in self.imagesFound){
            [tasks addObject:[self uploadPhotosOneEvent:cancellationToken forPhotos:images]];
        }
        
        [[BFTask taskForCompletionOfAllTasks:tasks] continueWithBlock:^id(BFTask *task) {
            if (task.error) {
                [taskUploadBack setError:task.error];
            }
            else{
                [taskUploadBack setResult:nil];
            }
            
            return nil;
        }];
        
        /*BFTask *task = [BFTask taskWithResult:nil];
        for (PFObject *result in results) {
            // For each item, extend the task with a function to delete the item.
            task = [task continueWithBlock:^id(BFTask *task) {
                // Return a task that will be marked as completed when the delete is finished.
                return [self deleteAsync:result];
            }];
        }
        
        [task continueWithBlock:^id(BFTask *task) {
            return nil;
        }];
       */
    });
    
    return taskUploadBack.task;
}

-(BFTask *)uploadPhotosOneEvent:(NSOperation *)cancellationToken forPhotos:(NSMutableArray *)photos{
    BFTaskCompletionSource *taskGeneral = [BFTaskCompletionSource taskCompletionSource];

    if (cancellationToken.isCancelled) {
        return [BFTask cancelledTask];
    }
    
    dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(aQueue, ^{
        BFTask *taskSerie = [BFTask taskWithResult:nil];

        for (Photo *photo in photos) {
            // For each item, extend the task with a function to delete the item.
            [taskSerie = [taskSerie continueWithBlock:^id(BFTask *task) {
                // Return a task that will be marked as completed when the upload is finished.
                return [MOUtility completeUploadImage:cancellationToken forPhoto:photo];
            }] continueWithBlock:^id(BFTask *task) {
                if (task.error) {
                    NSLog(@"Erreur : %@", task.error);
                }
                else if(task.isCancelled){
                    NSLog(@"Cancelled");
                }
                else{
                    NSLog(@"Une photo finished");
                    //This photo has been uploaded
                    photo.isUploaded = YES;
                    photo.infosForUpload = (NSDictionary *)task.result;
                }
                
                return nil;
            }];
        }
        
        [taskSerie continueWithBlock:^id(BFTask *task) {
            if (task.error) {
                [taskGeneral setError:task.error];
            }
            else{
                NSLog(@"Un évènement fini");
                [taskGeneral setResult:nil];
            }
            
            return nil;
        }];
    });
    
    
    return taskGeneral.task;
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

        
        //Stop background upload
        [self.operationUpload cancel];
        
        [[Mixpanel sharedInstance] track:@"Upload Auto Photos" properties:@{@"Nb Photos Phone": [NSNumber numberWithInt:photosPhone],@"Nb Photos Facebook": [NSNumber numberWithInt:photosFB] }];
        
        
        /* Get the image to upload and the one already uploaded */
        
        NSMutableArray *photosAlreadyUploaded = [[NSMutableArray alloc] init];
        NSMutableArray *photosToUpload = [[NSMutableArray alloc] init];
        
        /* Keep the same order as the invitations */
        
        for(NSMutableArray *photos in self.imagesFound){
            NSMutableArray *photosTempToUpload = [[NSMutableArray alloc] init];
            NSMutableArray *photosTempsAlreadyUploaded = [[NSMutableArray alloc] init];
            
            for(Photo *photo in photos){
                if (photo.isUploaded) {
                    [photosTempsAlreadyUploaded addObject:photo];
                }
                else{
                    [photosTempToUpload addObject:photo];
                }
            }
            
            [photosAlreadyUploaded addObject:photosTempsAlreadyUploaded];
            [photosToUpload addObject:photosTempToUpload];
        }
        
        UploadFilesAutomaticViewController *photoCollectionController = (UploadFilesAutomaticViewController *)segue.destinationViewController;
        photoCollectionController.photosToUpload = photosToUpload;
        photoCollectionController.photosAlreadyUploaded = photosAlreadyUploaded;
        //photoCollectionController.event = self.event[@"event"];
        //photoCollectionController.levelRoot = self.levelRoot;
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

- (IBAction)selectOrDeselectAll:(id)sender {
    UIButton *button = (UIButton *)sender;
    for(Photo *photo in [self.imagesFound objectAtIndex:button.tag]){
        if (button.isSelected) {
            photo.isSelected = NO;
        }
        else{
            photo.isSelected = YES;
        }
        
        [self updateValidateButton];
    }
    
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:button.tag]];
}


#pragma mark - Find Photos

-(BFTask *)findPhotosForInvitations:(NSArray *)invitations{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    
    
    
    
    //self.isLoadingFromPhone = YES;
    
    //NSMutableArray *photosFoundLibrary = [[NSMutableArray alloc] init];
    //self.numberOfPhotosSelectedPhone = 0;
    NSMutableArray *photosEvents = [[NSMutableArray alloc] init];
    
    for(PFObject *invitation in invitations){
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        [photosEvents addObject:tempArray];
    }
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        @autoreleasepool {
            if (group) {
                if ([[group valueForProperty:ALAssetsGroupPropertyType] compare:[NSNumber numberWithInt:ALAssetsGroupPhotoStream]]!=NSOrderedSame) {
                    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                        if (result) {
                            
                            NSDate *photoDate = (NSDate *)[result valueForProperty:ALAssetPropertyDate];
                            int i=0;
                            
                            for(PFObject *invitation in invitations){
                                PFObject *event = invitation[@"event"];
                                NSDate *startDate = (NSDate *)event[@"start_time"];
                                NSDate *endDate = [FbEventsUtilities getEndDateEvent:event];
                                
                                if ([MOUtility date:photoDate isBetweenDate:startDate andDate:endDate]) {
                                    
                                    Photo *photo = [[Photo alloc] init];
                                    photo.thumbnail = [UIImage imageWithCGImage:result.aspectRatioThumbnail];
                                    photo.assetUrl = [result valueForProperty:ALAssetPropertyAssetURL];
                                    photo.date = photoDate;
                                    photo.ownerPhoto = [PFUser currentUser];
                                    photo.isSelected = YES;
                                    photo.isUploaded = NO;
                                    
                                    self.numberOfPhotosSelectedPhone++;
                                    
                                    [[photosEvents objectAtIndex:i] insertObject:photo atIndex:0];
                                }
                                
                                i++;
                            }
                        }
                    }];
                }
                
            }
            else{
                
                [task setResult:photosEvents];
                
            }
        }
        
        
        
        //[self updateNavBar];
    } failureBlock:^(NSError *error) {
        NSLog(@"Failed.");
        [task setError:error];
    }];
    
    
    return task.task;
    
}

/* Fonction tthat will tell us if at least one photo is selected */

-(void)updateValidateButton{
    for(NSDictionary *photos in self.imagesFound){
        for(Photo *photo in photos){
            if (photo.isSelected) {
                [self.validateButton setEnabled:YES];
                break;
            }
            else{
                [self.validateButton setEnabled:NO];
            }
        }
    }
    
    
}

-(void)finish{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

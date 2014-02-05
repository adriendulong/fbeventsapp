//
//  PhotosAlbumViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 28/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "PhotosAlbumViewController.h"
#import "Photo.h"
#import "NSMutableArray+Reverse.h"
#import "MOUtility.h"
#import "SharePhotoViewController.h"
#import "MBProgressHUD.h"

#define MAX_PHOTOS_UPLOAD (int)20

@interface PhotosAlbumViewController ()

@end

@implementation PhotosAlbumViewController

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
    
    self.navigationController.navigationBar.tintColor = [UIColor orangeColor];
    self.title = NSLocalizedString(@"PhotosAlbumViewController_Title", nil);
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.validateButton setTitle:NSLocalizedString(@"UIBArButtonItem_Validate", nil)];
    [self.selectButton setTitle:NSLocalizedString(@"PhotosAlbumViewController_AllDeselect", nil) forState:UIControlStateNormal];
    [self initTitlePopover];
    
    self.assetsGroupList = [NSMutableArray array];
    self.datasourceAutomatic = [NSMutableArray array];
    self.datasourceComplete = [NSMutableArray array];
	// Do any additional setup after loading the view.
    
    [self getAllAssetsGroupType];
    
    [self loadPhotos];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Init Title for Popover
- (void)initTitlePopover
{
    self.titleViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //self.titleViewButton.backgroundColor = [UIColor orangeColor];
    [self.titleViewButton setTitle:NSLocalizedString(@"PhotosAlbumViewController_CameraRoll", nil) forState:UIControlStateNormal];
    self.titleViewButton.frame = CGRectMake(0, 0, 200, 44);
    self.titleViewButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.titleViewButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.titleViewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.titleViewButton addTarget:self action:@selector(titleTap) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.titleView = self.titleViewButton;
}

- (void)titleTap
{
    [self performSegueWithIdentifier:@"ShowPhotosDatasource" sender:self];
}


#pragma mark - UICollectionView delegate

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (self.nbAutomaticPhotos == 0) {
        return 1;
    } else {
        return 2;
    }
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.nbAutomaticPhotos > 1) {
        
        if (section == 0) {
            return  self.datasourceAutomatic.count;
        } else {
            return  self.datasourceComplete.count;
        }
    } else {
        return  self.datasourceComplete.count;
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PhotosAlbumCellIdentifier";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UIImageView *photoView = (UIImageView *)[cell viewWithTag:1];
    UIImageView *check = (UIImageView *)[cell viewWithTag:2];
    
    //cell.photoView.userInteractionEnabled = YES;
    //cell.photoView.tag = indexPath.item;
    
    Photo *photo;
    
    if (self.nbAutomaticPhotos > 1) {
        
        if (indexPath.section == 0) {
            photo = (Photo *)[self.datasourceAutomatic objectAtIndex:indexPath.row];
        } else {
            photo = (Photo *)[self.datasourceComplete objectAtIndex:indexPath.row];
        }
    } else {
        photo = (Photo *)[self.datasourceComplete objectAtIndex:indexPath.row];
    }
    
    [photoView setImage:photo.thumbnail];
    //[cell setPhoto:photo];
    
    if (photo.isSelected) {
        check.image = [UIImage imageNamed:@"check"];
    } else {
        check.image = [UIImage imageNamed:@"uncheck"];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *selectedCell = (UICollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    UIImageView *checkView = (UIImageView *)[selectedCell viewWithTag:2];
    
    //NSLog(@"%@", selectedCell.photo.description);
    Photo *photo;
    if (self.nbAutomaticPhotos > 1) {
        
        if (indexPath.section == 0) {
            photo = [self.datasourceAutomatic objectAtIndex:indexPath.row];
        } else {
            photo = [self.datasourceComplete objectAtIndex:indexPath.row];
        }
    } else {
        photo = [self.datasourceComplete objectAtIndex:indexPath.row];
    }
    
    if (photo.isSelected) {
        photo.isSelected = NO;
        checkView.image = [UIImage imageNamed:@"uncheck"];
    }
    else{
        if ([self nbSelectedPhotos] < MAX_PHOTOS_UPLOAD) {
            photo.isSelected = YES;
            checkView.image = [UIImage imageNamed:@"check"];
        }
        else{
            int nbMax = MAX_PHOTOS_UPLOAD;
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"PhotosAlbumViewController_NbLimit", nil), nbMax];
            UIAlertView *limitAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Warning", nil) message:message delegate:self cancelButtonTitle:NSLocalizedString(@"UIAlertView_Dismiss", nil) otherButtonTitles:nil, nil];
            
            [limitAlert show];
        }
    }
    
    self.navigationItem.rightBarButtonItem.enabled = ([self nbSelectedPhotos] == 0) ? NO : YES;
    
    if ([self nbSelectedAutomaticPhotos] == 1) {
        [self.selectButton setTitle:NSLocalizedString(@"PhotosAlbumViewController_AllDeselect", nil) forState:UIControlStateNormal];
    } else if ([self nbSelectedAutomaticPhotos] == 0) {
        [self.selectButton setTitle:NSLocalizedString(@"PhotosAlbumViewController_AllSelect", nil) forState:UIControlStateNormal];
    }
    
    /*
     if ([self.photosToUpload containsObject:selectedCell.photo]) {
     //NSLog(@"La photo est sélectionnée. On la supprime !");
     [self.photosToUpload removeObject:selectedCell.photo];
     selectedCell.circleCheck.image = [UIImage imageNamed:@"picto_uncheck.png"];
     //[self.delegate removePhotoToUpload:selectedCell.photo];
     
     } else {
     
     if (self.photosToUpload.count < MAX_PHOTOS_UPLOAD) {
     //NSLog(@"La photo n'est pas sélectionnée. On l'ajoute !");
     [self.photosToUpload addObject:selectedCell.photo];
     selectedCell.circleCheck.image = [UIImage imageNamed:@"picto_check.png"];
     //[self.delegate addPhotoToUpload:selectedCell.photo];
     
     } else {
     
     UIAlertView *limitAlert = [[UIAlertView alloc] initWithTitle:@"Attention" message:@"La limite d'upload est fixée à 15 photos." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
     
     [limitAlert show];
     
     }
     
     
     }*/
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if(kind == UICollectionElementKindSectionHeader)
    {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PhotosAlbumHeaderSectionIdentifier" forIndexPath:indexPath];
        
        UILabel *labelTitle = (UILabel *)[headerView viewWithTag:10];
        
        if (self.nbAutomaticPhotos > 1) {
            labelTitle.text = (indexPath.section == 0) ? NSLocalizedString(@"PhotosAlbumViewController_AutoSelect", nil) : NSLocalizedString(@"PhotosAlbumViewController_AllAlbum", nil);
            
        } else {
            labelTitle.text = NSLocalizedString(@"PhotosAlbumViewController_AllAlbum", nil);
        }
        
        return headerView;
    }
    
    return nil;
}



#pragma mark - Selected Photos

- (IBAction)selectPhotos:(id)sender {
    if ([self nbSelectedAutomaticPhotos] == 0) {
        int i = 0;
        for(Photo *photo in self.datasourceAutomatic){
            if (i<MAX_PHOTOS_UPLOAD) {
                photo.isSelected = YES;
            }
            i++;
        }
        [self.collectionView reloadData];
        
        [sender setTitle:NSLocalizedString(@"PhotosAlbumViewController_AllDeselect", nil) forState:UIControlStateNormal];
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        
    } else {
        for(Photo *photo in self.datasourceAutomatic){
            photo.isSelected = NO;
        }
        /*for(Photo *photo in self.datasourceComplete){
            photo.isSelected = NO;
        }*/
        
        [self.collectionView reloadData];
        
        [sender setTitle:NSLocalizedString(@"PhotosAlbumViewController_AllSelect", nil) forState:UIControlStateNormal];
        
        if ([self nbSelectedPhotos] == 0) {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    }
}

-(int)nbSelectedPhotos{
    int selectedPhotos = 0;
    
    for(Photo *photo in self.datasourceAutomatic){
        if (photo.isSelected) {
            selectedPhotos++;
        }
    }
    
    for (Photo *photo in self.datasourceComplete) {
        if (photo.isSelected) {
            selectedPhotos++;
        }
    }
    
    return selectedPhotos;
}

-(int)nbSelectedAutomaticPhotos{
    int selectedPhotos = 0;
    
    for(Photo *photo in self.datasourceAutomatic){
        if (photo.isSelected) {
            selectedPhotos++;
        }
    }
    
    return selectedPhotos;
}


#pragma mark - Album Photos

-(void)loadPhotos
{
    
    NSDate *startDate = [(NSDate *)self.event[@"start_time"] dateByAddingTimeInterval:-6*3600];
    NSDate *endDate = [MOUtility getEndDateEvent:self.event];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    if (self.datasourceAutomatic.count == 0) {
        
        [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            
            @autoreleasepool {
                if (group) {
                    self.selectedGroupPersistentID = (NSString *)[group valueForProperty:ALAssetsGroupPropertyPersistentID];
                    //NSLog(@"datasourceAutomatic | groupName = %@", self.selectedGroupPersistentID);
                    
                    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                        if (result) {
                            
                            NSDate *photoDate = (NSDate *)[result valueForProperty:ALAssetPropertyDate];
                            
                            if (startDate && endDate) {
                                
                                if ([MOUtility date:photoDate isBetweenDate:startDate andDate:endDate]) {
                                    
                                    Photo *photo = [[Photo alloc] init];
                                    photo.thumbnail = [UIImage imageWithCGImage:result.thumbnail];
                                    photo.assetUrl = [result valueForProperty:ALAssetPropertyAssetURL];
                                    photo.date = photoDate;
                                    photo.isSelected = YES;
                                    
                                    
                                    
                                    if (![self.datasourceAutomatic containsObject:photo]) {
                                        
                                        [self.datasourceAutomatic addObject:photo];
                                        //[self.delegate addPhotoToUpload:photo];
                                        
                                        /*if (![self.photosToUpload containsObject:photo]) {
                                         [self.photosToUpload addObject:photo];
                                         
                                         //if (self.photosToUpload.count < MAX_PHOTOS_UPLOAD) {
                                         //    [self.photosToUpload addObject:photo];
                                         //}
                                         }*/
                                    }
                                }
                                
                            }
                        }
                    }];
                    
                    [self.datasourceAutomatic reverse];
                    
                    if (self.datasourceAutomatic.count > MAX_PHOTOS_UPLOAD) {
                        for(Photo *photo in self.datasourceAutomatic){
                            photo.isSelected = NO;
                        }
                        for (int i=0; i< MAX_PHOTOS_UPLOAD; i++) {
                            Photo *photo = [self.datasourceAutomatic objectAtIndex:i];
                            photo .isSelected = YES;
                        }
                    }
                    
                    if (self.datasourceAutomatic.count == 0) {
                        [self.selectButton removeFromSuperview];
                        self.headerConstraint.constant = 0;
                    } else {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }
            }
            
            [self.collectionView reloadData];
            //[self updateNavBar];
        } failureBlock:^(NSError *error) {
            NSLog(@"Failed.");
        }];
    }
    
    if (self.datasourceComplete.count == 0) {
        
        [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            
            @autoreleasepool {
                if (group) {
                    self.selectedGroupPersistentID = (NSString *)[group valueForProperty:ALAssetsGroupPropertyPersistentID];
                    //NSLog(@"datasourceComplete | groupName = %@", self.selectedGroupPersistentID);
                    
                    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                        if (result) {
                            
                            NSDate *photoDate = (NSDate *)[result valueForProperty:ALAssetPropertyDate];
                            
                            if (startDate && endDate) {
                                
                                if (![MOUtility date:photoDate isBetweenDate:startDate andDate:endDate]) {
                                    
                                    Photo *photo = [[Photo alloc] init];
                                    photo.thumbnail = [UIImage imageWithCGImage:result.thumbnail];
                                    photo.assetUrl = [result valueForProperty:ALAssetPropertyAssetURL];
                                    photo.date = photoDate;
                                    photo.isSelected = NO;
                                    
                                    if (![self.datasourceComplete containsObject:photo]) {
                                        
                                        [self.datasourceComplete addObject:photo];
                                    }
                                }
                                
                            }
                        }
                    }];
                    
                    [self.datasourceComplete reverse];
                }
            }
            
            [self.collectionView reloadData];
            //[self updateNavBar];
        } failureBlock:^(NSError *error) {
            NSLog(@"Failed.");
        }];
    }
}

-(void)loadPhotosFromAssetsGroupPersistentID:(NSString *)persistentID
{
    
    NSDate *startDate = [(NSDate *)self.event[@"start_time"] dateByAddingTimeInterval:-6*3600];
    NSDate *endDate = [MOUtility getEndDateEvent:self.event];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [self.datasourceAutomatic removeAllObjects];
    [self.datasourceComplete removeAllObjects];
    
    if (self.datasourceAutomatic.count == 0) {
        
        [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            
            @autoreleasepool {
                if (group) {
                    
                    if ([[group valueForProperty:ALAssetsGroupPropertyPersistentID] isEqualToString:persistentID]) {
                        
                        self.selectedGroupPersistentID = (NSString *)[group valueForProperty:ALAssetsGroupPropertyPersistentID];
                        //NSLog(@"datasourceAutomatic | groupName = %@", self.selectedGroupPersistentID);
                        
                        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                            if (result) {
                                
                                NSDate *photoDate = (NSDate *)[result valueForProperty:ALAssetPropertyDate];
                                
                                if (startDate && endDate) {
                                    
                                    if ([MOUtility date:photoDate isBetweenDate:startDate andDate:endDate]) {
                                        
                                        Photo *photo = [[Photo alloc] init];
                                        photo.thumbnail = [UIImage imageWithCGImage:result.thumbnail];
                                        photo.assetUrl = [result valueForProperty:ALAssetPropertyAssetURL];
                                        photo.date = photoDate;
                                        photo.isSelected = YES;
                                        
                                        
                                        
                                        if (![self.datasourceAutomatic containsObject:photo]) {
                                            
                                            [self.datasourceAutomatic addObject:photo];
                                            //[self.delegate addPhotoToUpload:photo];
                                            
                                            /*if (![self.photosToUpload containsObject:photo]) {
                                             [self.photosToUpload addObject:photo];
                                             
                                             //if (self.photosToUpload.count < MAX_PHOTOS_UPLOAD) {
                                             //    [self.photosToUpload addObject:photo];
                                             //}
                                             }*/
                                        }
                                    }
                                    
                                }
                            }
                        }];
                        
                        [self.datasourceAutomatic reverse];
                        
                        if (self.datasourceAutomatic.count > MAX_PHOTOS_UPLOAD) {
                            for(Photo *photo in self.datasourceAutomatic){
                                photo.isSelected = NO;
                            }
                            for (int i=0; i< MAX_PHOTOS_UPLOAD; i++) {
                                Photo *photo = [self.datasourceAutomatic objectAtIndex:i];
                                photo .isSelected = YES;
                            }
                        }
                        
                        if (self.datasourceAutomatic.count == 0) {
                            [self.selectButton removeFromSuperview];
                            self.headerConstraint.constant = 0;
                        } else {
                            self.navigationItem.rightBarButtonItem.enabled = YES;
                        }
                    }
                }
            }
            
            [self.collectionView reloadData];
            //[self updateNavBar];
        } failureBlock:^(NSError *error) {
            NSLog(@"Failed.");
        }];
    }
    
    if (self.datasourceComplete.count == 0) {
        
        [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            
            @autoreleasepool {
                if (group) {
                    
                    if ([[group valueForProperty:ALAssetsGroupPropertyPersistentID] isEqualToString:persistentID]) {
                        
                        self.selectedGroupPersistentID = (NSString *)[group valueForProperty:ALAssetsGroupPropertyPersistentID];
                        //NSLog(@"datasourceComplete | groupName = %@", self.selectedGroupPersistentID);
                        
                        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                            if (result) {
                                
                                NSDate *photoDate = (NSDate *)[result valueForProperty:ALAssetPropertyDate];
                                
                                if (startDate && endDate) {
                                    
                                    if (![MOUtility date:photoDate isBetweenDate:startDate andDate:endDate]) {
                                        
                                        Photo *photo = [[Photo alloc] init];
                                        photo.thumbnail = [UIImage imageWithCGImage:result.thumbnail];
                                        photo.assetUrl = [result valueForProperty:ALAssetPropertyAssetURL];
                                        photo.date = photoDate;
                                        photo.isSelected = NO;
                                        
                                        if (![self.datasourceComplete containsObject:photo]) {
                                            
                                            [self.datasourceComplete addObject:photo];
                                        }
                                    }
                                    
                                }
                            }
                        }];
                        
                        [self.datasourceComplete reverse];
                    }
                }
            }
            
            [self.collectionView reloadData];
            //[self updateNavBar];
        } failureBlock:^(NSError *error) {
            NSLog(@"Failed.");
        }];
    }
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"SharePhotos"]) {
        
        //Remove image preview from this screen if come back
        
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"PhotosAlbumViewController_Modify", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        
        NSMutableArray *photosSelected = [[NSMutableArray alloc] init];
        for(Photo *photo in self.datasourceAutomatic){
            if (photo.isSelected) {
                [photosSelected addObject:photo];
            }
        }
        for(Photo *photo in self.datasourceComplete){
            if (photo.isSelected) {
                [photosSelected addObject:photo];
            }
        }
        
        SharePhotoViewController *photosCollectionViewController = segue.destinationViewController;
        photosCollectionViewController.photosArray = [photosSelected copy];
        photosCollectionViewController.event = self.event;
        
        
    } else if ([segue.identifier isEqualToString:@"ShowPhotosDatasource"]) {
        
        WYStoryboardPopoverSegue *popoverSegue = (WYStoryboardPopoverSegue*)segue;
        
        PhotosDatasourceViewController *photosDatasourceViewController = (PhotosDatasourceViewController *)popoverSegue.destinationViewController;
        
        
        
        photosDatasourceViewController.preferredContentSize = CGSizeMake(320, self.assetsGroupList.count * 75);
        photosDatasourceViewController.delegate = self;
        photosDatasourceViewController.selectedGroupPersistentID = self.selectedGroupPersistentID;
        photosDatasourceViewController.assetsGroupList = self.assetsGroupList;
        
        
        WYPopoverBackgroundView* popoverAppearance = [WYPopoverBackgroundView appearance];
        
        [popoverAppearance setOverlayColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
        
        [popoverAppearance setOuterCornerRadius:10];
        [popoverAppearance setOuterShadowBlurRadius:0];
        [popoverAppearance setOuterShadowColor:[UIColor clearColor]];
        [popoverAppearance setOuterShadowOffset:CGSizeMake(0, 0)];
        
        [popoverAppearance setGlossShadowColor:[UIColor clearColor]];
        [popoverAppearance setGlossShadowOffset:CGSizeMake(0, 0)];
        
        [popoverAppearance setBorderWidth:0];
        [popoverAppearance setArrowHeight:7];
        [popoverAppearance setArrowBase:15];
        
        [popoverAppearance setInnerCornerRadius:10];
        [popoverAppearance setInnerShadowBlurRadius:0];
        [popoverAppearance setInnerShadowColor:[UIColor clearColor]];
        [popoverAppearance setInnerShadowOffset:CGSizeMake(0, 0)];
        
        [popoverAppearance setFillTopColor:[UIColor whiteColor]];
        [popoverAppearance setFillBottomColor:[UIColor whiteColor]];
        [popoverAppearance setOuterStrokeColor:[UIColor clearColor]];
        [popoverAppearance setInnerStrokeColor:[UIColor clearColor]];
        
        
        self.photosDatasourcePopoverController = [popoverSegue popoverControllerWithSender:self.navigationItem.titleView
                                                                  permittedArrowDirections:WYPopoverArrowDirectionUp
                                                                                  animated:YES
                                                                                   options:WYPopoverAnimationOptionFadeWithScale];
        
        self.photosDatasourcePopoverController.popoverLayoutMargins = UIEdgeInsetsMake(0, 0, 0, 0);
        
        self.photosDatasourcePopoverController.delegate = self;
    }
}


#pragma mark - Assets library management

+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

- (void)getAllAssetsGroupType {
    
    [[PhotosAlbumViewController defaultAssetsLibrary] enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            
            if (![self.assetsGroupList containsObject:group]) {
                [self.assetsGroupList addObject:group];
                
                /*NSString *groupName = [group valueForProperty:ALAssetsGroupPropertyName];
                NSString *groupType = [group valueForProperty:ALAssetsGroupPropertyType];
                NSString *groupID = [group valueForProperty:ALAssetsGroupPropertyPersistentID];
                NSString *groupURL = [group valueForProperty:ALAssetsGroupPropertyURL];
                 
                NSLog(@"groupName = %@", groupName);
                NSLog(@"groupType = %@", groupType);
                NSLog(@"groupID = %@", groupID);
                NSLog(@"groupURL = %@", groupURL);*/
            }
        }
    } failureBlock:^(NSError *error) {
        if (error) {
            NSLog(@"error = %@", error.localizedDescription);
        }
    }];
}


#pragma mark - WYPhotosDatasourceViewControllerDelegate

- (void)photosDatasourceViewControllerDidCancel:(PhotosDatasourceViewController *)controller
{
    controller.delegate = nil;
    [self.photosDatasourcePopoverController dismissPopoverAnimated:YES];
    self.photosDatasourcePopoverController.delegate = nil;
    self.photosDatasourcePopoverController = nil;
}

- (void)photosDatasourceViewController:(PhotosDatasourceViewController *)controller
                 didSelectedDatasource:(NSString *)selectedDatasource
                     andDatasourceName:(NSString *)datasourceName
{
	self.selectedGroupPersistentID  = selectedDatasource;
    NSString *newTitle = [NSString stringWithFormat:@"%@ ▾", datasourceName];
    [self.titleViewButton setTitle:newTitle forState:UIControlStateNormal];
    
    [self loadPhotosFromAssetsGroupPersistentID:self.selectedGroupPersistentID];
    
    [self photosDatasourceViewControllerDidCancel:controller];
}

@end

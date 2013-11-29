//
//  PhotosAlbumViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 28/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "PhotosAlbumViewController.h"
#import "Photo.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "NSMutableArray+Reverse.h"
#import "MOUtility.h"
#import "SharePhotoViewController.h"

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
    self.title = @"PHOTOS";
    
    self.datasourceAutomatic = [NSMutableArray array];
    self.datasourceComplete = [NSMutableArray array];
	// Do any additional setup after loading the view.
    
    [self loadPhotos];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - UICollectionView delegate

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == 0) {
        return  self.datasourceAutomatic.count;
    } else if (section == 1) {
        return  self.datasourceComplete.count;
    }
    
    return 0;
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
    if (indexPath.section == 0) {
        photo = (Photo *)[self.datasourceAutomatic objectAtIndex:indexPath.row];
    } else if (indexPath.section == 1) {
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

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *selectedCell = (UICollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    UIImageView *checkView = (UIImageView *)[selectedCell viewWithTag:2];
    
    //NSLog(@"%@", selectedCell.photo.description);
    Photo *photo;
    if (indexPath.section ==0)
    {
        photo = [self.datasourceAutomatic objectAtIndex:indexPath.row];
    }
    else{
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
            NSString *message = [NSString stringWithFormat:@"Le nombre de photos que vous pouvez ajouter en une fois est limité à %d", nbMax];
            UIAlertView *limitAlert = [[UIAlertView alloc] initWithTitle:@"Attention" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            
            [limitAlert show];
        }
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
        
        labelTitle.text = (indexPath.section == 0) ? @"Sélection automatique" : @"Tout l'album";
        
        return headerView;
    }
    
    return nil;
}



#pragma mark - Selected Photos

- (IBAction)selectPhotos:(id)sender {
    if ([self nbSelectedPhotos] == 0) {
        int i = 0;
        for(Photo *photo in self.datasourceAutomatic){
            if (i<MAX_PHOTOS_UPLOAD) {
                photo.isSelected = YES;
            }
            i++;
        }
        [self.collectionView reloadData];
        
        [sender setTitle:@"Tout désélectionner" forState:UIControlStateNormal];
    } else {
        for(Photo *photo in self.datasourceAutomatic){
            photo.isSelected = NO;
        }
        for(Photo *photo in self.datasourceComplete){
            photo.isSelected = NO;
        }
        
        [self.collectionView reloadData];
        
        [sender setTitle:@"Tout sélectionner" forState:UIControlStateNormal];
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


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"SharePhotos"]) {
        
        //Remove image preview from this screen if come back
        
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Modifier" style:UIBarButtonItemStylePlain target:nil action:nil];
        
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
    }
}

@end

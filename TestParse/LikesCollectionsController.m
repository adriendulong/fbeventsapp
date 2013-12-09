//
//  LikesCollectionsController.m
//  FbEvents
//
//  Created by Adrien Dulong on 02/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "LikesCollectionsController.h"
#import "MOUtility.h"
#import "Constants.h"

@interface LikesCollectionsController ()

@end

@implementation LikesCollectionsController

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
    self.title = NSLocalizedString(@"LikesCollectionsController_Title", nil);
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Collection View Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.likers count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    //UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:100];
    //recipeImageView.image = [UIImage imageNamed:@"covertest"];
    
    PFImageView *imageViewPhoto = (PFImageView *)[cell viewWithTag:10];
    PFImageView *fbViewPhoto = (PFImageView *)[cell viewWithTag:20];
    UILabel *labelName = (UILabel *)[cell viewWithTag:30];
    
    //From server
    if ([self.likers objectAtIndex:indexPath.row][@"facebookId"]) {
        [fbViewPhoto setHidden:YES];
        [imageViewPhoto setImageWithURL:[MOUtility UrlOfFacebooProfileImage:[self.likers objectAtIndex:indexPath.row][@"facebookId"] withResolution:FacebookLargeProfileImage] placeholderImage:[UIImage imageNamed:@"covertest"]];
    }
    else{
        [fbViewPhoto setHidden:NO];
        [imageViewPhoto setImageWithURL:[MOUtility UrlOfFacebooProfileImage:[self.likers objectAtIndex:indexPath.row][@"id"] withResolution:FacebookLargeProfileImage] placeholderImage:[UIImage imageNamed:@"covertest"]];
    }
    
    labelName.text = [self.likers objectAtIndex:indexPath.row][@"name"];
    
    
    return cell;
}

@end

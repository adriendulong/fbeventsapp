//
//  PhotoDetailViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 18/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "PhotoDetailViewController.h"
#import "OwnerPhotoCell.h"
#import "PhotoCell.h"
#import "LikesPhotoCell.h"
#import "ActionPhotoCell.h"
#import "CommentsCell.h"

@interface PhotoDetailViewController ()

@end

@implementation PhotoDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ClickLikePhoto object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MorePhoto object:nil];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = NSLocalizedString(@"PhotoDetailViewController_Title", nil);
    
    //Notifs
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userClickedLike:) name:ClickLikePhoto object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(morePhoto:) name:MorePhoto object:nil];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Photo"];
    [query includeKey:@"user"];
    [query includeKey:@"prospect"];
    [query getObjectInBackgroundWithId:self.photo.objectId block:^(PFObject *photoObject, NSError *error) {
        if (!error) {
            self.photo = photoObject;
            [self.tableView reloadData];
        }
        
    }];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 50;
    } else if (indexPath.row==1) {
        return 320;
    }
    else if (indexPath.row==2){
        return 50;
    }
    else{
        return 100;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"Section %i", section);
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //OwnerPhoto part
    if (indexPath.row==0) {
        static NSString *simpleTableIdentifier = @"OwnerCell";
        
        OwnerPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        
        if (cell == nil) {
            cell = [[OwnerPhotoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        
        
        NSURL *pictureURL = [[NSURL alloc] init];
        
        if (self.photo[@"user"]) {
            cell.ownerName.text = self.photo[@"user"][@"name"];
            
            //corner radius image owner photo
            cell.ownerImage.layer.cornerRadius = 18.0f;
            cell.ownerImage.layer.masksToBounds = YES;
            
             pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=normal&return_ssl_resources=1", self.photo[@"user"][@"facebookId"]]];
        }
        else{
            cell.ownerName.text = self.photo[@"prospect"][@"name"];
            
            //corner radius image owner photo
            cell.ownerImage.layer.cornerRadius = 18.0f;
            cell.ownerImage.layer.masksToBounds = YES;
            
            pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=normal&return_ssl_resources=1", self.photo[@"prospect"][@"facebookId"]]];
        }
        
        
        [cell.ownerImage setImageWithURL:pictureURL
                        placeholderImage:[UIImage imageNamed:@"covertest.png"]];
        
        return cell;
    }
    else if (indexPath.row==1){
        static NSString *simpleTableIdentifier = @"PhotoCell";
        
        PhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        
        if (cell == nil) {
            cell = [[PhotoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        
        if (self.photo[@"facebookId"]) {
            [cell.photoImage setImageWithURL:self.photo[@"facebook_url_full"] placeholderImage:[UIImage imageNamed:@"covertestinfos.png"]];
        }
        else{
            cell.photoImage.image = [UIImage imageNamed:@"covertest"]; // placeholder image
            cell.photoImage.file = (PFFile *)self.photo[@"full_image"];
            
            [cell.photoImage loadInBackground];
        }
        
        
        
        return cell;
        
    }
    else if(indexPath.row==2) {
        static NSString *simpleTableIdentifier = @"ActionCell";
        
        ActionPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        
        if (cell == nil) {
            cell = [[ActionPhotoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        
        if ([self hasLikedPhoto]) {
            [cell.likeButton setSelected:YES];
        }
        else{
            [cell.likeButton setSelected:NO];
        }
        
        return cell;
    }
    else{
        static NSString *simpleTableIdentifier = @"LikesCell";
        
        LikesPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        
        if (cell == nil) {
            cell = [[LikesPhotoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        
        NSMutableArray *likersArray = [[NSMutableArray alloc] init];
        for (id like in self.photo[@"likes"]) {
            [likersArray addObject:like[@"name"]];
        }
        cell.likers.text = [likersArray componentsJoinedByString:@","];
        //[cell.likers sizeToFit];
        //[cell.likers setNumberOfLines:0];
        
        NSLog(@"%@", self.photo[@"comments"]);
        if (self.photo[@"comments"]) {
            cell.titleComment.text = [NSString stringWithFormat:@"%@ : %@", [self.photo[@"comments"] objectAtIndex:0][@"name"], [self.photo[@"comments"] objectAtIndex:0][@"comment"]];
        }
        
        
        return cell;
    }
    
    
}

-(void)userClickedLike:(NSNotification *)note{
    //We get the last infos of the image (maybe likes have evolved)
    PFQuery *query = [PFQuery queryWithClassName:@"Photo"];
    [query includeKey:@"user"];
    [query includeKey:@"prospect"];
    [query getObjectInBackgroundWithId:self.photo.objectId block:^(PFObject *photoObject, NSError *error) {
        if (!error) {
            self.photo = photoObject;
            
            if ([self hasLikedPhoto]) {
                [self removeCurrentUserFromLikes];
            }
            else{
                [self addCurrentUserToLikes];
            }
            
            //Save the new version
            [self.photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [self.tableView reloadData];
                }
                else{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Problem_Title", nil) message:NSLocalizedString(@"UIAlertView_Problem_Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
                    [alert show];
                }
            }];
            
        }
        else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Problem_Title", nil) message:NSLocalizedString(@"UIAlertView_Problem_Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
            [alert show];
        }
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)likeAction:(id)sender {
}

-(BOOL)hasLikedPhoto{
    for(id like in self.photo[@"likes"]){
        if ([like[@"id" ] isEqualToString:[PFUser currentUser].objectId]) {
            return YES;
        }
    }
    
    return NO;
}

-(void)removeCurrentUserFromLikes{
    NSMutableArray *tempLikes = [[NSMutableArray alloc] init];
    
    for(id like in self.photo[@"likes"]){
        if (![like[@"id"] isEqualToString:[PFUser currentUser].objectId]) {
            [tempLikes addObject:like];
        }
    }
    
    NSArray *likes = [tempLikes copy];
    self.photo[@"likes"] = likes;
}

-(void)addCurrentUserToLikes{
    NSMutableArray *tempLikes = [[NSMutableArray alloc] init];
    
    for(id like in self.photo[@"likes"]){
        [tempLikes addObject:like];
    }
    
    NSDictionary *userLiked = @{@"name": [PFUser currentUser][@"name"],
                                @"id": [PFUser currentUser].objectId,
                                @"date": [NSDate date]};
    [tempLikes addObject:userLiked];
    
    NSArray *likes = [tempLikes copy];
    self.photo[@"likes"] = likes;
}

-(void)morePhoto:(NSNotification *)note{
    NSLog(@"%@", self.photo[@"user"][@"name"]);
    PFUser *owner = (PFUser *)self.photo[@"user"];
    if ([owner.objectId isEqualToString:[PFUser currentUser].objectId]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"UIActionSheet_Cancel", nil)
                                                   destructiveButtonTitle:NSLocalizedString(@"UIActionSheet_Delete", nil)
                                                        otherButtonTitles:nil];
        [actionSheet showInView:self.view];
    }
    else{
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"UIActionSheet_Cancel", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
        [actionSheet showInView:self.view];
    }
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"The %@ button was tapped.", [actionSheet buttonTitleAtIndex:buttonIndex]);
    
    //Delete
    if (buttonIndex==0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Removal_Title", nil) message:NSLocalizedString(@"UIAlertView_Removal_Message", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"UIAlertView_No", nil) otherButtonTitles:NSLocalizedString(@"UIAlertView_Yes", nil), nil];
        [alert show];
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 1) {
		[self.photo deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [[NSNotificationCenter defaultCenter] postNotificationName:UploadPhotoFinished object:self userInfo:nil];
                [self.navigationController popViewControllerAnimated:YES];
            }
            else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Problem_Title", nil) message:NSLocalizedString(@"UIAlertView_Problem_Message2", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"UIAlertView_OK", nil) otherButtonTitles:nil, nil];
                [alert show];
            }
        }];
	} else {
	}
}

@end

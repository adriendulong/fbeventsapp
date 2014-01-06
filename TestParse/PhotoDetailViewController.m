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
#import "LikesCollectionsController.h"

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
    //self.title = NSLocalizedString(@"PhotoDetailViewController_Title", nil);
    self.navigationController.navigationBar.tintColor = [UIColor orangeColor];
    [self updateOwner];
    
    //Notifs
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userClickedLike:) name:ClickLikePhoto object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(morePhoto:) name:MorePhoto object:nil];
    
    if (self.photo[@"width"]) {
        NSLog(@"Width %@, Height %@", self.photo[@"width"], self.photo[@"height"]);
    }
    
    if (!self.photo[@"full_image"]) {
        [self.tableView setHidden:YES];
    }
    
    self.fbLikers = [[NSMutableArray alloc] init];
    [self getLikesPhotosFromFB];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Photo"];
    [query includeKey:@"user"];
    [query includeKey:@"prospect"];
    [query getObjectInBackgroundWithId:self.photo.objectId block:^(PFObject *photoObject, NSError *error) {
        if (!error) {
            [self.tableView setHidden:NO];
            self.photo = photoObject;
            [self updateOwner];
            [self.tableView reloadData];
        }
        
    }];
    
}

-(void)updateOwner{
    NSURL *pictureURL = [[NSURL alloc] init];
    
    if (self.photo[@"user"]) {
        self.nameOwner.text = self.photo[@"user"][@"name"];

        pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=normal&return_ssl_resources=1", self.photo[@"user"][@"facebookId"]]];
    }
    else{
        self.nameOwner.text = self.photo[@"prospect"][@"name"];
        
        pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=normal&return_ssl_resources=1", self.photo[@"prospect"][@"facebookId"]]];
    }
    
    //corner radius image owner photo
    self.imageOwner.layer.cornerRadius = 18.0f;
    self.imageOwner.layer.masksToBounds = YES;
    [self.imageOwner setImageWithURL:pictureURL
                    placeholderImage:[UIImage imageNamed:@"profil_default"]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==0) {
        return [self heightForImage];
    }
    else if (indexPath.row==1){
        return 50;
    }
    else if(indexPath.row == 2){
        if (self.photo[@"comments"]) {
            NSString *title = (NSString *)[self.photo[@"comments"] objectAtIndex:0][@"comment"];
            CGFloat heightSize = [title sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]}].height;
            
            return heightSize+10;
        }
        else return 0;
    }
    else{
        return 100;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.photo[@"comments"]) return 3;
    else return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //OwnerPhoto part
    /*if (indexPath.row==0) {
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
        
        //Time taken
        cell.timeTaken.text = [self lastSincePhotoTaken];
        
        return cell;
    }*/
    if (indexPath.row==0){
        static NSString *simpleTableIdentifier = @"PhotoCell";
        
        PhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        
        if (cell == nil) {
            cell = [[PhotoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }

        PFImageView *imgView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 0, 320, [self heightForImage])];
        
        
        if (self.photo[@"facebookId"]) {
            [imgView setImageWithURL:self.photo[@"facebook_url_full"]];
        }
        else{
            imgView.file = (PFFile *)self.photo[@"full_image"];
            
            [imgView loadInBackground];
        }
        
        [cell addSubview:imgView];
        
        
        
        return cell;
        
    }
    else if(indexPath.row==1) {
        static NSString *simpleTableIdentifier = @"ActionCell";
        
        ActionPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        
        if (cell == nil) {
            cell = [[ActionPhotoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        
        if ([self hasLikedPhoto:[PFUser currentUser][@"facebookId"]]) {
            [cell.likeButton setSelected:YES];
        }
        else{
            [cell.likeButton setSelected:NO];
        }
        
        NSString *message = [[NSString alloc] init];
        if ((((NSArray *)self.photo[@"likes"]).count + self.fbLikers.count) >1) {
             message = [NSString stringWithFormat:@"%i likes", (((NSArray *)self.photo[@"likes"]).count + self.fbLikers.count)];
            
        }
        else{
            message = [NSString stringWithFormat:@"%i like", (((NSArray *)self.photo[@"likes"]).count + self.fbLikers.count)];
        }
        [cell.nbPhotosButton setTitle:message forState:UIControlStateNormal];
        
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
            BOOL hasLiked = NO;
            
            if ([self hasLikedPhoto:[PFUser currentUser][@"facebookId"]]) {
                [self removeCurrentUserFromLikes];
                [self getLikesPhotosFromFB];
            }
            else{
                [self addCurrentUserToLikes];
                hasLiked = YES;
            }
            
            //Save the new version
            [self.photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    NSArray *likes = self.photo[@"likes"];
                    if (hasLiked) {
                        //Push
                        [self pushOwnerPhotoLiked];
                        [[Mixpanel sharedInstance] track:@"Like" properties:@{@"is_liked": @YES, @"Nb Likes" : [NSNumber numberWithInt:likes.count]}];
                    }
                    else{
                        [[Mixpanel sharedInstance] track:@"Like" properties:@{@"is_liked": @NO, @"Nb Likes" : [NSNumber numberWithInt:likes.count]}];
                    }
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

-(BOOL)hasLikedPhoto:(NSString *)facebookId{
    for(id like in self.photo[@"likes"]){
        if ([like[@"facebookId"] isEqualToString:facebookId]) {
            return YES;
        }
    }
    
    /*
    for(id like in self.fbLikers){
        if ([like[@"id"] isEqualToString:[PFUser currentUser][@"facebookId"]]) {
            return YES;
        }
    }*/
    
    
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
    
    if (self.photo[@"likes"]) {
        for(id like in self.photo[@"likes"]){
            [tempLikes addObject:like];
        }
    }
    
    NSLog(@"%@", [PFUser currentUser]);
    NSDictionary *userLiked = @{@"name": [PFUser currentUser][@"name"],
                                @"id": [PFUser currentUser].objectId,
                                @"facebookId" : [PFUser currentUser][@"facebookId"],
                                @"date": [NSDate date]};
    [tempLikes addObject:userLiked];
    
    NSArray *likes = [tempLikes copy];
    self.photo[@"likes"] = likes;
    [self ifLikedOnFacebookRemove:[PFUser currentUser][@"facebookId"]];
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


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if  ([buttonTitle isEqualToString:NSLocalizedString(@"UIActionSheet_Delete", nil)]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIActionSheet_Delete", nil) message:NSLocalizedString(@"PhotoDetailViewController_DeletePhoto", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"UIAlertView_No", nil) otherButtonTitles:NSLocalizedString(@"UIAlertView_Yes", nil), nil];
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
	}
}


-(float)heightForImage{
    if (self.photo[@"width"]) {
        float height = [self.photo[@"height"] floatValue];
        float width =[self.photo[@"width"] floatValue];
        
        float ratio = width/320;
        
        return height/ratio;
    }
    else{
        return 320;
    }
}


-(NSString *)lastSincePhotoTaken{
    NSDate *taken = [[NSDate alloc] init];
    NSString *response = [[NSString alloc] init];
    
    if (self.photo[@"facebookId"]) {
        taken = self.photo[@"created_time"];
    }
    else{
        taken = self.photo.createdAt;
    }
    
    NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:taken];
    NSInteger time  = distanceBetweenDates;
    
    //In seconds
    if (time<60) {
        response = [NSString stringWithFormat:@"%is", time];
    }
    //In minutes
    else if(time < 3600){
        NSInteger distanceMinutes = time/60;
        response = [NSString stringWithFormat:@"%im", distanceMinutes];
    }
    //In Hours
    else if(time < 86400){
        NSInteger distanceHours = time/3600;
        response = [NSString stringWithFormat:@"%ih", distanceHours];
    }
    //In days
    else{
        NSInteger distanceDays = time/86400;
        response = [NSString stringWithFormat:@"%ij", distanceDays];
    }
    
    return response;
    
    
}


-(void)getLikesPhotosFromFB{
    [self.fbLikers removeAllObjects];
    
    if (self.photo[@"facebookId"]) {
        NSString *requestString = [NSString stringWithFormat:@"%@/likes", self.photo[@"facebookId"]];
        
        FBRequest *request = [FBRequest requestForGraphPath:requestString];
        
        // Send request to Facebook
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                for(NSDictionary *user in result[@"data"]){
                    if(![self hasLikedPhoto:user[@"id"]]){
                        NSDictionary *userDict = @{@"id": user[@"id"],
                                                   @"name" : user[@"name"]};
                        [self.fbLikers addObject:userDict];
                    }
                    
                }
                [self.tableView reloadData];
                
                
            }
            else{
                NSLog(@"%@", error);
            }
        }];
    }
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"Likers"]) {
        
        //Remove image preview from this screen if come back
        
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
        
        NSMutableArray *likers = [[NSMutableArray alloc] init];

        [likers addObjectsFromArray:self.photo[@"likes"]];
        [likers addObjectsFromArray:self.fbLikers];

        
        LikesCollectionsController *likesCollection = segue.destinationViewController;
        likesCollection.likers = likers;
    }
}

-(void)ifLikedOnFacebookRemove:(NSString *)facebookId{
    for(NSDictionary *user in self.fbLikers){
        if([user[@"id"] isEqualToString:facebookId]){
            [self.fbLikers removeObject:user];
            break;
        }
    }
}

-(void)pushOwnerPhotoLiked{
    
    //We push only if the owner is a user of the app
    if (self.photo[@"user"]) {
        if (!([((PFUser *)self.photo[@"user"]).objectId isEqualToString:[PFUser currentUser].objectId])) {
            [PFCloud callFunction:@"pushnewlike" withParameters:@{@"photoid" : self.photo.objectId}];
        }
        
    }
    
}


@end

//
//  TestViewController.m
//  Woovent
//
//  Created by Jérémy on 04/02/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import "TestViewController.h"
#import "CommentPostCell.h"

@interface TestViewController ()

@end

@implementation TestViewController

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
    NSLog(@"TEST-CONTROLLER | viewDidLoad");
    
    self.postAndComments = [NSMutableArray array];
    
    [self getPostOnEventWall];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getPostOnEventWall {
    
    //Request
    NSString *requestString = [NSString stringWithFormat:@"%lld?fields=feed.fields(message,from,likes,comments.fields(message,from,created_time,like_count)),name", 499827973392733];//self.invitation[@"event"][@"eventId"]];
    
    NSLog(@"Request : %@", requestString);
    
    FBRequest *request = [FBRequest requestForGraphPath:requestString];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            
            //NSLog(@"result = %@", result);
            
            //NSLog(@"name = %@", result[@"name"]);
            
            for(id post in result[@"feed"][@"data"]) {
                
                NSDate *datePost = [MOUtility parseFacebookDate:post[@"created_time"] isDateOnly:NO];
                
                //NSLog(@"feed = %@", feed);
                //NSString *postString = [NSString stringWithFormat:@"%@ : %@", post[@"from"][@"name"], post[@"message"]];
                
                //NSLog(@"%@", postString);
                
                NSMutableArray *commentsArray = [NSMutableArray array];
                for (id comment in post[@"comments"][@"data"]) {
                    
                    NSDate *dateComment = [MOUtility parseFacebookDate:comment[@"created_time"] isDateOnly:NO];
                    
                    //NSString *commentString = [NSString stringWithFormat:@"%@ : %@", comment[@"from"][@"name"], comment[@"message"]];
                    
                    //NSLog(@"%@", commentString);
                    
                    NSDictionary *commentDict = @{ @"from" : comment[@"from"],
                                                   @"created_time" : dateComment,
                                                   @"like_count" : comment[@"like_count"],
                                                   @"message" : comment[@"message"] };
                    
                    [commentsArray addObject:commentDict];
                }
                
                
                
                NSDictionary *postDict = @{ @"id" : post[@"id"],
                                            @"from" : post[@"from"],
                                            @"created_time" : datePost,
                                            @"likes" : post[@"likes"][@"data"],
                                            @"message" : post[@"message"],
                                            @"comments" : commentsArray };
                
                //NSLog(@"postDict = %@", postDict);
                [self.postAndComments addObject:postDict];
                
            }
            
            //NSLog(@"postAndComments = %@", self.postAndComments);
            
            NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"created_time" ascending:NO];
            NSArray *postAndCommentsTmp = [self.postAndComments copy];
            [postAndCommentsTmp sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];

            //NSArray *recent = [postAndCommentsTmp copy];
            
            //NSLog(@"recent = %@", recent);
            
            [self.tableView reloadData];
            
        }
        else{
            NSLog(@"%@", error.localizedDescription);
        }
    }];
    
}

- (IBAction)sendMessageOnWall:(UIButton *)sender {
    
    NSDictionary *postDict = @{@"message": @"Test ;)",
                               @"picture": @"",
                               @"link": @"",
                               @"name": @"",
                               @"caption": @"",
                               @"description": @"",
                               @"source": @"",
                               @"place": @"",
                               @"tags": @""};
    
    //NSDictionary *postDict = @{@"message": @"Test ;)"};
    
    //[MOUtility postLinkOnFacebookEventWall:@"499827973392733" withUrl:nil withMessage:@"Test... "];
    [MOUtility postOnFacebooTimeline:@"499827973392733" withAttributes:postDict];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.postAndComments.count;
}

/*- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"InvitedListViewController_Presents", nil);
    }
    else if(section == 1){
        return NSLocalizedString(@"InvitedListViewController_Maybe", nil);
    }
    else if(section == 2){
        return NSLocalizedString(@"InvitedListViewController_NoResponse", nil);
    }
    else{
        return NSLocalizedString(@"InvitedListViewController_Absent", nil);
    }
}*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.postAndComments[section][@"comments"] count] + 1;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = nil;
    CommentPostCell *cell = nil;
    
    if (indexPath.row == 0) {
        CellIdentifier = @"CommentPostCell";
        cell = (CommentPostCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        NSURL *avatarUrl = [MOUtility UrlOfFacebooProfileImage:self.postAndComments[indexPath.section][@"from"][@"id"] withResolution:FacebookSquareProfileImage];
        
        [cell.avatar setImageWithURL:avatarUrl placeholderImage:[UIImage imageNamed:@"profil_default"]];
        cell.fullName.text = self.postAndComments[indexPath.section][@"from"][@"name"];
        cell.date.text = [self lastSinceCommentSent:self.postAndComments[indexPath.section][@"created_time"]];
        cell.textView.text = self.postAndComments[indexPath.section][@"message"];
    } else {
        CellIdentifier = @"CommentPostRespCell";
        cell = (CommentPostCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        NSURL *avatarUrl = [MOUtility UrlOfFacebooProfileImage:self.postAndComments[indexPath.section][@"comments"][indexPath.row-1][@"from"][@"id"] withResolution:FacebookSquareProfileImage];
        
        [cell.avatar setImageWithURL:avatarUrl placeholderImage:[UIImage imageNamed:@"profil_default"]];
        cell.fullName.text = self.postAndComments[indexPath.section][@"comments"][indexPath.row-1][@"from"][@"name"];
        cell.date.text = [self lastSinceCommentSent:self.postAndComments[indexPath.section][@"comments"][indexPath.row-1][@"created_time"]];
        cell.textView.text = self.postAndComments[indexPath.section][@"comments"][indexPath.row-1][@"message"];
    }
    
    
    
    
    //NSLog(@"cell.fullName.text = %@", cell.fullName.text);
    //NSLog(@"cell.date.text = %@", cell.date.text);
    //NSLog(@"cell.textView.text = %@", cell.textView.text);
    
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
    // Return NO if you do not want the specified item to be editable.
    return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
 }
 */


#pragma mark - NSDate to NSString
-(NSString *)lastSinceCommentSent:(NSDate *)sendDate {
    NSString *response = [[NSString alloc] init];
    
    NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:sendDate];
    NSInteger time  = distanceBetweenDates;
    
    //In seconds
    if (time<30) {
        response = NSLocalizedString(@"PhotoDetailViewController_Time_Now", nil);
    }
    else if (time<60) {
        response = [NSString stringWithFormat:NSLocalizedString(@"PhotoDetailViewController_Time_Ago", nil), time, NSLocalizedString(@"PhotoDetailViewController_Time_Second", nil)];
    }
    //In minutes
    else if(time < 3600){
        NSInteger distanceMinutes = time/60;
        response = [NSString stringWithFormat:NSLocalizedString(@"PhotoDetailViewController_Time_Ago", nil), distanceMinutes, NSLocalizedString(@"PhotoDetailViewController_Time_Minute", nil)];
    }
    //In Hours
    else if(time < 86400){
        NSInteger distanceHours = time/3600;
        response = [NSString stringWithFormat:NSLocalizedString(@"PhotoDetailViewController_Time_Ago", nil), distanceHours, NSLocalizedString(@"PhotoDetailViewController_Time_Hour", nil)];
    }
    //In days
    else{
        NSInteger distanceDays = time/86400;
        response = [NSString stringWithFormat:NSLocalizedString(@"PhotoDetailViewController_Time_Ago", nil), distanceDays, NSLocalizedString(@"PhotoDetailViewController_Time_Day", nil)];
    }
    
    return response;
    
    
}

@end

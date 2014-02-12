//
//  CommentPostViewController.m
//  Woovent
//
//  Created by Jérémy on 11/02/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import "CommentPostViewController.h"
#import "CommentPostCell.h"
#import "CommentPostToolbarCell.h"
#import "MOUtility.h"

@interface CommentPostViewController ()

@end

@implementation CommentPostViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
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
                if ((post[@"comments"][@"data"] != nil)) {
                    
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
                    
                }
                
                
                NSArray *likesArray = (post[@"likes"][@"data"] == nil) ? [NSArray array] : post[@"likes"][@"data"];
                
                //NSLog(@"likesArray = %@", likesArray);
                
                
                NSDictionary *postDict = @{ @"id" : post[@"id"],
                                            @"from" : post[@"from"],
                                            @"created_time" : datePost,
                                            @"likes" : likesArray,
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.postAndComments.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *CellIdentifier;
    if (indexPath.row == 0) {
        
        CellIdentifier = @"CommentPostCell";
        CommentPostCell *cell = (CommentPostCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        
        UIBezierPath *maskPath;
        maskPath = [UIBezierPath bezierPathWithRoundedRect:cell.subContentView.bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(2.5, 2.5)];
        
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = cell.subContentView.bounds;
        maskLayer.path = maskPath.CGPath;
        cell.subContentView.layer.mask = maskLayer;
        
        
        
        
        //cell.subContentView.layer.cornerRadius = 2.5f;
        //cell.subContentView.layer.borderColor = [UIColor colorWithRed:0.74 green:0.75 blue:0.77 alpha:1].CGColor;
        //cell.subContentView.layer.borderWidth = 0.5f;
        //cell.subContentView.layer.masksToBounds = YES;
        
        // Configure the cell...
        NSURL *avatarUrl = [MOUtility UrlOfFacebooProfileImage:self.postAndComments[indexPath.section][@"from"][@"id"] withResolution:FacebookSquareProfileImage];
        
        [cell.avatar setImageWithURL:avatarUrl placeholderImage:[UIImage imageNamed:@"profil_default"]];
        cell.fullName.text = self.postAndComments[indexPath.section][@"from"][@"name"];
        cell.date.text = [self lastSinceCommentSent:self.postAndComments[indexPath.section][@"created_time"]];
        cell.textView.text = self.postAndComments[indexPath.section][@"message"];
        cell.textView.backgroundColor = [UIColor redColor];
        cell.nbLike.text = [NSString stringWithFormat:@"%i", [self.postAndComments[indexPath.section][@"likes"] count]];
        cell.nbComment.text = [NSString stringWithFormat:@"%i", [self.postAndComments[indexPath.section][@"comments"] count]];
        
       // cell.textViewHeight.constant = 300;//[self sizeRectFromText:cell.textView.text].height;
        
        cell.textView.scrollEnabled = NO;
        
        
        return cell;
        
    } else if (indexPath.row == 1) {
        
        CellIdentifier = @"CommentPostToolbarCell";
        CommentPostToolbarCell *cell = (CommentPostToolbarCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        NSInteger nbComment = [self.postAndComments[indexPath.section][@"comments"] count];
        
        //NSLog(@"indexPath: %@ | nbComment: %i", indexPath, nbComment);
        
        if (nbComment > 0) {
            
            UIBezierPath *maskPath;
            maskPath = [UIBezierPath bezierPathWithRoundedRect:cell.subContentView.bounds byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(2.5, 2.5)];
            
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            maskLayer.frame = cell.subContentView.bounds;
            maskLayer.path = maskPath.CGPath;
            cell.subContentView.layer.mask = maskLayer;
            
            NSString *titleButton = (nbComment == 1) ? @"Afficher le commentaire" : [NSString stringWithFormat:@"Afficher les %i commentaires", nbComment];
            //NSLog(@"titleButton: %@", titleButton);
            
            [cell.showComments setTitle:titleButton forState:UIControlStateNormal];
            cell.showComments.titleLabel.textAlignment = NSTextAlignmentCenter;
            
        } else {
            [cell.showComments setTitle:@"Aucun commentaire" forState:UIControlStateNormal];
            cell.showComments.titleLabel.textAlignment = NSTextAlignmentCenter;
        }
        
        return cell;
    }
    
    
    
    return nil;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        CGFloat textViewHeight = [self sizeRectFromText:self.postAndComments[indexPath.section][@"message"]].height;
        
        return 135.0f+textViewHeight;
    } else {
        return 40.0f;
    }
}
 

/*-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 10.0;
    return 1.0;
}


-(CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == self.postAndComments.count-1)
        return 10.0;
    return 1.0;
}

-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

-(UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}*/

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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

#pragma mark - UITextView size
- (CGSize)sizeRectFromText:(NSString *)text {
    
    CGRect textRect = [text boundingRectWithSize:(CGSize){270, CGFLOAT_MAX}
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]}
                                         context:nil];
    
    NSLog(@"textView height = %f", textRect.size.height);
    
    return textRect.size;
}


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

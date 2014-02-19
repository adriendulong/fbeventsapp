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
#import "CommentDetailsPostViewController.h"

#define HEIGHT_CELL_POST 95
#define WIDTH_MESSAGE_TEXTVIEW 280

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
    
    //NSLog(@"Request : %@", requestString);
    
    FBRequest *request = [FBRequest requestForGraphPath:requestString];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            
            for(id post in result[@"feed"][@"data"]) {
                
                NSDate *datePost = [MOUtility parseFacebookDate:post[@"created_time"] isDateOnly:NO];
                
                NSMutableArray *commentsArray = [NSMutableArray array];
                if ((post[@"comments"][@"data"] != nil)) {
                    
                    
                    for (id comment in post[@"comments"][@"data"]) {
                        
                        NSDate *dateComment = [MOUtility parseFacebookDate:comment[@"created_time"] isDateOnly:NO];
                        
                        NSDictionary *commentDict = @{ @"from" : comment[@"from"],
                                                       @"created_time" : dateComment,
                                                       @"like_count" : comment[@"like_count"],
                                                       @"message" : comment[@"message"] };
                        
                        [commentsArray addObject:commentDict];
                    }
                    
                }
                
                
                NSArray *likesArray = (post[@"likes"][@"data"] == nil) ? [NSArray array] : post[@"likes"][@"data"];
                
                NSDictionary *postDict = @{ @"id" : post[@"id"],
                                            @"from" : post[@"from"],
                                            @"created_time" : datePost,
                                            @"likes" : likesArray,
                                            @"message" : post[@"message"],
                                            @"comments" : commentsArray };
                
                [self.postAndComments addObject:postDict];
                
            }
            
            NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"created_time" ascending:NO];
            NSArray *postAndCommentsTmp = [self.postAndComments copy];
            [postAndCommentsTmp sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
            
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
    return self.postAndComments.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *CellIdentifier;
    if (indexPath.row == 0) {
        
        CellIdentifier = @"CommentPostCell";
        CommentPostCell *cell = (CommentPostCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        
        [cell.contentView.layer setCornerRadius:2.5];
        [cell.contentView.layer setBorderWidth:0.5];
        [cell.contentView.layer setBorderColor:[UIColor colorWithRed:0.74 green:0.75 blue:0.77 alpha:1].CGColor];
        
        
        NSString *message = self.postAndComments[indexPath.section][@"message"];
        CGFloat textViewHeight = [self textViewHeightForAttributedText:[[NSAttributedString alloc] initWithString:message] andWidth:WIDTH_MESSAGE_TEXTVIEW];
        
        NSURL *avatarUrl = [MOUtility UrlOfFacebooProfileImage:self.postAndComments[indexPath.section][@"from"][@"id"] withResolution:FacebookSquareProfileImage];
        
        [cell.avatar setImageWithURL:avatarUrl placeholderImage:[UIImage imageNamed:@"profil_default"]];
        cell.fullName.text = self.postAndComments[indexPath.section][@"from"][@"name"];
        cell.date.text = [self lastSinceCommentSent:self.postAndComments[indexPath.section][@"created_time"]];
        cell.textView.text = message;
        
        cell.textViewHeightConstraints.constant = textViewHeight;
        
        
        
        // RESET Social Icon + Label
        cell.nbLike.hidden = NO;
        cell.thumbImageView.hidden = NO;
        cell.nbComment.hidden = NO;
        cell.commentImageView.hidden = NO;
        
        cell.thumbImageView.image = [UIImage imageNamed:@"like_woovent"];
        
        
        
        
        NSInteger nbLikes = [self.postAndComments[indexPath.section][@"likes"] count];
        NSInteger nbComments = [self.postAndComments[indexPath.section][@"comments"] count];
        
        cell.nbLike.text = [NSString stringWithFormat:@"%i", nbLikes];
        cell.nbComment.text = [NSString stringWithFormat:@"%i", nbComments];
        
        
        if (nbLikes == 0 && nbComments > 0) {
            
            cell.thumbImageView.image = [UIImage imageNamed:@"message_woovent"];
            cell.nbLike.text = [NSString stringWithFormat:@"%i", nbComments];
            
            cell.nbComment.hidden = YES;
            cell.commentImageView.hidden = YES;
        } else if (nbLikes == 0 && nbComments == 0) {
            cell.socialViewHeightConstaints.constant = 0;
        } else {
            
            if (nbComments == 0) {
                cell.nbComment.hidden = YES;
                cell.commentImageView.hidden = YES;
            }
            
            if (nbLikes == 0) {
                cell.nbLike.hidden = YES;
                cell.thumbImageView.hidden = YES;
            }
        }
        
        
        cell.textView.scrollEnabled = NO;
        cell.textView.textContainer.lineFragmentPadding = 0;
        cell.textView.textContainerInset = UIEdgeInsetsZero;
        
        [self.textViews setObject:cell.textView forKey:indexPath];
        
        [cell setNeedsUpdateConstraints];
        [cell updateConstraintsIfNeeded];
        
        
        return cell;
        
    } else if (indexPath.row == 1) {
        
        CellIdentifier = @"CommentPostToolbarCell";
        CommentPostToolbarCell *cell = (CommentPostToolbarCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        NSInteger nbComment = [self.postAndComments[indexPath.section][@"comments"] count];
        cell.showComments.tag = indexPath.section;
        
        
        if (nbComment > 0) {
            
            NSString *titleButton = (nbComment == 1) ? NSLocalizedString(@"CommentPostViewController_ShowComment", nil) : [NSString stringWithFormat:NSLocalizedString(@"CommentPostViewController_ShowNbComments", nil), nbComment];
            
            [cell.showComments setTitle:titleButton forState:UIControlStateNormal];
            cell.showComments.titleLabel.textAlignment = NSTextAlignmentCenter;
            
            cell.showComments.enabled = YES;
            
        } else {
            [cell.showComments setTitle:NSLocalizedString(@"CommentPostViewController_NoComment", nil) forState:UIControlStateNormal];
            cell.showComments.titleLabel.textAlignment = NSTextAlignmentCenter;
            
            cell.showComments.enabled = NO;
        }
        
        [cell.showComments.layer setCornerRadius:2.5];
        [cell.showComments.layer setBorderWidth:0.5];
        [cell.showComments.layer setBorderColor:[UIColor colorWithRed:0.74 green:0.75 blue:0.77 alpha:1].CGColor];
        
        
        return cell;
    }
    
    
    
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return HEIGHT_CELL_POST + [self textViewHeightForRowAtIndexPath:indexPath];
    } else {
        return 40.0f;
    }
}


-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 13.0;
    return 6.5;
}


-(CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == self.postAndComments.count-1)
        return 13.0;
    return 6.5;
}

-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

-(UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - UITextView size

- (CGFloat)textViewHeightForAttributedText: (NSAttributedString*)text andWidth: (CGFloat)width {
    UITextView *calculationView = [[UITextView alloc] init];
    [calculationView setAttributedText:text];
    CGSize size = [calculationView sizeThatFits:CGSizeMake(width, FLT_MAX)];
    
    return size.height;
}

- (CGFloat)textViewHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITextView *calculationView = [self.textViews objectForKey:indexPath];
    CGFloat textViewWidth = calculationView.frame.size.width;
    
    if (!calculationView.attributedText) {
        NSString *message = self.postAndComments[indexPath.section][@"message"];
        
        calculationView = [[UITextView alloc] init];
        calculationView.attributedText = [[NSAttributedString alloc] initWithString:message];
        textViewWidth = WIDTH_MESSAGE_TEXTVIEW;
    }
    CGSize size = [calculationView sizeThatFits:CGSizeMake(textViewWidth, FLT_MAX)];
    
    return size.height;
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

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        
        UIButton *showComments = (UIButton *)sender;
        
        if ([[segue identifier] isEqualToString:@"commentDetailsPostSegue"])
        {
            CommentDetailsPostViewController *cdpvc = [segue destinationViewController];
            
            [cdpvc setPostAndComments:self.postAndComments[showComments.tag]];
        }
    }
}

@end

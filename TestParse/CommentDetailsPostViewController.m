//
//  CommentDetailsPostViewController.m
//  Woovent
//
//  Created by Jérémy on 18/02/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import "CommentDetailsPostViewController.h"
#import "CommentPostCell.h"
#import "CommentPostRespCell.h"
#import "MOUtility.h"

#define HEIGHT_CELL_POST 95
#define WIDTH_MESSAGE_TEXTVIEW 280
#define WIDTH_MESSAGE_TEXTVIEW_RESP 238

@interface CommentDetailsPostViewController ()

@end

@implementation CommentDetailsPostViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.postAndComments[@"comments"] count]+1;
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
        
        
        NSString *message = self.postAndComments[@"message"];
        CGFloat textViewHeight = [self textViewHeightForAttributedText:[[NSAttributedString alloc] initWithString:message] andWidth:WIDTH_MESSAGE_TEXTVIEW];
        
        NSURL *avatarUrl = [MOUtility UrlOfFacebooProfileImage:self.postAndComments[@"from"][@"id"] withResolution:FacebookSquareProfileImage];
        
        [cell.avatar setImageWithURL:avatarUrl placeholderImage:[UIImage imageNamed:@"profil_default"]];
        cell.fullName.text = self.postAndComments[@"from"][@"name"];
        cell.date.text = [self lastSinceCommentSent:self.postAndComments[@"created_time"]];
        cell.textView.text = message;
        
        if ([self.postAndComments[@"likes"] count] > 0) {
            cell.nbLike.text = [NSString stringWithFormat:@"%i", [self.postAndComments[@"likes"] count]];
        } else {
            cell.nbLike.hidden = YES;
            cell.thumbImageView.hidden = YES;
            cell.socialViewHeightConstaints.constant = 0;
        }
        
        cell.textViewHeightConstraints.constant = textViewHeight;
        
        
        cell.textView.scrollEnabled = NO;
        cell.textView.textContainer.lineFragmentPadding = 0;
        cell.textView.textContainerInset = UIEdgeInsetsZero;
        
        [self.textViews setObject:cell.textView forKey:indexPath];
        
        [cell setNeedsUpdateConstraints];
        [cell updateConstraintsIfNeeded];
        
        
        return cell;
        
    } else {
        
        CellIdentifier = @"CommentPostRespCell";
        CommentPostRespCell *cell = (CommentPostRespCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        [cell.contentView.layer setCornerRadius:2.5];
        [cell.contentView.layer setBorderWidth:0.5];
        [cell.contentView.layer setBorderColor:[UIColor colorWithRed:0.74 green:0.75 blue:0.77 alpha:1].CGColor];
        
        
        NSString *message = self.postAndComments[@"comments"][indexPath.row-1][@"message"];
        CGFloat textViewHeight = [self textViewHeightForAttributedText:[[NSAttributedString alloc] initWithString:message] andWidth:WIDTH_MESSAGE_TEXTVIEW_RESP];
        
        NSURL *avatarUrl = [MOUtility UrlOfFacebooProfileImage:self.postAndComments[@"comments"][indexPath.row-1][@"from"][@"id"] withResolution:FacebookSquareProfileImage];
        
        [cell.avatar setImageWithURL:avatarUrl placeholderImage:[UIImage imageNamed:@"profil_default"]];
        cell.fullName.text = self.postAndComments[@"comments"][indexPath.row-1][@"from"][@"name"];
        cell.date.text = [self lastSinceCommentSent:self.postAndComments[@"comments"][indexPath.row-1][@"created_time"]];
        cell.textView.text = message;
        
        if ([self.postAndComments[@"comments"][indexPath.row-1][@"likes"] count] > 0) {
            cell.nbLike.hidden = NO;
            cell.thumbImageView.hidden = NO;
            
            cell.nbLike.text = [NSString stringWithFormat:@"%i", [self.postAndComments[@"comments"][indexPath.row-1][@"likes"] count]];
        } else {
            cell.nbLike.hidden = YES;
            cell.thumbImageView.hidden = YES;
        }
        
        cell.textViewHeightConstraints.constant = textViewHeight;
        
        
        cell.textView.scrollEnabled = NO;
        cell.textView.textContainer.lineFragmentPadding = 0;
        cell.textView.textContainerInset = UIEdgeInsetsZero;
        
        [self.textViews setObject:cell.textView forKey:indexPath];
        
        [cell setNeedsUpdateConstraints];
        [cell updateConstraintsIfNeeded];
        
        
        return cell;
    }
    
    
    
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row == 0) ? HEIGHT_CELL_POST + [self textViewHeightForRowAtIndexPath:indexPath] : 50.0 + [self textViewHeightForRowAtIndexPath:indexPath];
}


-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    return 13.0;
}


-(CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
    return 13.0;
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
        
        NSString *message = nil;
        if (indexPath.row == 0) {
            message = self.postAndComments[@"message"];
        } else {
            message = self.postAndComments[@"comments"][indexPath.row-1][@"message"];
        }
        
        calculationView = [[UITextView alloc] init];
        calculationView.attributedText = [[NSAttributedString alloc] initWithString:message];
        
        textViewWidth = (indexPath.row == 0) ? WIDTH_MESSAGE_TEXTVIEW : WIDTH_MESSAGE_TEXTVIEW_RESP;
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

@end

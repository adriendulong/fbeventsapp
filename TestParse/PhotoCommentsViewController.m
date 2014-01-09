//
//  PhotoCommentsViewController.m
//  Woovent
//
//  Created by Jérémy on 07/01/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import "PhotoCommentsViewController.h"
#import "CommentCell.h"

@interface PhotoCommentsViewController ()

@end

@implementation PhotoCommentsViewController

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
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    // Return the number of rows in the section.
    return self.commentsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"commentCell";
    CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[CommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *comment = [self.commentsArray objectAtIndex:indexPath.row];
    
    NSString *name = comment[@"name"];
    NSString *text = comment[@"comment"];
    NSDate *date = comment[@"date"];
    
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/mm/yyy HH:mm"];
    
    NSString *stringFromDate = [formatter stringFromDate:date];
    
    
    NSString *sentence = [NSString stringWithFormat:@"%@ %@", name, text];
    NSLog(@"sentence = %@", sentence);
    
    NSMutableAttributedString *sentenceStr = [[NSMutableAttributedString alloc] initWithString:sentence];
    NSInteger nameLenght = [name length];
    
    [sentenceStr addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:NSMakeRange(0, nameLenght)];
    [sentenceStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:14.0f] range:NSMakeRange(0, sentence.length)];
    
    

    cell.commentTextView.attributedText = sentenceStr;
    cell.timeLabel.text = stringFromDate;
    
    CGSize sizeThatShouldFitTheContent = [cell.commentTextView sizeThatFits:cell.commentTextView.frame.size];
    NSLog(@"sizeThatShouldFitTheContent.height = %f", sizeThatShouldFitTheContent.height);
    cell.heightConstraint.constant = sizeThatShouldFitTheContent.height;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary *comment = [self.commentsArray objectAtIndex:indexPath.row];
    
    NSString *name = (NSString *)comment[@"name"];
    NSString *text = (NSString *)comment[@"comment"];
    
    NSString *sentence = [NSString stringWithFormat:@"%@ %@", name, text];
    NSLog(@"sentence = %@", sentence);
    
    NSMutableAttributedString *sentenceStr = [[NSMutableAttributedString alloc] initWithString:sentence];
    NSInteger nameLenght = [name length];
    
    [sentenceStr addAttribute:NSForegroundColorAttributeName value:[UIColor orangeColor] range:NSMakeRange(0, nameLenght)];
    [sentenceStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:14.0f] range:NSMakeRange(0, sentence.length)];
    
    CGFloat textViewHeight = [self textViewHeightForAttributedText:sentenceStr andWidth:307];
    
    return textViewHeight+30;
}

- (CGFloat)textViewHeightForAttributedText:(NSAttributedString *)text andWidth:(CGFloat)width
{
    UITextView *textView = [[UITextView alloc] init];
    [textView setAttributedText:text];
    CGSize size = [textView sizeThatFits:CGSizeMake(width, FLT_MAX)];
    NSLog(@"size.height = %f", size.height);
    
    return size.height;
}

@end

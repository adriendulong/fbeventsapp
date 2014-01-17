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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.writeComment.delegate = self;
    
    self.writeComment.placeholder = NSLocalizedString(@"PhotoDetailViewController_SendComment_Placeholder", nil);
    
    self.sendComment.enabled = NO;
    self.sendComment.alpha = 0.5;
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(liftMainViewWhenKeybordAppears:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(returnMainViewToInitialposition:) name:UIKeyboardWillHideNotification object:nil];
}
- (void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    return [self.photo[@"comments"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"commentCell";
    CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[CommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *comment = [self.photo[@"comments"] objectAtIndex:indexPath.row];
    
    
    NSString *text = (comment[@"comment"] == nil) ? @"" : comment[@"comment"];
    
    const char *jsonString = [text UTF8String];
    NSData *jsonData = [NSData dataWithBytes:jsonString length:strlen(jsonString)];
    NSString *goodMsg = [[NSString alloc] initWithData:jsonData encoding:NSNonLossyASCIIStringEncoding];
    
    //NSLog(@"goodMsg = %@", goodMsg);
    
    NSString *name = comment[@"name"];
    NSDate *date = comment[@"date"];
    
    
    
    /*NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/mm/yyy HH:mm"];
    
    NSString *stringFromDate = [formatter stringFromDate:date];*/
    
    
    NSString *sentence = [NSString stringWithFormat:@"%@ %@", name, goodMsg];
    //NSLog(@"sentence = %@", sentence);
    
    NSMutableAttributedString *sentenceStr = [[NSMutableAttributedString alloc] initWithString:sentence];
    NSInteger nameLenght = [name length];
    
    [sentenceStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:110/255.0f green:111/255.0f blue:116/255.0f alpha:1.0f] range:NSMakeRange(0, sentence.length)];
    [sentenceStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:252/255.0f green:157/255.0f blue:44/255.0f alpha:1.0f] range:NSMakeRange(0, nameLenght)];
    [sentenceStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:14.0f] range:NSMakeRange(0, sentence.length)];
    [sentenceStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0f] range:NSMakeRange(0, nameLenght)];
    

    cell.commentTextView.attributedText = sentenceStr;
    cell.timeLabel.text = [self lastSinceCommentSent:date];
    
    CGSize sizeThatShouldFitTheContent = [cell.commentTextView sizeThatFits:cell.commentTextView.frame.size];
    //NSLog(@"sizeThatShouldFitTheContent.height = %f", sizeThatShouldFitTheContent.height);
    cell.heightConstraint.constant = sizeThatShouldFitTheContent.height;

    cell.commentTextView.scrollEnabled = NO;
    
    //NSLog(@"indexPath = %@", indexPath);
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary *comment = [self.photo[@"comments"] objectAtIndex:indexPath.row];
    
    NSString *name = (NSString *)comment[@"name"];
    NSString *text = ((NSString *)comment[@"comment"] == nil) ? @"" : (NSString *)comment[@"comment"];
    
    const char *jsonString = [text UTF8String];
    NSData *jsonData = [NSData dataWithBytes:jsonString length:strlen(jsonString)];
    NSString *goodMsg = [[NSString alloc] initWithData:jsonData encoding:NSNonLossyASCIIStringEncoding];
    
    NSString *sentence = [NSString stringWithFormat:@"%@ %@", name, goodMsg];
    //NSLog(@"sentence = %@", sentence);
    
    NSMutableAttributedString *sentenceStr = [[NSMutableAttributedString alloc] initWithString:sentence];
    NSInteger nameLenght = [name length];
    
    [sentenceStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:110/255.0f green:111/255.0f blue:116/255.0f alpha:1.0f] range:NSMakeRange(0, sentence.length)];
    [sentenceStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:252/255.0f green:157/255.0f blue:44/255.0f alpha:1.0f] range:NSMakeRange(0, nameLenght)];
    [sentenceStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:14.0f] range:NSMakeRange(0, sentence.length)];
    [sentenceStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0f] range:NSMakeRange(0, nameLenght)];
    
    CGFloat textViewHeight = [self textViewHeightForAttributedText:sentenceStr andWidth:307];
    
    return textViewHeight+22;
}

- (CGFloat)textViewHeightForAttributedText:(NSAttributedString *)text andWidth:(CGFloat)width
{
    UITextView *textView = [[UITextView alloc] init];
    [textView setAttributedText:text];
    CGSize size = [textView sizeThatFits:CGSizeMake(width, FLT_MAX)];
    //NSLog(@"size.height = %f", size.height);
    
    return size.height;
}

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

- (void)scrollToTableViewBottom {
    NSIndexPath* path = [NSIndexPath indexPathForRow:[self.photo[@"comments"] count]-1 inSection:0];
    [self performSelector:@selector(scrollToCell:) withObject:path afterDelay:0.3f];
}

- (void)scrollToCell:(NSIndexPath*)path {
    //NSLog(@"scrollToCell");
    [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //NSLog(@"textFieldDidBeginEditing");
    
    CGRect tableFrame = self.tableView.frame;
    tableFrame.origin.y -= 44;
    self.tableView.frame = tableFrame;
    
    if ([self.photo[@"comments"] count] > 0) {
        [self scrollToTableViewBottom];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{

    CGRect tableFrame = self.tableView.frame;
    tableFrame.origin.y += 44;
    self.tableView.frame = tableFrame;
}

- (void) liftMainViewWhenKeybordAppears:(NSNotification*)aNotification{
    NSDictionary* userInfo = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    //[[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    [self.writtingToolbar setFrame:CGRectMake(self.writtingToolbar.frame.origin.x, self.writtingToolbar.frame.origin.y - keyboardFrame.size.height, self.writtingToolbar.frame.size.width, self.writtingToolbar.frame.size.height)];
    [UIView commitAnimations];
    
    
    
    self.initialTVHeight = self.tableView.frame.size.height;
    
    CGRect initialFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect convertedFrame = [self.view convertRect:initialFrame fromView:nil];
    CGRect tvFrame = self.tableView.frame;
    tvFrame.size.height = convertedFrame.origin.y;
    self.tableView.frame = tvFrame;
}

- (void) returnMainViewToInitialposition:(NSNotification*)aNotification{
    NSDictionary* userInfo = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    [self.writtingToolbar setFrame:CGRectMake(self.writtingToolbar.frame.origin.x, self.writtingToolbar.frame.origin.y + keyboardFrame.size.height, self.writtingToolbar.frame.size.width, self.writtingToolbar.frame.size.height)];
    [UIView commitAnimations];
    
    
    
    CGRect tvFrame = self.tableView.frame;
    tvFrame.size.height = self.initialTVHeight;
    [UIView beginAnimations:@"TableViewDown" context:NULL];
    [UIView setAnimationDuration:0.3f];
    self.tableView.frame = tvFrame;
    [UIView commitAnimations];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    if (textField.text.length > 1 || (string.length > 0 && ![string isEqualToString:@""]))
    {
        self.sendComment.enabled = YES;
        self.sendComment.alpha = 1.0;
    }
    else
    {
        self.sendComment.enabled = NO;
        self.sendComment.alpha = 0.5;
    }
    
    return YES;
}

#pragma mark - Send comment
- (IBAction)sendComment:(id)sender
{
    
    if (self.writeComment.text.length > 0) {
        
        NSString *uniText = [NSString stringWithUTF8String:[self.writeComment.text UTF8String]];
        NSData *msgData = [uniText dataUsingEncoding:NSNonLossyASCIIStringEncoding];
        NSString *goodMsg = [[NSString alloc] initWithData:msgData encoding:NSUTF8StringEncoding] ;
        
        NSMutableArray *comments = (self.photo[@"comments"] == 0) ? [NSMutableArray array] : [self.photo[@"comments"] mutableCopy];
        
        NSDictionary *comment = @{@"name": [PFUser currentUser][@"name"],
                                  @"id": [PFUser currentUser].objectId,
                                  @"date": [NSDate date],
                                  @"comment":goodMsg};
        
        //NSLog(@"comment = %@", comment);
        
        
        [comments addObject:comment];
        self.photo[@"comments"] = [comments copy];
        
        //NSLog(@"self.photo[@\"comments\"] = %@", self.photo[@"comments"]);
        
        
        self.sendComment.enabled = NO;
        self.sendComment.alpha = 0.5;
        
        
        self.writeComment.text = nil;
        [self.writeComment resignFirstResponder];
        
        
        [self.tableView reloadData];
        [self scrollToTableViewBottom];
        
        
        [self.photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"Commentaire ajouté !");
                [self pushOwnerPhotoCommented:goodMsg];
                [[NSNotificationCenter defaultCenter] postNotificationName:NewCommentAdded object:self];
                
                //NSLog(@"self.photo[@\"comments\"] = %@", self.photo[@"comments"]);
            } else {
                NSLog(@"Envoi commentaire échoué...");
                
                [comments removeObject:comment];
                self.photo[@"comments"] = [comments copy];
                
                [self.tableView reloadData];
                [self scrollToTableViewBottom];
            }
            
        }];
    } /*else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UIAlertView_Title_Comment_Error", nil) message:NSLocalizedString(@"UIAlertView_Problem_Message5", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"UIAlertView_Dismiss", nil), nil];
        [alert show];
    }*/
}


-(void)pushOwnerPhotoCommented:(NSString *)comment{
    
    //We push only if the owner is a user of the app
    if (self.photo[@"user"]) {
        [PFCloud callFunction:@"pushnewcomment" withParameters:@{@"photoid" : self.photo.objectId, @"comment": comment}];
        
    }
    
}

@end

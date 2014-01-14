//
//  PhotoCommentsViewController.h
//  Woovent
//
//  Created by Jérémy on 07/01/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCommentsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) PFObject *photo;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIToolbar *writtingToolbar;
@property (weak, nonatomic) IBOutlet UITextField *writeComment;
@property (weak, nonatomic) IBOutlet UIButton *sendComment;

@property (nonatomic) CGFloat initialTVHeight;

- (IBAction)sendComment:(id)sender;

@end

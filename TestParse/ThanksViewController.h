//
//  ThanksViewController.h
//  Woovent
//
//  Created by Adrien Dulong on 02/01/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThanksViewController : UIViewController
- (IBAction)dismiss:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *terminateButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

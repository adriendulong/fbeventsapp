//
//  CGUViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 13/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CGUViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *terminateButton;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

- (IBAction)finish:(id)sender;
@end

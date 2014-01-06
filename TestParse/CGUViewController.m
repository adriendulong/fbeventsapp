//
//  CGUViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 13/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "CGUViewController.h"

@interface CGUViewController ()

@end

@implementation CGUViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    //Init
    self.title = NSLocalizedString(@"CGUViewController_title", nil);
    [self.terminateButton setTitle:NSLocalizedString(@"UIBArButtonItem_Terminate", nil)];
    
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    NSString *fullURL;
    if ([language isEqualToString:@"fr"]) {
        fullURL = @"http://woovent.com/cgu/fr";
    }
    else{
        fullURL = @"http://woovent.com/cgu/en";
    }
    
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:requestObj];
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

- (IBAction)finish:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

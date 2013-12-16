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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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

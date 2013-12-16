//
//  TutorialViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 15/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "TutorialViewController.h"

@interface TutorialViewController ()

@end

@implementation TutorialViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.iconImageView.layer.cornerRadius = 20.0f;
    self.iconImageView.layer.masksToBounds = YES;
    
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    
    if (self.index==0) {
        self.imageView.image = [UIImage imageNamed:@"tuto_step_1"];
        self.explicationLabel.text = NSLocalizedString(@"TutorialViewController_tuto_step_1", nil);
    }
    else if(self.index==1){
        self.imageView.image = [UIImage imageNamed:@"tuto_step_2"];
        self.explicationLabel.text = NSLocalizedString(@"TutorialViewController_tuto_step_2", nil);
    }
    else if(self.index == 2){
        self.imageView.image = [UIImage imageNamed:@"tuto_step_3"];
        self.explicationLabel.text = NSLocalizedString(@"TutorialViewController_tuto_step_3", nil);
    }
    else{
        self.imageView.image = [UIImage imageNamed:@"tuto_step_4"];
        self.explicationLabel.text = NSLocalizedString(@"TutorialViewController_tuto_step_4", nil);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

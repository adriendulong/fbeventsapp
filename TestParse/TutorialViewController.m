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
    
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    
    if (self.index==0) {
        self.iconImageView.image = [UIImage imageNamed:@"icon_tuto_1"];
        self.titleLabel.text = NSLocalizedString(@"TutorialViewController_tuto_title_1", nil);
        self.explicationLabel.text = NSLocalizedString(@"TutorialViewController_tuto_step_1", nil);
    }
    else if(self.index==1){
        [[Mixpanel sharedInstance] track:@"Use Tutoriel"];
        self.iconImageView.image = [UIImage imageNamed:@"icon_tuto_2"];
        self.titleLabel.text = NSLocalizedString(@"TutorialViewController_tuto_title_2", nil);
        self.explicationLabel.text = NSLocalizedString(@"TutorialViewController_tuto_step_2", nil);
    }
    else if(self.index == 2){
        self.iconImageView.image = [UIImage imageNamed:@"icon_tuto_3"];
        self.titleLabel.text = NSLocalizedString(@"TutorialViewController_tuto_title_3", nil);
        self.explicationLabel.text = NSLocalizedString(@"TutorialViewController_tuto_step_3", nil);
    }
    else{
        self.iconImageView.image = [UIImage imageNamed:@"icon_tuto_4"];
        self.titleLabel.text = NSLocalizedString(@"TutorialViewController_tuto_title_4", nil);
        self.explicationLabel.text = NSLocalizedString(@"TutorialViewController_tuto_step_4", nil);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

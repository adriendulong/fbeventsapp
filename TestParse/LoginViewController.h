//
//  LoginViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 15/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SecondDelegate <NSObject>
-(void) comingFromLogin;
@end

@interface LoginViewController : UIViewController  <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) UIPageControl *pageControl;
@property (nonatomic, assign) id<SecondDelegate> myDelegate;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *cguButton;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (strong, nonatomic) Mixpanel *mixpanel;
@property (nonatomic, assign) BOOL isNewUser;
@property (nonatomic, assign) NSInteger nextController;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;

- (IBAction)facebook:(id)sender;
-(void)updateUserInfos;

@end

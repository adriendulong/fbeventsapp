//
//  LandingViewController.h
//  Woovent
//
//  Created by Adrien Dulong on 16/01/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LandingViewController : UIViewController <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIView *winnerView;
@property (weak, nonatomic) IBOutlet UIView *looserView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UIImageView *iconViewWinner;
@property (weak, nonatomic) IBOutlet UIImageView *iconViwLooser;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintVerticalMarmotteWinner;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalConstraintViewTextWinner;
@property (strong, nonatomic) UIImage *imageScreenshot;


//Label Loading
@property (weak, nonatomic) IBOutlet UILabel *analyseLoading;
@property (weak, nonatomic) IBOutlet UIImageView *facebookOne;
@property (weak, nonatomic) IBOutlet UIImageView *facebookTwo;
@property (weak, nonatomic) IBOutlet UIImageView *facebookThree;
@property (weak, nonatomic) IBOutlet UIImageView *facebookFour;
@property (strong, nonatomic) NSTimer *facebookTimer;
@property (assign, nonatomic) int counterTimer;


//Labels Winner
@property (weak, nonatomic) IBOutlet UILabel *totalInvitationsNumber;
@property (weak, nonatomic) IBOutlet UILabel *congratsLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalInvitationsLabel;
@property (weak, nonatomic) IBOutlet UILabel *participateEventNumber;
@property (weak, nonatomic) IBOutlet UILabel *participateEventsLabel;
@property (weak, nonatomic) IBOutlet UILabel *youBeatLabel;
@property (weak, nonatomic) IBOutlet UILabel *peopleLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberPerson;
@property (weak, nonatomic) IBOutlet UIButton *buttonStartWinner;
@property (weak, nonatomic) IBOutlet UIButton *buttonChallengeWinner;
@property (weak, nonatomic) IBOutlet UILabel *notAnsweredNumber;
@property (weak, nonatomic) IBOutlet UILabel *notAnsweredText;
@property (weak, nonatomic) IBOutlet UILabel *easilyManageFBEvents;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintViewCup;



//button winner
- (IBAction)startWinner:(id)sender;
- (IBAction)challengeFriends:(id)sender;


//Step Request Facebook
@property (nonatomic, assign) NSInteger step;
@property (nonatomic, assign) NSInteger nbAttending;
@property (nonatomic, assign) NSInteger nbMaybe;
@property (nonatomic, assign) NSInteger nbDeclined;
@property (nonatomic, assign) NSInteger nbNotReplied;
@property (nonatomic, assign) NSInteger nbCreated;
@property (nonatomic, assign) NSInteger nbPeopleBehind;





- (IBAction)next:(id)sender;
@end

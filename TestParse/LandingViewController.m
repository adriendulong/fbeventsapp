//
//  LandingViewController.m
//  Woovent
//
//  Created by Adrien Dulong on 16/01/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import "LandingViewController.h"
#import "UIView-JTViewToImage.h"

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@interface LandingViewController ()

@end

@implementation LandingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [self.loadingView setHidden:NO];
    [self.winnerView setHidden:YES];
    
    //Init Labels
    
    //Label Loading
    self.analyseLoading.text = NSLocalizedString(@"LandingViewController_analyzeLoading", nil);
    
    //Label Winner
    self.congratsLabel.text = NSLocalizedString(@"LandingViewControllerWinner_congratsLabel1", nil);
    self.totalInvitationsLabel.text = NSLocalizedString(@"LandingViewControllerWinner_totalInvitationsLabel", nil);
    self.participateEventsLabel.text = NSLocalizedString(@"LandingViewControllerWinner_participateEventsLabel", nil);
    self.notAnsweredText.text = NSLocalizedString(@"LandingViewControllerWinner_notAnsweredText", nil);
    self.youBeatLabel.text = NSLocalizedString(@"LandingViewControllerWinner_youBeatLabel", nil);
    self.peopleLabel.text = NSLocalizedString(@"LandingViewControllerWinner_peopleLabel", nil);
    

    
    //Load Facebook Event
    self.step = 0;
    [self loadOldFacebookEvents:nil];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.iconView.layer.cornerRadius = 20.0f;
    self.iconView.layer.masksToBounds = YES;
    self.iconViewWinner.layer.cornerRadius = 20.0f;
    self.iconViewWinner.layer.masksToBounds = YES;
    self.iconViwLooser.layer.cornerRadius = 20.0f;
    self.iconViwLooser.layer.masksToBounds = YES;
    
    if (!IS_IPHONE_5) {
        self.constraintVerticalMarmotteWinner.constant = 77.0f;
        self.verticalConstraintViewTextWinner.constant = 55.0f;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startWinner:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)challengeFriends:(id)sender {
    [self.buttonChallengeWinner setEnabled:NO];
    
    NSString *messageToPost = [NSString stringWithFormat:NSLocalizedString(@"LandingViewControllerWinner_messageForFacebook", nil), (self.nbAttending+self.nbDeclined+self.nbMaybe+self.nbNotReplied)];
    NSString *requestString = [NSString stringWithFormat:@"me/photos"];
    FBRequest *request = [FBRequest requestWithGraphPath:requestString parameters:@{@"message":messageToPost, @"picture":UIImagePNGRepresentation(self.imageScreenshot)} HTTPMethod:@"POST"];
    
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            NSLog(@"Message posted");
            [self dismissViewControllerAnimated:YES completion:nil];
            
        }
        else{
            NSLog(@"%@", [error userInfo]);
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (IBAction)next:(id)sender {
    [self.loadingView setHidden:YES];
    [self.winnerView setHidden:NO];
}


#pragma mark - Facebook Request

-(void)loadOldFacebookEvents:(NSString *)requestFacebook{
    int startTimeInterval = (int)[[NSDate date] timeIntervalSince1970];
    NSString *stopDate = [NSString stringWithFormat:@"%i", startTimeInterval];
    
    //Request
    if (requestFacebook==nil) {
        //Attending and maybe
        if (self.step == 0) {
            requestFacebook = [NSString stringWithFormat:@"/me/events?until=%@&limit=500", stopDate];
        }
        else if(self.step == 1){
            requestFacebook = [NSString stringWithFormat:@"/me/events?fields=%@&until=%@&limit=500&type=declined",FacebookEventsFields, stopDate];
        }
        else if(self.step == 2){
            requestFacebook = [NSString stringWithFormat:@"/me/events?fields=%@&until=%@&limit=500&type=not_replied",FacebookEventsFields, stopDate];
        }
        else{
            requestFacebook = [NSString stringWithFormat:@"/me/events?fields=%@&until=%@&limit=500&type=created",FacebookEventsFields, stopDate];
        }
        
    }
    FBRequest *request = [FBRequest requestForGraphPath:requestFacebook];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            //NSLog(@"%@", result);
            
            for(id event in result[@"data"]){
                NSLog(@"RSVP : %@", event[@"rsvp_status"]);
                if (self.step == 0) {
                    if ([event[@"rsvp_status"] isEqualToString:FacebookEventAttending]) {
                        self.nbAttending++;
                    }
                    else{
                        self.nbMaybe++;
                    }
                    
                }
                else if(self.step == 1){
                    self.nbDeclined++;
                }
                else if(self.step == 2){
                    self.nbNotReplied++;
                }
                else{
                    self.nbCreated++;
                }
            }
            
            if(result[@"paging"][@"next"]){
                NSURL *previous = [NSURL URLWithString:result[@"paging"][@"next"]];
                NSLog(@"NEXT");
                NSString *goodRequest = [NSString stringWithFormat:@"%@?%@", [previous path], [previous query]];
                [self loadOldFacebookEvents:goodRequest];
            }
            else{
                self.step++;
                if (self.step<4) {
                    [self loadOldFacebookEvents:nil];
                }
                else{
                    NSLog(@"Nb Maybe : %i, Nb Attending : %i, Nombre Delcined : %i, Nombre Not Replied : %i, Nombre created : %i", self.nbMaybe, self.nbAttending, self.nbDeclined, self.nbNotReplied, self.nbCreated);
                    
                    
                    //Already stats ?
                    PFQuery *queryStats = [PFQuery queryWithClassName:@"Statistics"];
                    [queryStats whereKey:@"user" equalTo:[PFUser currentUser]];
                    [queryStats findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        if (!error) {
                            PFObject *stats;
                            if (objects.count==0) {
                                //Save on the server
                                stats = [PFObject objectWithClassName:@"Statistics"];
                            }
                            else{
                                stats = objects[0];
                            }
                            
                            [stats setObject:[PFUser currentUser] forKey:@"user"];
                            [stats setObject:[NSNumber numberWithInt:(self.nbMaybe+self.nbAttending+self.nbDeclined+self.nbNotReplied)] forKey:@"invitedEventCount"];
                            [stats setObject:[NSNumber numberWithInt:self.nbCreated] forKey:@"createdEventCount"];
                            [stats setObject:[NSNumber numberWithInt:self.nbAttending] forKey:@"attendingEventCount"];
                            [stats setObject:[NSNumber numberWithInt:self.nbMaybe] forKey:@"maybeEventCount"];
                            [stats setObject:[NSNumber numberWithInt:self.nbDeclined] forKey:@"declinedEventCount"];
                            [stats setObject:[NSNumber numberWithInt:self.nbNotReplied] forKey:@"notRepliedEventCount"];
                            [stats saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                if (succeeded) {
                                    PFQuery *countPosition = [PFQuery queryWithClassName:@"Statistics"];
                                    [countPosition whereKey:@"invitedEventCount" lessThan:stats[@"invitedEventCount"]];
                                    [countPosition countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                                        if (!error) {
                                            NSLog(@"Classement : %i", number);
                                            self.nbPeopleBehind = number;
                                            [self nextScreen];
                                        }
                                        else{
                                            NSLog(@"Problème when trying to get the classement");
                                        }
                                    }];
                                }
                                else{
                                    NSLog(@"Problème when trying to save stats");
                                }
                            }];
                        }
                        else{
                            //Do something
                            NSLog(@"Probleme when trying to see if stats already exists for this user");
                            
                        }
                    }];
                    
                    
                }
            }
            
            
            
            
            
        }
        else{
            NSLog(@"%@", error);
        }
    }];
    
}


-(void)nextScreen{
    self.totalInvitationsNumber.text = [NSString stringWithFormat:@"%d", (self.nbAttending+self.nbMaybe+self.nbDeclined+self.nbNotReplied)];
    self.participateEventNumber.text = [NSString stringWithFormat:@"%d", (self.nbAttending+self.nbMaybe)];
    self.notAnsweredNumber.text = [NSString stringWithFormat:@"%d", (self.nbDeclined+self.nbNotReplied)];
    self.numberPerson.text = [NSString stringWithFormat:@"%d", self.nbPeopleBehind];
    
    [self.loadingView setHidden:YES];
    [self.winnerView setHidden:NO];
    
    //Screenshot
    [self getSnapshotImage];
    
    
    
}

-(void)getSnapshotImage{
    self.imageScreenshot =  [self.view toImage];
    //self.imageScreenshot = viewSnapshot;
    
    //UIImageWriteToSavedPhotosAlbum(viewSnapshot, nil, nil, nil);
}


@end

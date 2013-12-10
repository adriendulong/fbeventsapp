//
//  InfoHeaderCollectionView.m
//  TestParseAgain
//
//  Created by Adrien Dulong on 08/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "InfoHeaderCollectionView.h"
#import "CameraViewController.h"

@implementation InfoHeaderCollectionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


- (IBAction)rsvpChanged:(id)sender {
    //Accept
    if(self.segmentRsvp.selectedSegmentIndex == 0){
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:@"attending"];
    }
    //Maybe
    else if (self.segmentRsvp.selectedSegmentIndex == 1){
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:@"maybe"];
    }
    //No
    else{
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:@"declined"];
    }
}

//RSVP to an event
-(void)RsvpToFbEvent:(NSString *)fbId withRsvp:(NSString *)rsvp{
    NSLog(@"Change the rsvp on FB : %@", rsvp);
    
    
    NSString *requestString = [NSString stringWithFormat:@"%@/%@", fbId, rsvp];
    FBRequest *request = [FBRequest requestWithGraphPath:requestString parameters:nil HTTPMethod:@"POST"];
    
    //@"rsvp_event"
    //If not have permission to rsvp
    FBSession *session = [PFFacebookUtils session] ;
    NSLog(@"Permissions : %@", session.permissions);
    
    BOOL rsvp_perm = [[PFUser currentUser][@"has_rsvp_perm"] boolValue];
    
    if (([session.permissions indexOfObject:@"rsvp_event"] == NSNotFound) && !rsvp_perm) {
        // if we don't already have the permission, then we request it now
        [PFFacebookUtils reauthorizeUser:[PFUser currentUser] withPublishPermissions:@[@"rsvp_event"] audience:FBSessionDefaultAudienceFriends block:^(BOOL succeeded, NSError *error) {
            
            
            //Add permission rsvp to user
            FBRequest *requestPerms = [FBRequest requestForGraphPath:@"me/permissions"];
            [requestPerms startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                
                NSArray *permissions = result[@"data"];
                if ([[permissions objectAtIndex:0][@"rsvp_event"] intValue] == 1) {
                    PFUser *currentUser =[PFUser currentUser];
                    currentUser[@"has_rsvp_perm"] = @YES;
                    [currentUser saveInBackground];
                }
                NSLog(@"TEST");
            }];
            
            
            if (succeeded) {
                NSLog(@"COOL");
            }
            
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    NSLog(@"%@", result);
                    
                    if (result[@"FACEBOOK_NON_JSON_RESULT"]) {
                        NSLog(@"OK !!");
                        //Save the new rsvp
                        self.invitation[@"rsvp_status"] = rsvp;
                        [self.invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if(!error){
                                //Warn the table view controller
                                [[NSNotificationCenter defaultCenter] postNotificationName:ModifEventsInvitationsAnswers object:self];
                            }
                            else{
                                [self.segmentRsvp setSelectedSegmentIndex:UISegmentedControlNoSegment];
                            }
                        }];
                    }
                    
                }
                else{
                    NSLog(@"%@", error);
                    [self.segmentRsvp setSelected:NO];
                }
            }];
        }];

    } else {
        // Send request to Facebook
        NSLog(@"On a la permission");
        
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                NSLog(@"%@", result);
                
                if (result[@"FACEBOOK_NON_JSON_RESULT"]) {
                    NSLog(@"OK !!");
                    //Save the new rsvp
                    self.invitation[@"rsvp_status"] = rsvp;
                    [self.invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if(!error){
                            //Warn the table view controller
                            [[NSNotificationCenter defaultCenter] postNotificationName:ModifEventsInvitationsAnswers object:self];
                        }
                        else{
                            [self.segmentRsvp setSelectedSegmentIndex:UISegmentedControlNoSegment];
                        }
                    }];
                }
                
            }
            else{
                NSLog(@"%@", error);
                [self.segmentRsvp setSelectedSegmentIndex:UISegmentedControlNoSegment];
            }
        }];
    }
    
    
}

- (IBAction)hideView:(id)sender {
    if (self.isShowingDetails) {
        self.labelHide.text = NSLocalizedString(@"InfoHeaderCollectionView_Details", nil);
        self.isShowingDetails = NO;
        [self.viewToHide setHidden:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:ShowOrHideDetailsEventNotification object:self userInfo:nil];
        
    }
    else{
        self.labelHide.text = NSLocalizedString(@"InfoHeaderCollectionView_Hide", nil);
        self.isShowingDetails = YES;
        [self.viewToHide setHidden:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:ShowOrHideDetailsEventNotification object:self userInfo:nil];
    }
}

- (IBAction)accessMap:(id)sender {
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"AddPhoto"]) {
        
        /*
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Evènements" style:UIBarButtonItemStylePlain target:nil action:nil];*/
        
        //Selected row];
        
        
        CameraViewController *cameraViewController = segue.destinationViewController;
        cameraViewController.event = self.invitation[@"event"];
    }
}
@end

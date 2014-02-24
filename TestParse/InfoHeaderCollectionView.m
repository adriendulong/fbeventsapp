//
//  InfoHeaderCollectionView.m
//  TestParseAgain
//
//  Created by Adrien Dulong on 08/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "InfoHeaderCollectionView.h"
#import "CameraViewController.h"
#import "MOUtility.h"
#import "KeenClient.h"

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
    NSDictionary *event;
    
    //Accept
    if(self.segmentRsvp.selectedSegmentIndex == 0){
        event = [NSDictionary dictionaryWithObjectsAndKeys:@"detail", @"view", FacebookEventAttending, @"answer", @"press", @"type", nil];
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:FacebookEventAttending];
    }
    //Maybe
    else if (self.segmentRsvp.selectedSegmentIndex == 1){
        event = [NSDictionary dictionaryWithObjectsAndKeys:@"detail", @"view", FacebookEventMaybeAnswer, @"answer", @"press", @"type", nil];
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:FacebookEventMaybeAnswer];
    }
    //No
    else{
        event = [NSDictionary dictionaryWithObjectsAndKeys:@"detail", @"view", FacebookEventDeclined, @"answer", @"press", @"type", nil];
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:FacebookEventDeclined];
    }
    [[KeenClient sharedClient] addEvent:event toEventCollection:@"rsvp" error:nil];
}

//RSVP to an event
-(void)RsvpToFbEvent:(NSString *)fbId withRsvp:(NSString *)rsvp{
    
    
    NSString *requestString = [NSString stringWithFormat:@"%@/%@", fbId, rsvp];
    FBRequest *request = [FBRequest requestWithGraphPath:requestString parameters:nil HTTPMethod:@"POST"];
    
    
    
    ////////////////////
    if ([FBSession.activeSession.permissions indexOfObject:@"rsvp_event"] == NSNotFound) {
        ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).comeFromFB = YES;
        [FBSession.activeSession requestNewPublishPermissions:@[@"rsvp_event"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                if (!error) {
                                                    ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).comeFromFB = NO;
                                                    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                        if (!error) {
                                                            NSLog(@"%@", result);
                                                            
                                                            if (result[@"FACEBOOK_NON_JSON_RESULT"]) {
                                                                //Save the new rsvp
                                                                NSString *oldRsvp = self.invitation[@"rsvp_status"];
                                                                self.invitation[@"rsvp_status"] = rsvp;
                                                                [self.invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                                    if(!error){
                                                                        [MOUtility setRsvp:rsvp forInvitation:self.invitation.objectId];
                                                                        [[NSNotificationCenter defaultCenter] postNotificationName:ModifEventsInvitationsAnswers object:self];
                                                                    }
                                                                    else{
                                                                        self.invitation[@"rsvp_status"] = oldRsvp;
                                                                        [self.segmentRsvp setSelectedSegmentIndex:[self segmentPositionForRsvp:self.invitation[@"rsvp"]]];
                                                                    }
                                                                }];
                                                            }
                                                            
                                                        }
                                                        else{
                                                            [self.segmentRsvp setSelectedSegmentIndex:[self segmentPositionForRsvp:self.invitation[@"rsvp"]]];
                                                        }
                                                    }];
                                                } else if (error.fberrorCategory != FBErrorCategoryUserCancelled){
                                                     ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).comeFromFB = NO;
                                                    [self.segmentRsvp setSelectedSegmentIndex:[self segmentPositionForRsvp:self.invitation[@"rsvp"]]];
                                                }
                                            }];
    }
    else{
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                
                if (result[@"FACEBOOK_NON_JSON_RESULT"]) {
                    //Save the new rsvp
                    NSString *oldRsvp = self.invitation[@"rsvp_status"];
                    self.invitation[@"rsvp_status"] = rsvp;
                    [self.invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if(!error){
                            //Warn the table view controller
                            [MOUtility setRsvp:rsvp forInvitation:self.invitation.objectId];
                            [[NSNotificationCenter defaultCenter] postNotificationName:ModifEventsInvitationsAnswers object:self];
                        }
                        else{
                            self.invitation[@"rsvp_status"] = oldRsvp;
                            [self.segmentRsvp setSelectedSegmentIndex:[self segmentPositionForRsvp:self.invitation[@"rsvp"]]];
                        }
                    }];
                }
                
            }
            else{
                [self.segmentRsvp setSelectedSegmentIndex:[self segmentPositionForRsvp:self.invitation[@"rsvp"]]];
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
        CameraViewController *cameraViewController = segue.destinationViewController;
        cameraViewController.event = self.invitation[@"event"];
    }
}


-(NSInteger)segmentPositionForRsvp:(NSString *)rsvp{
    if ([rsvp isEqualToString:FacebookEventAttending]) {
        return 0;
    }
    else if([rsvp isEqualToString:FacebookEventMaybeAnswer]){
        return 1;
    }
    else{
        return 2;
    }
}
@end

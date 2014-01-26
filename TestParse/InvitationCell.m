//
//  InvitationCell.m
//  TestParseAgain
//
//  Created by Adrien Dulong on 31/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "InvitationCell.h"
#import "MOUtility.h"

@implementation InvitationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(IBAction)rsvpChanged:(id)sender {
    [TestFlight passCheckpoint:@"CHANGE_RSVP_INVITATIONS"];
    
    
    //Accept
    if(self.rsvpSegmentedControl.selectedSegmentIndex == 0){
        NSDictionary *userInfo = @{@"invitationId": self.invitation.objectId,
                                   @"rsvp": FacebookEventAttending, @"eventId" : self.invitation[@"event"][@"eventId"]};
        [[NSNotificationCenter defaultCenter] postNotificationName:fakeAnswerEvents object:self userInfo:userInfo];
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:FacebookEventAttending oldRsvpIndex:self.rsvpSegmentedControl.selectedSegmentIndex withInvitation:self.invitation];
       
    }
    //Maybe
    else if (self.rsvpSegmentedControl.selectedSegmentIndex == 1){
        NSDictionary *userInfo = @{@"invitationId": self.invitation.objectId,
                                   @"rsvp": FacebookEventMaybeAnswer, @"eventId" : self.invitation[@"event"][@"eventId"]};
        [[NSNotificationCenter defaultCenter] postNotificationName:fakeAnswerEvents object:self userInfo:userInfo];
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:FacebookEventMaybeAnswer oldRsvpIndex:self.rsvpSegmentedControl.selectedSegmentIndex withInvitation:self.invitation];
    }
    //No
    else{
        NSDictionary *userInfo = @{@"invitationId": self.invitation.objectId,
                                   @"rsvp": FacebookEventDeclined, @"eventId" : self.invitation[@"event"][@"eventId"]};
        [[NSNotificationCenter defaultCenter] postNotificationName:fakeAnswerEvents object:self userInfo:userInfo];
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:FacebookEventDeclined oldRsvpIndex:self.rsvpSegmentedControl.selectedSegmentIndex withInvitation:self.invitation];
    }
    
    
    
}


//RSVP to an event
-(void)RsvpToFbEvent:(NSString *)fbId withRsvp:(NSString *)rsvp oldRsvpIndex:(NSInteger)oldSelected withInvitation:(PFObject *)invitation{
    
    
    NSString *requestString = [NSString stringWithFormat:@"%@/%@", fbId, rsvp];
    FBRequest *request = [FBRequest requestWithGraphPath:requestString parameters:nil HTTPMethod:@"POST"];
    
    __block NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]initWithCapacity:3];
    [userInfo setObject:invitation.objectId forKey:@"invitationId"];
    [userInfo setObject:rsvp forKey:@"rsvp"];
    

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
                                                                NSLog(@"OK !!");
                                                                //Save the new rsvp
                                                                NSString *oldRsvp = invitation[@"rsvp_status"];
                                                                invitation[@"rsvp_status"] = rsvp;
                                                                [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                                    if(!error){
                                                                        //Warn the table view controller
                                                                        [MOUtility setRsvp:rsvp forInvitation:invitation.objectId];
                                                                        [userInfo setObject:@YES forKey:@"isSuccess"];
                                                                        [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                                                                    }
                                                                    else{
                                                                        invitation[@"rsvp_status"] = oldRsvp;
                                                                        [userInfo setObject:@NO forKey:@"isSuccess"];
                                                                        [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                                                                    }
                                                                }];
                                                            }
                                                            
                                                        }
                                                        else{
                                                            [userInfo setObject:@NO forKey:@"isSuccess"];
                                                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                                                        }
                                                    }];
                                                } else if (error.fberrorCategory != FBErrorCategoryUserCancelled){
                                                     ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).comeFromFB = NO;
                                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission denied"
                                                                                                        message:@"Unable to get permission to post"
                                                                                                       delegate:nil
                                                                                              cancelButtonTitle:@"OK"
                                                                                              otherButtonTitles:nil];
                                                    [alertView show];
                                                    
                                                }
                                            }];
    }
    else{
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                NSLog(@"%@", result);
                
                if (result[@"FACEBOOK_NON_JSON_RESULT"]) {
                    NSLog(@"OK !!");
                    //Save the new rsvp
                    NSString *oldRsvp = invitation[@"rsvp_status"];
                    invitation[@"rsvp_status"] = rsvp;
                    [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if(!error){
                            //Warn the table view controller
                            [MOUtility setRsvp:rsvp forInvitation:invitation.objectId];
                            [userInfo setObject:@YES forKey:@"isSuccess"];
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                        }
                        else{
                            invitation[@"rsvp_status"] = oldRsvp;
                            [userInfo setObject:@NO forKey:@"isSuccess"];
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                        }
                    }];
                }
                
            }
            else{
                [userInfo setObject:@NO forKey:@"isSuccess"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
            }
        }];
    }
}

@end

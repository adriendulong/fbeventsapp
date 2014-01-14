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

- (IBAction)rsvpChanged:(id)sender {
    [TestFlight passCheckpoint:@"CHANGE_RSVP_INVITATIONS"];
    
    
    //Accept
    if(self.rsvpSegmentedControl.selectedSegmentIndex == 0){
        NSDictionary *userInfo = @{@"invitationId": self.invitation.objectId,
                                   @"rsvp": FacebookEventAttending, @"eventId" : self.invitation[@"event"][@"eventId"]};
        [[NSNotificationCenter defaultCenter] postNotificationName:fakeAnswerEvents object:self userInfo:userInfo];
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:FacebookEventAttending oldRsvpIndex:self.rsvpSegmentedControl.selectedSegmentIndex];
       
    }
    //Maybe
    else if (self.rsvpSegmentedControl.selectedSegmentIndex == 1){
        NSDictionary *userInfo = @{@"invitationId": self.invitation.objectId,
                                   @"rsvp": FacebookEventMaybeAnswer, @"eventId" : self.invitation[@"event"][@"eventId"]};
        [[NSNotificationCenter defaultCenter] postNotificationName:fakeAnswerEvents object:self userInfo:userInfo];
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:FacebookEventMaybeAnswer oldRsvpIndex:self.rsvpSegmentedControl.selectedSegmentIndex];
    }
    //No
    else{
        NSDictionary *userInfo = @{@"invitationId": self.invitation.objectId,
                                   @"rsvp": FacebookEventDeclined, @"eventId" : self.invitation[@"event"][@"eventId"]};
        [[NSNotificationCenter defaultCenter] postNotificationName:fakeAnswerEvents object:self userInfo:userInfo];
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:FacebookEventDeclined oldRsvpIndex:self.rsvpSegmentedControl.selectedSegmentIndex];
    }
    
    
    
}

//RSVP to an event
-(void)RsvpToFbEvent:(NSString *)fbId withRsvp:(NSString *)rsvp oldRsvpIndex:(NSInteger)oldSelected{
    
    
    NSString *requestString = [NSString stringWithFormat:@"%@/%@", fbId, rsvp];
    FBRequest *request = [FBRequest requestWithGraphPath:requestString parameters:nil HTTPMethod:@"POST"];
    
    __block NSMutableDictionary *userInfo = [[NSMutableDictionary alloc]initWithCapacity:3];
    [userInfo setObject:self.invitation.objectId forKey:@"invitationId"];
    [userInfo setObject:rsvp forKey:@"rsvp"];
    

    //If not have permission to rsvp
    FBSession *session = [PFFacebookUtils session] ;
    
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
            }];
            
            
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    NSLog(@"%@", result);
                    
                    if (result[@"FACEBOOK_NON_JSON_RESULT"]) {
                        //Save the new rsvp
                        NSString *oldRsvp = self.invitation[@"rsvp_status"];
                        self.invitation[@"rsvp_status"] = rsvp;
                        [self.invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if(!error){
                                //Warn the table view controller
                                [MOUtility setRsvp:rsvp forInvitation:self.invitation.objectId];
                                [userInfo setObject:@YES forKey:@"isSuccess"];
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                            }
                            else{
                                self.invitation[@"rsvp_status"] = oldRsvp;
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
         }];
    } else {
        // Send request to Facebook
        
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                NSLog(@"%@", result);
                
                if (result[@"FACEBOOK_NON_JSON_RESULT"]) {
                    NSLog(@"OK !!");
                    //Save the new rsvp
                    NSString *oldRsvp = self.invitation[@"rsvp_status"];
                    self.invitation[@"rsvp_status"] = rsvp;
                    [self.invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if(!error){
                            //Warn the table view controller
                            [MOUtility setRsvp:rsvp forInvitation:self.invitation.objectId];
                            [userInfo setObject:@YES forKey:@"isSuccess"];
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                        }
                        else{
                            self.invitation[@"rsvp_status"] = oldRsvp;
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

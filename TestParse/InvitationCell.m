//
//  InvitationCell.m
//  TestParseAgain
//
//  Created by Adrien Dulong on 31/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "InvitationCell.h"

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
    NSLog(@"Changed : %i", self.rsvpSegmentedControl.selectedSegmentIndex);
    
    //Accept
    if(self.rsvpSegmentedControl.selectedSegmentIndex == 0){
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:@"attending" oldRsvpIndex:self.rsvpSegmentedControl.selectedSegmentIndex];
    }
    //Maybe
    else if (self.rsvpSegmentedControl.selectedSegmentIndex == 1){
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:@"maybe" oldRsvpIndex:self.rsvpSegmentedControl.selectedSegmentIndex];
    }
    //No
    else{
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:@"declined" oldRsvpIndex:self.rsvpSegmentedControl.selectedSegmentIndex];
    }
    
    
    
}

//RSVP to an event
-(void)RsvpToFbEvent:(NSString *)fbId withRsvp:(NSString *)rsvp oldRsvpIndex:(NSInteger)oldSelected{
    NSLog(@"Change the rsvp on FB : %@", rsvp);
    
    
    NSString *requestString = [NSString stringWithFormat:@"%@/%@", fbId, rsvp];
    FBRequest *request = [FBRequest requestWithGraphPath:requestString parameters:nil HTTPMethod:@"POST"];
    
    __block NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.invitation.objectId forKey:@"invitationId"];
    
    //@"rsvp_event"
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
                NSLog(@"TEST");
            }];
            
            
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
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                            }
                            else{
                                [self.rsvpSegmentedControl setSelectedSegmentIndex:self.rsvpSegmentedControl.selectedSegmentIndex];
                            }
                        }];
                    }
                    
                }
                else{
                    NSLog(@"%@", error);
                    [self.rsvpSegmentedControl setSelectedSegmentIndex:self.rsvpSegmentedControl.selectedSegmentIndex];
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
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self userInfo:userInfo];
                        }
                        else{
                            [self.rsvpSegmentedControl setSelectedSegmentIndex:self.rsvpSegmentedControl.selectedSegmentIndex];
                        }
                    }];
                }
                
            }
            else{
                NSLog(@"%@", error);
                [self.rsvpSegmentedControl setSelectedSegmentIndex:self.rsvpSegmentedControl.selectedSegmentIndex];
            }
        }];
    }
    
    
}

@end

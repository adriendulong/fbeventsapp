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
        [self RsvpToFbEvent:self.invitation[@"event"][@"eventId"] withRsvp:@"attending"];
    }
    //Maybe
    else if (self.rsvpSegmentedControl.selectedSegmentIndex == 1){
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
    
    if ([session.permissions indexOfObject:@"rsvp_event"] == NSNotFound) {
        // if we don't already have the permission, then we request it now
        [FBSession.activeSession
         requestNewPublishPermissions:[NSArray arrayWithObject:@"rsvp_event"]
         defaultAudience:FBSessionDefaultAudienceFriends
         completionHandler:^(FBSession *session, NSError *error) {
             if (!error) {
                 NSLog(@"Permission obetnue");
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
                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self];
                                 }
                                 else{
                                     [self.rsvpSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
                                 }
                             }];
                         }
                         
                     }
                     else{
                         NSLog(@"%@", error);
                         [self.rsvpSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
                     }
                 }];
             }
             else{
                 NSLog(@"Problem when trying to get the rights.");
                 [self.rsvpSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
             }
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
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RsvpChanged" object:self];
                        }
                        else{
                            [self.rsvpSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
                        }
                    }];
                }
                
            }
            else{
                NSLog(@"%@", error);
                [self.rsvpSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
            }
        }];
    }
    
    
}

@end

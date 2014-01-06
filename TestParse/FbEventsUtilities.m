//
//  FbEventsUtilities.m
//  TestParseAgain
//
//  Created by Adrien Dulong on 01/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "FbEventsUtilities.h"
#import "MOUtility.h"
#import "EventUtilities.h"

@implementation FbEventsUtilities


+(void)saveEvent:(NSDictionary *)event{
    
    
    //See if the event already exist
    PFQuery *query = [PFQuery queryWithClassName:@"Event"];
    [query whereKey:@"eventId" equalTo:event[@"id"]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (error && error.code == kPFErrorObjectNotFound) {
            [self createEvent:event];
        }
        else{
            [self updateEvent:event compareTo:object];
        }
    }];
    
}


+(void)createEvent:(NSDictionary *)event{
    //We create the event
    PFObject *eventObject = [PFObject objectWithClassName:@"Event"];
    eventObject[@"eventId"] = event[@"id"];
    eventObject[@"name"] = event[@"name"];
    
    if(event[@"location"]){
        eventObject[@"location"] = event[@"location"];
    }
    
    if(event[@"start_time"]){
        eventObject[@"start_time"] =  [MOUtility parseFacebookDate:event[@"start_time"] isDateOnly:[event[@"is_date_only"] boolValue]];
    }
    
    if(event[@"end_time"]){
        eventObject[@"end_time"] = [MOUtility parseFacebookDate:event[@"end_time"] isDateOnly:[event[@"is_date_only"] boolValue]];
    }
    
    if (event[@"description"]) {
        eventObject[@"description"] = event[@"description"];
    }
    
    if (event[@"cover"]) {
        eventObject[@"cover"] = event[@"cover"][@"source"];
    }
    
    if (event[@"owner"]) {
        eventObject[@"owner"] = event[@"owner"];
    }
    
    if (event[@"admins"]) {
        eventObject[@"admins"] = event[@"admins"][@"data"];
        
    }
    
    if(event[@"is_date_only"]){
        eventObject[@"is_date_only"] = event[@"is_date_only"];
    }
    
    if (event[@"venue"]) {
        eventObject[@"venue"] = event[@"venue"];
    }
    
    //
    
    //Save in the background, and associate it to the user when created
    [eventObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(!error){
            PFObject *invitation = [PFObject objectWithClassName:@"Invitation"];
            [invitation setObject:eventObject forKey:@"event"];
            [invitation setObject:[PFUser currentUser] forKey:@"user"];
            invitation[@"rsvp_status"] = event[@"rsvp_status"];
            invitation[@"start_time"] = eventObject[@"start_time"];
            
            invitation[@"isOwner"] = @NO;
            invitation[@"isAdmin"] = @NO;
            
            if([EventUtilities isOwnerOfEvent:eventObject forUser:[PFUser currentUser]])
            {
                invitation[@"isOwner"] = @YES;
            }
            
            if ([EventUtilities isAdminOfEvent:eventObject forUser:[PFUser currentUser]]) {
                invitation[@"isAdmin"] = @YES;
            }
            
            
            
            [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:event[@"rsvp_status"] forKey:@"rsvp"];
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"FacebookEventUploaded"
                 object:self userInfo:userInfo];
            }];
        }
        else{
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:event[@"rsvp_status"] forKey:@"rsvp"];
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"FacebookEventUploaded"
             object:self userInfo:userInfo];
        }
    }];
}

//The event already exists, we update it, and add an invite if the user is not invited yet
+(void)updateEvent:(NSDictionary *)event compareTo:(PFObject *)eventToCompare{
    NSNull *null = [NSNull null];
    
    //If the update date is superior to the update date of the saved object
    NSDate *updated_time = [MOUtility parseFacebookDate:event[@"updated_time"]  isDateOnly:NO];
    if([updated_time compare:eventToCompare.updatedAt] == NSOrderedDescending){
        if(event[@"name"]){
            eventToCompare[@"name"] = event[@"name"];
        }
        
        //LOCATION
        if(event[@"location"]){
            eventToCompare[@"location"] = event[@"location"];
        }
        
        if(event[@"venue"]){
            eventToCompare[@"venue"] = event[@"venue"];
        }
        
        
        //START TIME
        if(event[@"start_time"]){
            NSDate *startDate = [MOUtility parseFacebookDate:event[@"start_time"]  isDateOnly:[event[@"is_date_only"] boolValue]];
            eventToCompare[@"start_time"] = startDate;
        }
        else{
            if(eventToCompare[@"start_time"]){
                eventToCompare[@"start_time"] = null;
            }
        }
        
        //END TIME
        if(event[@"end_time"]){
            NSDate *endDate = [MOUtility parseFacebookDate:event[@"end_time"]  isDateOnly:[event[@"is_date_only"] boolValue]];
            eventToCompare[@"end_time"] = endDate;
        }
        else{
            if(eventToCompare[@"end_time"]){
                eventToCompare[@"end_time"] = null;
            }
        }
        
        //DESCRIPTION
        if(event[@"description"]){
            eventToCompare[@"description"] = event[@"description"];
        }
        
        //COVER
        if(event[@"cover"]){
            eventToCompare[@"cover"] = event[@"cover"][@"source"];
        }
        
        //OWNER
        if(event[@"owner"]){
            eventToCompare[@"owner"] = event[@"owner"];
        }
        
        
        //ADMINS
        if(event[@"admins"]){
            eventToCompare[@"admins"] = event[@"admins"][@"data"];
        }
        
        [eventToCompare saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [EventUtilities userInvitationToEvent:eventToCompare forUser:[PFUser currentUser] forRsvp:event[@"rsvp_status"]];
        }];
    }
    else{
        [EventUtilities userInvitationToEvent:eventToCompare forUser:[PFUser currentUser] forRsvp:event[@"rsvp_status"]];
    }
    
    //We see if the user is already invited to this event
    
    
}

+(PFObject *)getProspectOrUserFromInvitation:(PFObject *)invitation{
    PFObject *guest;
    if (invitation[@"user"]) {
        guest = invitation[@"user"];
    }
    else{
        guest = invitation[@"prospect"];
    }
    
    return guest;
}

@end

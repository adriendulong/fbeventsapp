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


//////////////// OLD SAVE EVENT ////////////////

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


////////////// NEW BFTASK SAVE EVENT ////////////////////

+(BFTask *)saveEventAsync:(NSDictionary *)eventDict{
    BFTaskCompletionSource *taskSave = [BFTaskCompletionSource taskCompletionSource];
    
    
    //
    // EVENT exists ?
    //
    
    [[FbEventsUtilities isEventExistsAsync:eventDict] continueWithBlock:^id(BFTask *task) {
        if(task.error){
            NSLog(@"Error me : %@", [task.error localizedDescription]);
            [taskSave setError:task.error];
        }
        else{
            
            //
            // Event exists
            //
            if (task.result!=nil) {
                NSLog(@"Exists");
                
                //See if invitations exist
                PFObject *event = (PFObject *)task.result;
                
                [[[FbEventsUtilities updateEventAsync:eventDict compareTo:event] continueWithBlock:^id(BFTask *task) {
                    
                    ///
                    /// Invitations exists ?
                    ///
                    return [FbEventsUtilities userInvitationToEventAsync:event forUser:[PFUser currentUser]];
                }] continueWithBlock:^id(BFTask *task) {
                    //
                    // Error
                    //
                    if (task.error) {
                        [taskSave setError:task.error];
                        NSLog(@"Error : %@", task.error.userInfo[@"error"]);
                    }
                    else{
                        
                        //
                        // Invitation exists
                        //
                        
                        if (task.result!=nil) {
                            NSLog(@"Invitation exists");
                            
                            //
                            // Update invitation
                            //
                            
                            [[FbEventsUtilities updateInviteUser:[PFUser currentUser] toEvent:event withRsvp:eventDict[@"rsvp_status"] withInvitation:(PFObject *)task.result] continueWithBlock:^id(BFTask *task) {
                                if (task.error) {
                                    [taskSave setError:task.error];
                                }
                                else{
                                    [taskSave setResult:task.result];
                                }
                                
                                return nil;
                            }];
                        }
                        
                        //
                        //No invitation
                        //
                        
                        else{
                            NSLog(@"No invitations");
                            
                            //
                            // Create invitation
                            //
                            
                            [[FbEventsUtilities createInvitationAsync:event forRSVP:eventDict[@"rsvp_status"]] continueWithBlock:^id(BFTask *task) {
                                if (task.error) {
                                    [taskSave setError:task.error];
                                    NSLog(@"error");
                                }
                                else{
                                    [taskSave setResult:task.result];
                                    NSLog(@"Invitation created");
                                }
                                return nil;
                            }];
                        }
                    }
                    
                    return nil;
                }];
                
                

                
            }
            
            //
            // Event does not exist
            //
            else{
                //Create event
                [[[FbEventsUtilities createEventAsync:eventDict] continueWithSuccessBlock:^id(BFTask *task) {
                    
                    //Create invitations
                    return [FbEventsUtilities createInvitationAsync:(PFObject *)task.result forRSVP:eventDict[@"rsvp_status"]];
                }] continueWithBlock:^id(BFTask *task) {
                    //Error
                    if (task.error) {
                        [taskSave setError:task.error];
                    }
                    //Created
                    else{
                        [taskSave setResult:task.result];
                    }
                    return nil;
                }];
            }
            
        }
        
        return nil;
    }];
    
    return taskSave.task;
}

/*
 Event exists
 */

+(BFTask *)isEventExistsAsync:(NSDictionary *)event{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    
    //See if the event already exist
    PFQuery *query = [PFQuery queryWithClassName:@"Event"];
    [query whereKey:@"eventId" equalTo:event[@"id"]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //No object found and there is no error
        if (error && error.code == kPFErrorObjectNotFound) {
            //[self createEvent:event];
            [task setResult:nil];
        }
        //There is an object
        else if(object!=nil){
            [task setResult:object];
            //[self updateEvent:event compareTo:object];
        }
        //Error
        else{
            NSLog(@"Error request");
            [task setError:error];
        }
    }];
    
    return task.task;
}


//////////////// OLD CREATE EVENT ////////////////

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



////////////// NEW BFTASK CREATE EVENT ////////////////////

+(BFTask *)createEventAsync:(NSDictionary *)event{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    
    
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
            [task setResult:eventObject];

        }
        else{
            [task setError:error];

        }
    }];
    
    return task.task;
}






////////// OLD UPDATE EVENT /////////////////////

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
}

///////// NEW UPDATE EVENT ASYNC ////////////////////////////

+(BFTask *)updateEventAsync:(NSDictionary *)event compareTo:(PFObject *)eventToCompare{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    NSNull *null = [NSNull null];
    
    //If the update date is superior to the update date of the saved object
    NSDate *updated_time = [MOUtility parseFacebookDate:event[@"updated_time"]  isDateOnly:NO];
    //if(!([updated_time compare:eventToCompare.updatedAt] == NSOrderedDescending)){
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
        
        [eventToCompare saveInBackground];
        
        /*[eventToCompare saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [EventUtilities userInvitationToEvent:eventToCompare forUser:[PFUser currentUser] forRsvp:event[@"rsvp_status"]];
        }];*/
    //}
    /*else{
        [EventUtilities userInvitationToEvent:eventToCompare forUser:[PFUser currentUser] forRsvp:event[@"rsvp_status"]];
    }*/
    
    [task setResult:eventToCompare];
    return task.task;
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



#pragma mark - Invitations

/*
 Create invitation to an event for the current user
 */

+(BFTask *)createInvitationAsync:(PFObject *)event forRSVP:(NSString *)rsvp{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    
    PFObject *invitation = [PFObject objectWithClassName:@"Invitation"];
    [invitation setObject:event forKey:@"event"];
    [invitation setObject:[PFUser currentUser] forKey:@"user"];
    invitation[@"rsvp_status"] = rsvp;
    invitation[@"start_time"] = event[@"start_time"];
    //invitation[@"start_time"] = [NSDate date];
    
    invitation[@"isOwner"] = @NO;
    invitation[@"isAdmin"] = @NO;
    
    if([EventUtilities isOwnerOfEvent:event forUser:[PFUser currentUser]])
    {
        invitation[@"isOwner"] = @YES;
    }
    
    if ([EventUtilities isAdminOfEvent:event forUser:[PFUser currentUser]]) {
        invitation[@"isAdmin"] = @YES;
    }
    
    
    
    [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [task setResult:invitation];
        }
        else{
            [task setError:error];
        }
        
        /*NSDictionary *userInfo = [NSDictionary dictionaryWithObject:event[@"rsvp_status"] forKey:@"rsvp"];
         [[NSNotificationCenter defaultCenter]
         postNotificationName:@"FacebookEventUploaded"
         object:self userInfo:userInfo];*/
    }];
    
    return task.task;
    
}

/*
 Update the invitation
*/

+(BFTask *)updateInviteUser:(PFUser *)user toEvent:(PFObject *)event withRsvp:(NSString *)rsvp withInvitation:(PFObject *)invitation{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    BOOL needToUpdate = NO;
    
    if(![invitation[@"rsvp_status"] isEqualToString:rsvp]){
        invitation[@"rsvp_status"] = rsvp;
        needToUpdate = YES;
    }
    
    if (!invitation[@"is_memory"]) {
        invitation[@"is_memory"] = @YES;
        needToUpdate = YES;
    }
    
    
    if([EventUtilities isOwnerOfEvent:event forUser:user])
    {
        if(!invitation[@"isOwner"]){
            invitation[@"isOwner"] = @YES;
            needToUpdate = YES;
        }
        
    }
    
    if ([EventUtilities isAdminOfEvent:event forUser:user]) {
        if (!invitation[@"isAdmin"]) {
            invitation[@"isAdmin"] = @YES;
            needToUpdate = YES;
        }
    }
    
    NSDate *invitDate = (NSDate *)invitation[@"start_time"];
    NSDate *eventDate = (NSDate *)event[@"start_time"];
    
    if (![invitDate isEqualToDate:eventDate]) {
        needToUpdate = YES;
        invitation[@"start_time"] = event[@"start_time"];
    }
    
    if(needToUpdate){
        [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [task setResult:invitation];
            }
            else{
                [task setError:error];
            }
            
            /*NSDictionary *userInfo = [NSDictionary dictionaryWithObject:rsvp forKey:@"rsvp"];
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"FacebookEventUploaded"
             object:self userInfo:userInfo];*/
        }];
    }
    else{
        [task setResult:invitation];
        
        /*NSDictionary *userInfo = [NSDictionary dictionaryWithObject:rsvp forKey:@"rsvp"];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"FacebookEventUploaded"
         object:self userInfo:userInfo];*/
    }
    
    return task.task;
    
}

/*
 If the user have an invitation for this event
 */

+(BFTask *)userInvitationToEventAsync:(PFObject *)event forUser:(PFUser *)user{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:user];
    [query whereKey:@"event" equalTo:event];
    
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (error && error.code == kPFErrorObjectNotFound) {
            //[self createEvent:event];
            [task setResult:nil];
        }
        //There is an object
        else if(object!=nil){
            [task setResult:object];
            //[self updateEvent:event compareTo:object];
        }
        //Error
        else{
            [task setError:error];
        }
        
    }];
    
    return task.task;
}


#pragma mark - End Time
+(NSDate *)getEndDateEvent:(PFObject *)event{
    NSDate *end_date;
    NSDate *start_date = (NSDate *)event[@"start_time"];
    
    if (event[@"end_time"]) {
        end_date = (NSDate *)event[@"end_time"];
    }
    else{
        if (event[@"is_date_only"]) {
            end_date = [start_date dateByAddingTimeInterval:1*3600];
        }
        else{
            end_date = [start_date dateByAddingTimeInterval:1*3600];
        }
    }
    
    return end_date;
}

@end

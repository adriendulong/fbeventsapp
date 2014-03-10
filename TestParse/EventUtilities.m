//
//  EventUtilities.m
//  TestParse
//
//  Created by Adrien Dulong on 29/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "EventUtilities.h"
#import "MOUtility.h"

@implementation EventUtilities


+(BOOL)isAdminOfEvent:(PFObject *)event forUser:(PFObject *)user{
    BOOL isAdmin = NO;
    
    
    if(event[@"admin"]){
        NSArray *admins = [event objectForKey:@"admins"];
        
        for(id admin in admins){
            if ([admin[@"id"] isEqualToString:user[@"facebookId"]]) {
                isAdmin = YES;
                NSLog(@"iss ADMIN");
                return isAdmin;
            }
        }
    }
    
    return isAdmin;
}

+(BOOL)isOwnerOfEvent:(PFObject *)event forUser:(PFObject *)user{
    BOOL isOwner = NO;
    
    if (event[@"owner"]) {
        if([event[@"owner"][@"id"] isEqualToString:user[@"facebookId"]])
        {
            isOwner = YES;
        }
    }
    return isOwner;
}

+(void)userInvitationToEvent:(PFObject *)event forUser:(PFUser *)user forRsvp:(NSString *)rsvp{
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:user];
    [query whereKey:@"event" equalTo:event];
    
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(object){
            [EventUtilities updateInviteUser:user toEvent:event withRsvp:rsvp withInvitation:object];
        }
        else{
            [EventUtilities inviteUser:user toEvent:event withRsvp:rsvp];
            
        }
        
    }];
}


+(void)inviteUser:(PFUser *)user toEvent:(PFObject *)event withRsvp:(NSString *)rsvp{
    
    PFObject *invitation = [PFObject objectWithClassName:@"Invitation"];
    [invitation setObject:event forKey:@"event"];
    [invitation setObject:user forKey:@"user"];
    invitation[@"is_memory"] = @YES;
    invitation[@"rsvp_status"] = rsvp;
    invitation[@"start_time"] = event[@"start_time"];
    
    invitation[@"isOwner"] = @NO;
    invitation[@"isAdmin"] = @NO;
    
    if([EventUtilities isOwnerOfEvent:event forUser:user])
    {
        invitation[@"isOwner"] = @YES;
    }
    
    if ([EventUtilities isAdminOfEvent:event forUser:user]) {
        invitation[@"isAdmin"] = @YES;
    }
    
    
    [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:rsvp forKey:@"rsvp"];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"FacebookEventUploaded"
         object:self userInfo:userInfo];
    }];
}


+(void)updateInviteUser:(PFUser *)user toEvent:(PFObject *)event withRsvp:(NSString *)rsvp withInvitation:(PFObject *)invitation{
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
    if (![invitation[@"start_time"] isEqualToDate:event[@"start_time"]]) {
        needToUpdate = YES;
        invitation[@"start_time"] = event[@"start_time"];
    }
    
    if(needToUpdate){
       [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
           
           NSDictionary *userInfo = [NSDictionary dictionaryWithObject:rsvp forKey:@"rsvp"];
           [[NSNotificationCenter defaultCenter]
            postNotificationName:@"FacebookEventUploaded"
            object:self userInfo:userInfo];
       }];
    }
    else{
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:rsvp forKey:@"rsvp"];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"FacebookEventUploaded"
         object:self userInfo:userInfo];
    }
    
}

+(void)setBadgeForInvitation:(UITabBarController *)controller atIndex:(NSUInteger)index{
    
    //From local database
    int countInvit = [MOUtility countFutureInvitations];
    if(countInvit>0){
        [[[[controller tabBar] items] objectAtIndex:index] setBadgeValue:[NSString stringWithFormat:@"%d", countInvit]];
    }
    else{
        [[[[controller tabBar] items] objectAtIndex:index] setBadgeValue:nil];
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"rsvp_status" equalTo:@"not_replied"];
    [query whereKey:@"start_time" greaterThan:[NSDate date]];
    
    #warning Modify Cache Policy
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (!error) {
            // The count request succeeded. Log the count
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
            if(count>0){
               [[[[controller tabBar] items] objectAtIndex:index] setBadgeValue:[NSString stringWithFormat:@"%d", count]];
            }
            else{
                [[[[controller tabBar] items] objectAtIndex:index] setBadgeValue:nil];
            }
        } else {
            // The request failed
        }
    }];
}

+(NSDate *)endDateForStart:(NSDate *)startDate withType:(NSNumber *)type andLast:(NSNumber *)lastTime{
    
    int realLast;
    int last = [lastTime intValue];
    
    //Party (add 6 jours)
    if ([type isEqualToNumber:[NSNumber numberWithInt:1]]) {
        realLast = last + 6;
    }
    //Day (add 12 hours)
    else if ([type isEqualToNumber:[NSNumber numberWithInt:2]]){
        realLast = last + 12;
    }
    //Week-End (Add 24 hours)
    else if ([type isEqualToNumber:[NSNumber numberWithInt:3]]){
        realLast = last + 24;
    }
    
    //Holidays (add 72 hours)
    else {
        realLast = last + 72;
    }
    
    NSDate *endDate = [startDate dateByAddingTimeInterval:3600*realLast];
    
    return endDate;
    
}


+(NSDate *)endDateForStart:(NSDate *)startDate withType:(NSNumber *)type andEndDate:(NSDate *)endDate{
    
    int add;
    
    //Party (add 6 jours)
    if ([type isEqualToNumber:[NSNumber numberWithInt:1]]) {
        add = 6;
    }
    //Day (add 12 hours)
    else if ([type isEqualToNumber:[NSNumber numberWithInt:2]]){
        add = 12;
    }
    //Week-End (Add 24 hours)
    else if ([type isEqualToNumber:[NSNumber numberWithInt:3]]){
        add =  24;
    }
    
    //Holidays (add 72 hours)
    else {
        add = 72;
    }
    
    NSDate *endDateFinal = [endDate dateByAddingTimeInterval:3600*add];
    
    return endDateFinal;
    
}


@end

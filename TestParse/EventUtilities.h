//
//  EventUtilities.h
//  TestParse
//
//  Created by Adrien Dulong on 29/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EventUtilities : NSObject

+(BOOL)isAdminOfEvent:(PFObject *)event forUser:(PFObject *)user;
+(BOOL)isOwnerOfEvent:(PFObject *)event forUser:(PFObject *)user;
+(void)userInvitationToEvent:(PFObject *)event forUser:(PFUser *)user forRsvp:(NSString *)rsvp;
+(void)inviteUser:(PFUser *)user toEvent:(PFObject *)event withRsvp:(NSString *)rsvp;
+(void)updateInviteUser:(PFUser *)user toEvent:(PFObject *)event withRsvp:(NSString *)rsvp withInvitation:(PFObject *)invitation;
+(void)setBadgeForInvitation:(UITabBarController *)controller atIndex:(NSUInteger)index;
+(NSDate *)endDateForStart:(NSDate *)startDate withType:(NSNumber *)type andLast:(NSNumber *)lastTime;
+(NSDate *)endDateForStart:(NSDate *)startDate withType:(NSNumber *)type andEndDate:(NSDate *)endDate;

@end

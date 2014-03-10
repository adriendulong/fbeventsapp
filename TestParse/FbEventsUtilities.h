//
//  FbEventsUtilities.h
//  TestParseAgain
//
//  Created by Adrien Dulong on 01/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FbEventsUtilities : NSObject

+(void)saveEvent:(NSDictionary *)event;
+(BFTask *)saveEventAsync:(NSDictionary *)event;
+(BFTask *)isEventExistsAsync:(NSDictionary *)event;
+(void)createEvent:(NSDictionary *)event;
+(BFTask *)createEventAsync:(NSDictionary *)event;
+(void)updateEvent:(NSDictionary *)event compareTo:(PFObject *)eventToCompare;
+(PFObject *)getProspectOrUserFromInvitation:(PFObject *)invitation;

#pragma mark - Invitations
+(BFTask *)createInvitationAsync:(PFObject *)event forRSVP:(NSString *)rsvp;
+(BFTask *)updateInviteUser:(PFUser *)user toEvent:(PFObject *)event withRsvp:(NSString *)rsvp withInvitation:(PFObject *)invitation;
+(BFTask *)userInvitationToEventAsync:(PFObject *)event forUser:(PFUser *)user;

#pragma makr - End Time
+(NSDate *)getEndDateEvent:(PFObject *)event;

@end

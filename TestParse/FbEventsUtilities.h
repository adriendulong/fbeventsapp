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
+(void)createEvent:(NSDictionary *)event;
+(void)updateEvent:(NSDictionary *)event compareTo:(PFObject *)eventToCompare;
+(PFObject *)getProspectOrUserFromInvitation:(PFObject *)invitation;

@end

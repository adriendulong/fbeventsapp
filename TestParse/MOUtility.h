//
//  MOUtility.h
//  TestParse
//
//  Created by Adrien Dulong on 16/10/13.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MOUtility : NSObject

#pragma mark - Email
+(BOOL)isValidEmailAddress:(NSString *)emailaddress;

#pragma mark - Date
+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;

#pragma mark - Facebook
+(NSURL *)UrlOfFacebooProfileImage:(NSString *)profileId;
+(NSDate *)parseFacebookDate:(NSString *)date isDateOnly:(BOOL)isDateOnly;

#pragma mark - Colors
+(UIColor*)colorWithHexString:(NSString*)hex;

#pragma mark - Image
+(CGSize)newBoundsForMaxSize:(float)max andActualSize:(CGSize)size;


@end

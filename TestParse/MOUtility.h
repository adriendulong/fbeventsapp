//
//  MOUtility.h
//  TestParse
//
//  Created by Adrien Dulong on 16/10/13.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface MOUtility : NSObject

#pragma mark - Email
+(BOOL)isValidEmailAddress:(NSString *)emailaddress;

#pragma mark - Date
+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;
+(NSDate *)getEndDateEvent:(PFObject *)event;

#pragma mark - Facebook
+(NSURL *)UrlOfFacebooProfileImage:(NSString *)profileId withResolution:(NSString *)quality;
+(NSDate *)parseFacebookDate:(NSString *)date isDateOnly:(BOOL)isDateOnly;
+(PFObject *)createEventFromFacebookDict:(NSDictionary *)facebookEvent;
+(PFObject *)createInvitationFromFacebookDict:(NSDictionary *)facebookEvent andEvent:(PFObject *)event;
+(void)postLinkOnFacebookEventWall:(NSString *)eventId withUrl:(NSString *)url withMessage:(NSString *)message;

#pragma mark - Colors
+(UIColor*)colorWithHexString:(NSString*)hex;

#pragma mark - Image
+(CGSize)newBoundsForMaxSize:(float)max andActualSize:(CGSize)size;

#pragma mark - Type Event
+(int)typeEvent:(PFObject *)event;

#pragma mark - Twitter
+(void)postImage:(UIImage *)image withStatus:(NSString *)status;

#pragma mark - IOS Resources
//- (void)getUIImageFromAssetURL:(NSURL *)assetUrl withEnded:(UIImage *)block;

@end

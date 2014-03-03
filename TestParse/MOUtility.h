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
#import "Invitation.h"
#import "Notification.h"
#import "Event.h"
#import "TestParseAppDelegate.h"

@interface MOUtility : NSObject <UIAlertViewDelegate>

#pragma mark - Email
+(BOOL)isValidEmailAddress:(NSString *)emailaddress;
+(BOOL)isATestUser:(NSString *)facebookId;

#pragma mark - Date
+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;
+(NSDate *)getEndDateEvent:(PFObject *)event;
+(NSDate *)getEndDateWooventEvent:(NSDictionary *)event;
+(NSMutableArray *)sortByStartDate:(NSMutableArray *)invitations isAsc:(BOOL)ascending;
+(NSDate *)birthdayStringToDate:(NSString *)birthdayString;
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

#pragma mark - Facebook
+(NSURL *)UrlOfFacebooProfileImage:(NSString *)profileId withResolution:(NSString *)quality;
+(NSDate *)parseFacebookDate:(NSString *)date isDateOnly:(BOOL)isDateOnly;
+(PFObject *)createEventFromFacebookDict:(NSDictionary *)facebookEvent;
+(PFObject *)createInvitationFromFacebookDict:(NSDictionary *)facebookEvent andEvent:(PFObject *)event;
+(void)postOnFacebooTimeline:(NSString *)eventId withAttributes:(NSDictionary *)attributes;
+(void)postLinkOnFacebookEventWall:(NSString *)eventId withUrl:(NSString *)url withMessage:(NSString *)message;
+(void)postRSVP:(NSString *)eventId withMessage:(NSString *)message;

#pragma mark - Colors
+(UIColor*)colorWithHexString:(NSString*)hex;

#pragma mark - Image
+(CGSize)newBoundsForMaxSize:(float)max andActualSize:(CGSize)size;
+(BOOL)image:(UIImage *)image1 isEqualTo:(UIImage *)image2;

#pragma mark - Data manipulation
+(NSString *)hashFromImage:(UIImage *)image;
+(NSString *)hashFromData:(NSData *)data;

#pragma mark - Type Event
+(int)typeEvent:(PFObject *)event;

#pragma mark - Twitter
+(void)postImage:(UIImage *)image withStatus:(NSString *)status;

#pragma mark - IOS Resources
//- (void)getUIImageFromAssetURL:(NSURL *)assetUrl withEnded:(UIImage *)block;


#pragma mark - Database Local
+(BOOL)removeAllInvitations;
+(BOOL)deleteInvitation:(NSString *)objectId;
+(BOOL)removeAllEvents;
+(Invitation *)getInvitationForObjectId:(NSString *)objectId;
+(Event *)getEventForObjectId:(NSString *)objectId;
+(Invitation *)saveInvitationWithEvent:(PFObject *)invitation;
+(Event *)saveEvent:(PFObject *)event;
+(Notification *)saveNotification:(NSDictionary *)infos;
+(void)setRsvp:(NSString *)rsvp forInvitation:(NSString *)invitationId;

#pragma mark - Model to Parse Object
+(PFObject *)invitationToParseInvitation:(Invitation *)invitation;
+(PFObject *)eventToParseEvent:(Event *)event;

#pragma mark - Access Local Database
+(NSArray *)getAllFuturInvitations;
+(NSArray *)getFuturInvitationNotReplied;
+(NSArray *)getFuturInvitationDeclined;
+(NSArray *)getPastMemories;
+(int)countFutureInvitations;
+(NSArray *)getNotifs;
+(BOOL)notificationJustRead:(Notification *)notification;
+(NSInteger)nbNewNotifs;


#pragma mark - LogOut
+(BOOL)logoutApp;

#pragma mark - User Infos
+(void)updateUserInfos;

#pragma mark - Device Type
+ (NSString *)platformRawString;
+ (NSString *)platformNiceString;

#pragma mark - Return API KEYS
+(NSString *)getKeenProjectId;
+(NSString *)getKeenWriteKey;
+(NSString *)getKeenReadKey;
+(NSString *)getParseAppId;
+(NSString *)getParseClientKey;

#pragma mark - fonts
+(UIFont *)getFontWithSize:(CGFloat)size;

#pragma mark - Cover
+(UIImage *)getCover:(NSInteger)which;

#pragma mark - Local Notifications
+(void)programNotifForEvent:(PFObject *)event;
+(void)eraseNotifsOfType:(NSInteger)type;

@end

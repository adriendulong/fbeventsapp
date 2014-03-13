//
//  MOUtility.m
//  TestParse
//
//  Created by Adrien Dulong on 16/10/13.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "MOUtility.h"
#import "EventUtilities.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/sysctl.h>
#include <stdlib.h>
#import "KeenClient.h"
#import "FbEventsUtilities.h"
#import "Photo.h"

@implementation MOUtility

#pragma mark - MOUtility
#pragma mark Common Utilities

//Validate en email address

#pragma mark - Email
+(BOOL)isValidEmailAddress:(NSString *)emailaddress{
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:emailaddress];
}

+(BOOL)isATestUser:(NSString *)facebookId{
    NSArray *testeurs = [NSArray arrayWithObjects:@"662393812", nil];
    
    if ([testeurs containsObject:facebookId]) {
        return YES;
    }
    
    else return NO;
}


#pragma mark - Facebook

+(NSDate *)parseFacebookDate:(NSString *)date isDateOnly:(BOOL)isDateOnly{
    
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    NSDateFormatter *dateFullFormatter = [[NSDateFormatter alloc] init];
    [dateFullFormatter setLocale:enUSPOSIXLocale];
    [dateFullFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH:mm:ssZ"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSDateFormatter *oldDateFormat = [[NSDateFormatter alloc] init];
    [oldDateFormat setLocale:enUSPOSIXLocale];
    [oldDateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH:mm:ss"];
    
    NSDate* dateToReturn;
    
    
    if(!isDateOnly){
        dateToReturn = [dateFullFormatter dateFromString:date];
    }
    else{
        dateToReturn = [dateFormatter dateFromString:date];
    }
    
    
    if (dateToReturn==nil) {
        dateToReturn = [oldDateFormat dateFromString:date];
    }
    
    if (dateToReturn==nil) {
        if (date) {
            NSDictionary *event= [NSDictionary dictionaryWithObjectsAndKeys: date, @"time", nil];
            [[KeenClient sharedClient] addEvent:event toEventCollection:@"problem_time" error:nil];
        }
        
        dateToReturn = [NSDate date];
    }
    
    return dateToReturn;
}

+(NSDate *)parseFacebookDateUnix:(NSString *)dateUnix{
    NSDate* dateFacebook = [NSDate dateWithTimeIntervalSince1970:[dateUnix doubleValue]];
    return dateFacebook;
}

+(NSURL *)UrlOfFacebooProfileImage:(NSString *)profileId withResolution:(NSString *)quality{
    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=%@&return_ssl_resources=1", profileId, quality]];
    
    return pictureURL;
}



+(PFObject *)createEventFromFacebookDict:(NSDictionary *)facebookEvent{
    PFObject *eventObject = [PFObject objectWithClassName:@"Event"];
    eventObject[@"eventId"] = facebookEvent[@"id"];
    eventObject[@"name"] = facebookEvent[@"name"];
    
    if(facebookEvent[@"location"]){
        eventObject[@"location"] = facebookEvent[@"location"];
    }
    
    if(facebookEvent[@"start_time"]){
        eventObject[@"start_time"] =  [MOUtility parseFacebookDate:facebookEvent[@"start_time"] isDateOnly:[facebookEvent[@"is_date_only"] boolValue]];
    }
    
    if(facebookEvent[@"end_time"]){
        eventObject[@"end_time"] = [MOUtility parseFacebookDate:facebookEvent[@"end_time"] isDateOnly:[facebookEvent[@"is_date_only"] boolValue]];
        eventObject[@"type"] = [NSNumber numberWithInt:[MOUtility typeEvent:eventObject]];
    }
    
    if (facebookEvent[@"description"]) {
        eventObject[@"description"] = facebookEvent[@"description"];
    }
    
    if (facebookEvent[@"cover"]) {
        eventObject[@"cover"] = facebookEvent[@"cover"][@"source"];
    }
    
    if (facebookEvent[@"owner"]) {
        eventObject[@"owner"] = facebookEvent[@"owner"];
    }
    
    if (facebookEvent[@"admins"]) {
        eventObject[@"admins"] = facebookEvent[@"admins"][@"data"];
        
    }
    
    if(facebookEvent[@"is_date_only"]){
        eventObject[@"is_date_only"] = facebookEvent[@"is_date_only"];
    }
    
    if (facebookEvent[@"venue"]) {
        eventObject[@"venue"] = facebookEvent[@"venue"];
    }
    
    
    
    return eventObject;
}


+(PFObject *)createInvitationFromFacebookDict:(NSDictionary *)facebookEvent andEvent:(PFObject *)event{
    
    PFObject *invitation = [PFObject objectWithClassName:@"Invitation"];
    [invitation setObject:event forKey:@"event"];
    [invitation setObject:[PFUser currentUser] forKey:@"user"];
    invitation[@"rsvp_status"] = facebookEvent[@"rsvp_status"];
    invitation[@"start_time"] = event[@"start_time"];
    invitation[@"is_memory"] = @YES;
    
    invitation[@"isOwner"] = @NO;
    invitation[@"isAdmin"] = @NO;
    
    if([EventUtilities isOwnerOfEvent:event forUser:[PFUser currentUser]])
    {
        NSLog(@"You are the owner !!");
        invitation[@"isOwner"] = @YES;
    }
    
    if ([EventUtilities isAdminOfEvent:event forUser:[PFUser currentUser]]) {
        invitation[@"isAdmin"] = @YES;
    }
    
    
    return invitation;
}


+(void)postOnFacebooTimeline:(NSString *)eventId withAttributes:(NSDictionary *)attributes {
    
    /*
     message, picture, link, name, caption, description, source, place, tags
    */
    
    NSArray *keysArray = @[@"message",
                           @"picture",
                           @"link",
                           @"name",
                           @"caption",
                           @"description",
                           @"source",
                           @"place",
                           @"tags"];
    
    NSMutableDictionary *attMutable = [attributes mutableCopy];
    
    
    for (NSString *attribute in attributes) {
        
        if ([keysArray containsObject:attribute]) {
            
            [attMutable setValue:[attributes valueForKey:attribute] forKey:attribute];
        }
        
        NSLog(@"attribute = %@", attribute);
        
        
    }
    
    NSLog(@"attMutable = %@", attMutable);
    
    
    NSString *requestString = [NSString stringWithFormat:@"%@/feed", eventId];
    FBRequest *request = [FBRequest requestWithGraphPath:requestString parameters:attMutable HTTPMethod:@"POST"];
    
    
    if (([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound)|| ([FBSession.activeSession.permissions indexOfObject:@"publish_stream"] == NSNotFound)) {
        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions", @"publish_stream"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                if (!error) {
                                                    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                        if (!error) {
                                                            NSLog(@"Message posted");
                                                        }
                                                        else{
                                                            NSLog(@"%@", [error userInfo]);
                                                        }
                                                    }];
                                                } else if (error.fberrorCategory != FBErrorCategoryUserCancelled){
                                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission denied"
                                                                                                        message:@"Unable to get permission to post"
                                                                                                       delegate:nil
                                                                                              cancelButtonTitle:@"OK"
                                                                                              otherButtonTitles:nil];
                                                    [alertView show];
                                                    
                                                }
                                            }];
    }
    else{
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                NSLog(@"Message posted");
            }
            else{
                NSLog(@"%@", [error userInfo]);
            }
        }];
    }
    
}

+(void)postLinkOnFacebookEventWall:(NSString *)eventId withUrl:(NSString *)url withMessage:(NSString *)message{
    
    NSString *requestString = [NSString stringWithFormat:@"%@/feed", eventId];
    FBRequest *request = [FBRequest requestWithGraphPath:requestString parameters:@{@"link": url, @"message":message, @"ref":@"photolink"} HTTPMethod:@"POST"];
    
    
    if (([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound)|| ([FBSession.activeSession.permissions indexOfObject:@"publish_stream"] == NSNotFound)) {
        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions", @"publish_stream"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                if (!error) {
                                                    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                        if (!error) {
                                                            NSLog(@"Message posted");
                                                        }
                                                        else{
                                                            NSLog(@"%@", [error userInfo]);
                                                        }
                                                    }];
                                                } else if (error.fberrorCategory != FBErrorCategoryUserCancelled){
                                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission denied"
                                                                                                        message:@"Unable to get permission to post"
                                                                                                       delegate:nil
                                                                                              cancelButtonTitle:@"OK"
                                                                                              otherButtonTitles:nil];
                                                    [alertView show];
                                                    
                                                }
                                            }];
    }
    else{
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                NSLog(@"Message posted");
            }
            else{
                NSLog(@"%@", [error userInfo]);
            }
        }];
    }

}

+(void)postRSVP:(NSString *)eventId withMessage:(NSString *)message{
    NSString *requestString = [NSString stringWithFormat:@"%@/feed", eventId];
    NSString *messageToPost = [NSString stringWithFormat:@"%@ \n\n via Woovent", message];
    FBRequest *request = [FBRequest requestWithGraphPath:requestString parameters:@{@"message":messageToPost, @"link":@"https://apps.facebook.com/woovent", @"ref":@"rsvppost"} HTTPMethod:@"POST"];
    
    if (([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound)|| ([FBSession.activeSession.permissions indexOfObject:@"publish_stream"] == NSNotFound)) {

        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions", @"publish_stream"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                if (!error) {
                                                    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                        if (!error) {
                                                            NSLog(@"Message posted");
                                                        }
                                                        else{
                                                            NSLog(@"%@", [error userInfo]);
                                                        }
                                                    }];
                                                } else if (error.fberrorCategory != FBErrorCategoryUserCancelled){
                                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission denied"
                                                                                                        message:@"Unable to get permission to post"
                                                                                                       delegate:nil
                                                                                              cancelButtonTitle:@"OK"
                                                                                              otherButtonTitles:nil];
                                                    [alertView show];
                                                    
                                                }
                                            }];
    }
    else{
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                NSLog(@"Message posted");
            }
            else{
                NSLog(@"%@", [error userInfo]);
            }
        }];
    }
}

#pragma mark - Events
+(NSMutableArray *)keepGoodEvents:(NSArray *)invitations{
    NSMutableArray *invitationsSorted = [[NSMutableArray alloc] init];
    NSDate *now = [NSDate date];
    
    for(PFObject *invitation in invitations){
        PFObject *tempEvent = invitation[@"event"];
        
        //All day long we keep it 25 hours
        if ([tempEvent[@"is_date_only"] boolValue]) {
            [invitationsSorted addObject:invitation];
        }
        //Not all day long we keep it 12 hours
        else{
            NSDate *start_time = (NSDate *)tempEvent[@"start_time"];
            start_time = [start_time dateByAddingTimeInterval:12*3600];
            if ([start_time compare:now] == NSOrderedDescending) {
                [invitationsSorted addObject:invitation];
            }
        }
        
    }
    
    return invitationsSorted;
}


#pragma mark - Colors

+(UIColor*)colorWithHexString:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

#pragma mark - Date

+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    if ([date compare:beginDate] == NSOrderedAscending)
    	return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
    	return NO;
    
    return YES;
}

+(NSDate *)getEndDateEvent:(PFObject *)event{
    NSDate *startDate = (NSDate *)event[@"start_time"];
    
    
    if (event[@"end_time"]) {
        return (NSDate *)event[@"end_time"];
    }
    else if(event[@"type"]){
        int last = [(NSNumber *)event[@"last"] intValue];
        return [startDate dateByAddingTimeInterval:last*3600];
    }
    else{
        return [startDate dateByAddingTimeInterval:DefaultNbHoursEvent*3600];
    }
}

+(NSMutableArray *)sortByStartDate:(NSMutableArray *)invitations isAsc:(BOOL)ascending{
    NSMutableArray *eventMutArray = [[NSMutableArray alloc] init];
    
    //Create an array with the events
    for(PFObject *invitation in invitations){
        [eventMutArray addObject:invitation[@"event"]];
    }
    
    //Then sort array of events
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start_time"
                                                 ascending:ascending];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedEventArray;
    sortedEventArray = [eventMutArray sortedArrayUsingDescriptors:sortDescriptors];
    
    //Then create a mut array with invits sorted
    NSMutableArray *sortedInvits = [[NSMutableArray alloc] init];
    
    for(PFObject *event in sortedEventArray){
        for(PFObject *invitation in invitations){
            PFObject *eventTemp = invitation[@"event"];
            if ([eventTemp.objectId isEqualToString:event.objectId]) {
                [sortedInvits addObject:invitation];
                break;
            }
        }
    }
    
    return sortedInvits;
}


+(NSDate *)birthdayStringToDate:(NSString *)birthdayString{
    NSDateFormatter* myFormatter = [[NSDateFormatter alloc] init];
    [myFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate* myDate = [myFormatter dateFromString:birthdayString];
    
    return myDate;
}

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

+(NSDate *)setDateTime:(NSDate*)date withTime:(NSInteger)hour{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
    [components setHour:hour];
    return [calendar dateFromComponents:components];
}


#pragma mark - Image

+(CGSize)newBoundsForMaxSize:(float)max andActualSize:(CGSize)size{
    if (size.width>size.height) {
        if (size.width>max) {
            float ratio = max/size.width;
            float newWidth = ratio * size.width;
            float newHeight = ratio*size.height;
            
            CGSize newSize = CGSizeMake(newWidth, newHeight);
            return newSize;
        }
        else {
            return size;
        }
    }
    else{
        if (size.height>max) {
            float ratio = max/size.height;
            float newWidth = ratio * size.width;
            float newHeight = ratio * size.height;
            
            CGSize newSize = CGSizeMake(newWidth, newHeight);
            return newSize;
        }
        else {
            return size;
        }
    }
}

+ (BOOL)image:(UIImage *)image1 isEqualTo:(UIImage *)image2
{
    NSData *data1 = UIImagePNGRepresentation(image1);
    NSData *data2 = UIImagePNGRepresentation(image2);
    
    return [data1 isEqual:data2];
}

#pragma mark - Data manipulation

+ (NSString *)hashFromImage:(UIImage *)image
{
    CGDataProviderRef provider = CGImageGetDataProvider(image.CGImage);
    NSData *data = (id)CFBridgingRelease(CGDataProviderCopyData(provider));
    NSString *hashFromPhoto = [self hashFromData:data];
    
    return hashFromPhoto;
}

+ (NSString *)hashFromData:(NSData *)data {
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, data.length, md5Buffer);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

#pragma mark - Twitter
+(void)postImage:(UIImage *)image withStatus:(NSString *)status
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    ACAccountType *twitterType =
    [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    SLRequestHandler requestHandler =
    ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (responseData) {
            NSInteger statusCode = urlResponse.statusCode;
            if (statusCode >= 200 && statusCode < 300) {
                NSDictionary *postResponseData =
                [NSJSONSerialization JSONObjectWithData:responseData
                                                options:NSJSONReadingMutableContainers
                                                  error:NULL];
                NSLog(@"[SUCCESS!] Created Tweet with ID: %@", postResponseData[@"id_str"]);
            }
            else {
                NSLog(@"[ERROR] Server responded: status code %d %@", statusCode,
                      [NSHTTPURLResponse localizedStringForStatusCode:statusCode]);
            }
        }
        else {
            NSLog(@"[ERROR] An error occurred while posting: %@", [error localizedDescription]);
        }
    };
    
    ACAccountStoreRequestAccessCompletionHandler accountStoreHandler =
    ^(BOOL granted, NSError *error) {
        if (granted) {
            NSArray *accounts = [accountStore accountsWithAccountType:twitterType];
            NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                          @"/1.1/statuses/update_with_media.json"];
            NSDictionary *params = @{@"status" : status};
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                    requestMethod:SLRequestMethodPOST
                                                              URL:url
                                                       parameters:params];
            NSData *imageData = UIImageJPEGRepresentation(image, 1.f);
            [request addMultipartData:imageData
                             withName:@"media[]"
                                 type:@"image/jpeg"
                             filename:@"image.jpg"];
            [request setAccount:[accounts lastObject]];
            [request performRequestWithHandler:requestHandler];
        }
        else {
            NSLog(@"[ERROR] An error occurred while asking for user authorization: %@",
                  [error localizedDescription]);
        }
    };
    
    [accountStore requestAccessToAccountsWithType:twitterType
                                               options:NULL
                                            completion:accountStoreHandler];
}


#pragma mark - Type Event
+(int)typeEvent:(PFObject *)event{
    
    NSTimeInterval distanceBetweenDates = [event[@"end_time"] timeIntervalSinceDate:event[@"start_time"]];
    double secondsInHours = 3600;
    NSInteger daysBetweenDates = distanceBetweenDates / secondsInHours;
    
    if (0<=daysBetweenDates<12) {
        return 1;
    }
    else if(12<=daysBetweenDates<=24){
        return 2;
    }
    else if(24< daysBetweenDates < 96){
        return 3;
    }
    else{
        return 4;
    }
}



#pragma mark - Database Local
+(BOOL)removeAllInvitations{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Invitation" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // fetch all objects
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Houston, we have a problem: %@", error);
    }
    
    // display all objects
    for (Invitation *invitation in fetchedObjects) {
        NSLog(@"%@", invitation.objectId);
        [context deleteObject:invitation];
        NSLog(@"deleted");
    }
    
    if (![context save:&error]) {
        NSLog(@"Couldn't save: %@", error);
    }
    
    
    return YES;
}

+(BOOL)deleteInvitation:(NSString *)objectId{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Invitation" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // setup a predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", objectId];
    fetchRequest.predicate = predicate;
    
    // fetch all objects
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Houston, we have a problem: %@", error);
    }
    else{
        // display all objects
        for (Invitation *invitation in fetchedObjects) {
            [context deleteObject:invitation];
        }
    }
    
    if (![context save:&error]) {
        NSLog(@"Couldn't save: %@", error);
    }
    
    
    
    return YES;
}

+(BOOL)removeAllEvents{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // fetch all objects
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Houston, we have a problem: %@", error);
    }
    
    // display all objects
    for (Event *event in fetchedObjects) {
        NSLog(@"%@", event.objectId);
        [context deleteObject:event];
        NSLog(@"deleted");
    }
    
    if (![context save:&error]) {
        NSLog(@"Couldn't save: %@", error);
    }
    
    
    return YES;
}

+(BOOL)removeAllNotifs{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notification" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // fetch all objects
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Houston, we have a problem: %@", error);
    }
    
    // display all objects
    for (Notification *notif in fetchedObjects) {
        [context deleteObject:notif];
    }
    
    if (![context save:&error]) {
        NSLog(@"Couldn't save: %@", error);
    }
    
    
    return YES;
}

+(Invitation *)getInvitationForObjectId:(NSString *)objectId{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    //See if an invitation with this Id already exists
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Invitation" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    // setup a predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", objectId];
    fetchRequest.predicate = predicate;
    // fetch all objects
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects == nil) {
        return nil;
    }
    else if(fetchedObjects.count == 0){
        return nil;
    }
    else{
        return (Invitation *)[fetchedObjects objectAtIndex:0];
    }
    
}

+(Event *)getEventForObjectId:(NSString *)objectId{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    //See if an invitation with this Id already exists
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    // setup a predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", objectId];
    fetchRequest.predicate = predicate;
    // fetch all objects
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects == nil) {
        return nil;
    }
    else if(fetchedObjects.count == 0){
        return nil;
    }
    else{
        return (Event *)[fetchedObjects objectAtIndex:0];
    }
    
}

+(Invitation *)saveInvitationWithEvent:(PFObject *)invitation{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    Invitation *invitationBase;
    
    //See if an invitation with this Id already exists
    
    
    if ([self getInvitationForObjectId:invitation.objectId] != nil) {
        invitationBase = [self getInvitationForObjectId:invitation.objectId];
    }
    else{
        invitationBase = [NSEntityDescription insertNewObjectForEntityForName:@"Invitation" inManagedObjectContext:context];
    }
    
    
    invitationBase.objectId = invitation.objectId;
    invitationBase.is_memory = [NSNumber numberWithBool:[invitation[@"is_memory"] boolValue]];
    invitationBase.rsvp_status = invitation[@"rsvp_status"];
    invitationBase.event = [self saveEvent:invitation[@"event"]];
    
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return nil;
    }
    else return invitationBase;
}

+(Event *)saveEvent:(PFObject *)event{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    Event *eventBase;
    
    if ([self getEventForObjectId:event.objectId]!=nil) {
        eventBase =[self getEventForObjectId:event.objectId];
    }
    else{
        eventBase = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:context];
    }
    
    eventBase.objectId = event.objectId;
    if (event[@"name"]) eventBase.name = event[@"name"];
    if (event[@"description"]) eventBase.descrip = event[@"description"];
    if (event[@"eventId"]) eventBase.eventId = event[@"eventId"];
    if (event[@"cover"]){
        eventBase.cover = event[@"cover"];
    }
    if (event[@"is_date_only"]) eventBase.is_date_only = [NSNumber numberWithBool:[event[@"is_date_only"] boolValue]];
    if (event[@"location"]) eventBase.location = event[@"location"];
    if (event[@"start_time"]) eventBase.start_date = event[@"start_time"];
    if (event[@"end_time"]) eventBase.end_date = event[@"end_time"];
    if (event[@"owner"]) eventBase.owner = event[@"owner"];
    if (event[@"venue"]) eventBase.venue = event[@"venue"];
    
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return nil;
    }
    else return eventBase;
}

+(Notification *)saveNotification:(NSDictionary *)infos{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    Notification *notif = [NSEntityDescription insertNewObjectForEntityForName:@"Notification" inManagedObjectContext:context];
    
    if (infos[@"invitation"]) {
        notif.invitation = infos[@"invitation"];
    }
    else{
        notif.objectId = infos[@"objectId"];
    }
    
    notif.type = infos[@"type"];
    notif.date = [NSDate date];
    notif.message = infos[@"message"];
    notif.is_new = [NSNumber numberWithBool:YES];
    
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return nil;
    }
    
    else return notif;
}

+(void)setRsvp:(NSString *)rsvp forInvitation:(NSString *)invitationId{
     NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    Invitation *invitation = [self getInvitationForObjectId:invitationId];
    
    if (invitation != nil) {
        invitation.rsvp_status = rsvp;
        
        NSError *error;
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
    }
}


#pragma mark - Model to Parse Object

+(PFObject *)invitationToParseInvitation:(Invitation *)invitation{
    PFObject *parseInvitation = [PFObject objectWithClassName:@"Invitation"];
    
    parseInvitation.objectId = invitation.objectId;
    if (invitation.is_memory) {
        if ([invitation.is_memory isEqualToNumber:[NSNumber numberWithInt:1]]) {
            parseInvitation[@"is_memory"] = @YES;
        }
        else{
            parseInvitation[@"is_memory"] = @NO;
        }
        
    }
    if (invitation.rsvp_status) {
        parseInvitation[@"rsvp_status"] = invitation.rsvp_status;
    }
    if (invitation.event) {
        parseInvitation[@"event"] = [self eventToParseEvent:invitation.event];
    }
    
    
    
    return parseInvitation;
}

+(PFObject *)eventToParseEvent:(Event *)event{
    PFObject *parseEvent = [PFObject objectWithClassName:@"Event"];
    
    parseEvent.objectId = event.objectId;
    
    if (event.name) {
        parseEvent[@"name"] = event.name;
    }
    if (event.descrip) {
        parseEvent[@"description"] = event.descrip;
    }
    
    if (event.eventId) {
        parseEvent[@"eventId"] = event.eventId;
    }
    
    if (event.cover) {
        parseEvent[@"cover"] = event.cover;
    }
    if (event.is_date_only) {
        if ([event.is_date_only isEqualToNumber:[NSNumber numberWithInt:1]]) {
            parseEvent[@"is_date_only"] = @YES;
        }
        else{
            parseEvent[@"is_date_only"] = @NO;
        }
    }
    if (event.location) {
        parseEvent[@"location"] = event.location;
    }
    if (event.start_date) {
        parseEvent[@"start_time"] = event.start_date;
    }
    if (event.end_date) {
        parseEvent[@"end_time"] = event.end_date;
    }
    if (event.owner) {
        parseEvent[@"owner"] = event.owner;
    }
    if (event.venue) {
        parseEvent[@"venue"] = event.venue;
    }
    
    return parseEvent;
}


#pragma mark - Access Local Database
+(NSArray *)getAllFuturInvitations{
    NSMutableArray *invitationsTemp = [[NSMutableArray alloc] init];
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    //See if an invitation with this Id already exists
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Invitation" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"event.start_date" ascending:YES selector:nil];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:dateSort]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(((event.start_date >= %@) OR (event.end_date >= %@)) AND ((rsvp_status like %@) OR (rsvp_status like %@)))", [[NSDate date] dateByAddingTimeInterval:-12*3600] , [NSDate date],FacebookEventAttending, FacebookEventMaybe];
    fetchRequest.predicate = predicate;

    // fetch all objects
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects == nil) {
        return nil;
    }

    for(Invitation *invitation in fetchedObjects){
        PFObject *parseInvit = [self invitationToParseInvitation:invitation];
        [invitationsTemp addObject:parseInvit];
    }
    
    return [invitationsTemp copy];
}


+(NSArray *)getFuturInvitationNotReplied{
    NSMutableArray *invitationsTemp = [[NSMutableArray alloc] init];
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    //See if an invitation with this Id already exists
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Invitation" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"event.start_date" ascending:YES selector:nil];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:dateSort]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(event.start_date >= %@) AND (rsvp_status like %@) ", [NSDate date], FacebookEventNotReplied];
    fetchRequest.predicate = predicate;
    
    // fetch all objects
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects == nil) {
        return nil;
    }
    
    for(Invitation *invitation in fetchedObjects){
        PFObject *parseInvit = [self invitationToParseInvitation:invitation];
        [invitationsTemp addObject:parseInvit];
    }
    
    return [invitationsTemp copy];
}


+(NSArray *)getFuturInvitationDeclined{
    NSMutableArray *invitationsTemp = [[NSMutableArray alloc] init];
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    //See if an invitation with this Id already exists
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Invitation" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"event.start_date" ascending:YES selector:nil];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:dateSort]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(event.start_date >= %@) AND (rsvp_status like %@) ", [NSDate date], FacebookEventDeclined];
    fetchRequest.predicate = predicate;
    
    // fetch all objects
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects == nil) {
        return nil;
    }
    
    for(Invitation *invitation in fetchedObjects){
        PFObject *parseInvit = [self invitationToParseInvitation:invitation];
        [invitationsTemp addObject:parseInvit];
    }
    
    return [invitationsTemp copy];
}

+(NSArray *)getPastMemories{
    NSMutableArray *invitationsTemp = [[NSMutableArray alloc] init];
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    //See if an invitation with this Id already exists
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Invitation" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"event.start_date" ascending:NO selector:nil];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:dateSort]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((event.start_date < %@)) AND ((rsvp_status like %@) OR (rsvp_status like %@)) AND (is_memory == %@)", [NSDate date], FacebookEventMaybe, FacebookEventAttending, [NSNumber numberWithBool:YES]];
    fetchRequest.predicate = predicate;
    
    // fetch all objects
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects == nil) {
        return nil;
    }
    
    for(Invitation *invitation in fetchedObjects){
        PFObject *parseInvit = [self invitationToParseInvitation:invitation];
        [invitationsTemp addObject:parseInvit];
    }
    
    return [invitationsTemp copy];
}

+(int)countFutureInvitations{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    //See if an invitation with this Id already exists
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Invitation" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesSubentities:NO];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(event.start_date >= %@) AND (rsvp_status like %@) ", [NSDate date], FacebookEventNotReplied];
    fetchRequest.predicate = predicate;
    
    // fetch all objects
    NSError *err;
    NSUInteger count = [context countForFetchRequest:fetchRequest error:&err];
    if(count == NSNotFound) {
        return 0;
    }
    
    else return count;
}

+(NSArray *)getNotifs{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    //See if an invitation with this Id already exists
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notification" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // fetch all objects
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects == nil) {
        return nil;
    }
    else return fetchedObjects;
}

+(void)emptyDatabase{
    //Empty Invitations
    [self removeAllInvitations];
    
    //Empty Events
    [self removeAllEvents];
    
    //Empty Notif
    [self removeAllNotifs];
}


+(BOOL)notificationJustRead:(Notification *)notification;{
    notification.is_new = [NSNumber numberWithBool:NO];    
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;

    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return NO;
    }
    
    else return YES;
}

+(NSInteger)nbNewNotifs{
    NSManagedObjectContext *context = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    
    //See if an invitation with this Id already exists
    // create a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notification" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"is_new == %@", [NSNumber numberWithBool:YES]];
    fetchRequest.predicate = predicate;
    
    // fetch all objects
    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
    
    if (count == NSNotFound) {
        return 0;
    }
    else return count;
}


#pragma mark - LogOut
+(BOOL)logoutApp{
    UIApplication *application = ((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).application;
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    
    [self emptyDatabase];
    
    // Clear all caches
    [PFQuery clearAllCachedResults];
    [PFUser logOut];
    
    return YES;
}


#pragma mark - User Infos
+(void)updateUserInfos{
    
    FBRequest *request = [FBRequest requestForMe];
    [[Mixpanel sharedInstance] identify:[PFUser currentUser].objectId];
    [[Mixpanel sharedInstance].people set:@{@"is_mail_notif": [PFUser currentUser][@"is_mail_notif"]}];
    
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // result is a dictionary with the user's Facebook data
            NSDictionary *userData = (NSDictionary *)result;
            
            NSString *facebookID = userData[@"id"];
            
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            PFUser *currentUser = [PFUser currentUser];
            currentUser.email = userData[@"email"];
            [[Mixpanel sharedInstance].people set:@{@"$email": currentUser.email}];
            
            if(userData[@"id"]){
                currentUser[@"facebookId"] = userData[@"id"];
            }
            
            if(userData[@"first_name"]){
                currentUser[@"first_name"] = userData[@"first_name"];
                [[Mixpanel sharedInstance].people set:@{@"First Name": currentUser[@"first_name"]}];
            }
            
            if(userData[@"last_name"]){
                currentUser[@"last_name"] = userData[@"last_name"];
                [[Mixpanel sharedInstance].people set:@{@"Last Name": currentUser[@"last_name"]}];
            }
            
            if(userData[@"name"]){
                currentUser[@"name"] = userData[@"name"];
                [[Mixpanel sharedInstance].people set:@{@"$name": currentUser[@"name"]}];
            }
            
            if(userData[@"location"][@"name"]){
                currentUser[@"location"] = userData[@"location"][@"name"];
                [[Mixpanel sharedInstance].people set:@{@"Location": currentUser[@"location"]}];
                [[Mixpanel sharedInstance] registerSuperProperties:@{@"Location": currentUser[@"location"]}];
            }
            
            if(userData[@"gender"]){
                
                currentUser[@"gender"] = userData[@"gender"];
                [[Mixpanel sharedInstance] registerSuperProperties:@{@"Gender": currentUser[@"gender"]}];
                [[Mixpanel sharedInstance].people set:@{@"Gender": currentUser[@"gender"]}];
            }
            
            if(userData[@"birthday"]){
                currentUser[@"birthday"] = userData[@"birthday"];
                [[Mixpanel sharedInstance] registerSuperProperties:@{@"Birthday": [MOUtility birthdayStringToDate:userData[@"birthday"]]}];
                [[Mixpanel sharedInstance].people set:@{@"Birthday": [MOUtility birthdayStringToDate:userData[@"birthday"]]}];
            }
            
            currentUser[@"pictureURL"] = [pictureURL absoluteString];
            [[Mixpanel sharedInstance].people set:@{@"$profile_picture": currentUser[@"pictureURL"]}];
            currentUser[@"is_mail_notif"] = @YES;
            
            [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    //Update permissions
                    FBRequest *requestPerms = [FBRequest requestForGraphPath:@"me/permissions"];
                    [requestPerms startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                        PFUser *currentUser =[PFUser currentUser];
                        
                        NSArray *permissions = result[@"data"];
                        if ([[permissions objectAtIndex:0][@"rsvp_event"] intValue] == 1) {
                            currentUser[@"has_rsvp_perm"] = @YES;
                        }
                        else{
                            currentUser[@"has_rsvp_perm"] = @NO;
                        }
                        
                        if ([[permissions objectAtIndex:0][@"publish_stream"] intValue] == 1) {
                            currentUser[@"has_publish_perm"] = @YES;
                        }
                        else{
                            currentUser[@"has_publish_perm"] = @NO;
                        }
                        
                        [currentUser saveInBackground];
                    }];
                }
            }];
        }
    }];
}


#pragma mark - AlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == [alertView cancelButtonIndex]) {
    }else{
    }
}

#pragma mark - Device Type

+ (NSString *)platformRawString {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (NSString *)platformNiceString {
    NSString *platform = [self platformRawString];
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad 1";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (4G,2)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (4G,3)";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
}


#pragma mark - Return API KEYS
+(NSString *)getKeenProjectId{
    if (((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).isProdApp) {
        return KeenProjectIdProd;
    }
    else{
        return KeenProjectIdDev;
    }
}

+(NSString *)getKeenWriteKey{
    if (((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).isProdApp) {
        return KeenWriteKeyProd;
    }
    else{
        return KeenWriteKeyDev;
    }
}

+(NSString *)getKeenReadKey{
    if (((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).isProdApp) {
        return KeenReadKeyProd;
    }
    else{
        return KeenReadKeyDev;
    }
}

+(NSString *)getParseAppId{
    if (((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).isProdApp) {
        return ParseApplicationIDProd;
    }
    else{
        return ParseApplicationIDDev;
    }
}

+(NSString *)getParseClientKey{
    if (((TestParseAppDelegate *)[[UIApplication sharedApplication] delegate]).isProdApp) {
        return ParseClientKeyProd;
    }
    else{
        return ParseClientKeyDev;
    }
}


#pragma mark - Font
+(UIFont *)getFontWithSize:(CGFloat)size{
    UIFont *font = [UIFont fontWithName:@"HelveticaNeueLTStd-Lt" size:size];
    return font;
}

#pragma mark - String
+(NSString *)removeAccentuation:(NSString *)text{
    // convert to a data object, using a lossy conversion to ASCII
    NSData *asciiEncoded = [text dataUsingEncoding:NSASCIIStringEncoding
                                            allowLossyConversion:YES];
    
    // take the data object and recreate a string using the lossy conversion
    return [[NSString alloc] initWithData:asciiEncoded
                                            encoding:NSASCIIStringEncoding];
}

#pragma mark - Cover
+(UIImage *)getCover:(NSInteger)which{
    int r = arc4random() % 4;
    
    NSString *nameImage;
    if (which) {
        int number = (which%4)+1;
        nameImage = [NSString stringWithFormat:@"default_cover%i",number];
    }
    else{
         nameImage = [NSString stringWithFormat:@"default_cover%i",(r+1)];
    }
   
    
    return [UIImage imageNamed:nameImage];
}

#pragma mark - Local Notifications
+(void)programNotifForEvent:(PFObject *)invitation{
    NSString *rsvp_status = invitation[@"rsvp_status"];
    
    if(invitation[@"start_time"]){
        //Need a notif
        if ([rsvp_status isEqualToString:FacebookEventAttending]||[rsvp_status isEqualToString:FacebookEventMaybe]) {
            //Erase all notif for this event
            [self eraseNotifsForInvitation:invitation];
            
            [self createNotif:invitation andType:0];
            [self createNotif:invitation andType:1];
            
        }
        //Don't need it, but check if we need to remove one
        else{
            //Erase all notifs for this event if there is
            [self eraseNotifsForInvitation:invitation];
        }
    }
}

+(void)eraseNotifsForInvitation:(PFObject *)invitation{
    NSArray *localNotifs = [[UIApplication sharedApplication] scheduledLocalNotifications];
    
    for(UILocalNotification *notif in localNotifs){
        NSDictionary *userInfos = notif.userInfo;
        if ([userInfos[@"invitationId"] isEqualToString:invitation.objectId]) {
            [[UIApplication sharedApplication] cancelLocalNotification:notif];
        }
    }
    
}

+(void)eraseNotifsOfType:(NSInteger)type{
    NSArray *localNotifs = [[UIApplication sharedApplication] scheduledLocalNotifications];
    NSNumber *typeNotif = [NSNumber numberWithInt:type];
    
    for(UILocalNotification *notif in localNotifs){
        NSDictionary *userInfos = notif.userInfo;
        if ([(NSNumber *)userInfos[@"type"] compare:typeNotif]==NSOrderedSame) {
            [[UIApplication sharedApplication] cancelLocalNotification:notif];
        }
    }
    
}

+(void)createNotif:(PFObject *)invitation andType:(NSUInteger)type{
    NSDictionary *userInfos = @{@"invitationId": invitation.objectId, @"type":[NSNumber numberWithInt:type]};
    PFObject *event = invitation[@"event"];
     NSString *rsvp_status = invitation[@"rsvp_status"];
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    NSString *message;
    NSDate *dateStart = (NSDate *)event[@"start_time"];
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    
    if ([currentInstallation[@"is_push_notif"] boolValue]) {
        //Day before
        if (type == 0) {
            if ([rsvp_status isEqualToString:FacebookEventAttending]) {
                message = [NSString stringWithFormat:NSLocalizedString(@"LocalNotifs_TomorrowGo", nil), event[@"name"]];
            }
            else if([rsvp_status isEqualToString:FacebookEventMaybe]){
                message = [NSString stringWithFormat:NSLocalizedString(@"LocalNotifs_TommorowMaybe", nil), event[@"name"]];
            }
            
            //Day before beginning
            NSDate *testDate = [NSDate date];
            dateStart = [dateStart dateByAddingTimeInterval:-(60*60*24)];
            testDate = [testDate dateByAddingTimeInterval:15];
            
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
            NSDateComponents *components = [gregorian components: NSUIntegerMax fromDate: dateStart];
            [components setHour: 20];
            [components setMinute: 0];
            [components setSecond: 0];
            
            NSDate *newDate = [gregorian dateFromComponents: components];
            
            
            localNotification.fireDate = newDate;
            
            localNotification.alertAction = @"Plus d'infos";
        }
        //Just after the beginning of the event
        else{
            NSDate *testDate = [NSDate date];
            testDate = [testDate dateByAddingTimeInterval:60*1];
            
            //If date only put notif at 20:00 of this day
            NSDate *newDate = [[NSDate alloc] init];
            if ([event[@"is_date_only"] boolValue]) {
                
                NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
                NSDateComponents *components = [gregorian components: NSUIntegerMax fromDate: dateStart];
                [components setHour: 20];
                [components setMinute: 0];
                [components setSecond: 0];
                
                newDate = [gregorian dateFromComponents: components];
            }
            //Otherwise 3 hours after the beginning
            else{
                
                newDate = [dateStart dateByAddingTimeInterval:60*60*3];
                
            }
            
            localNotification.fireDate = newDate;
            message = [NSString stringWithFormat:NSLocalizedString(@"LocalNotifs_SameDay", nil), event[@"name"]];
            localNotification.alertAction = @"Immortaliser";
        }
        
        
        localNotification.alertBody = message;
        localNotification.timeZone = [NSTimeZone defaultTimeZone];
        localNotification.userInfo = userInfos;
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        
        
        //Notif date must be after the actuel date otherwise will always pop up
        if ([localNotification.fireDate compare:[NSDate date]] == NSOrderedDescending) {
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        }
        
    }
    
}


#pragma mark - Photos
+(BFTask *)getNumberOfPhotosToImport:(NSDate *)lastUploadDate forEvents:(NSArray *)events{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    //__block NSInteger nbPhotos = 0;
    //__block NSMutableArray *photosArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *eventsInfosPhotos = [[NSMutableArray alloc] init];

    for(PFObject *event in events){
        NSInteger nbPhotos = 0;
        NSMutableArray *photosArray = [[NSMutableArray alloc] init];
        NSMutableDictionary *infosEvent = [[NSMutableDictionary alloc] init];
        [infosEvent setObject:[NSNumber numberWithInteger:nbPhotos] forKey:@"nb_photos"];
        [infosEvent setObject:photosArray forKey:@"photos"];
        [infosEvent setObject:event forKey:@"event"];
        
        [eventsInfosPhotos addObject:infosEvent];
    }
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

        
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        @autoreleasepool {
            if (group) {
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    if (result) {
                        
                        NSDate *photoDate = (NSDate *)[result valueForProperty:ALAssetPropertyDate];
                        
                        for(NSMutableDictionary *infosEvent in eventsInfosPhotos){
                            PFObject *event = infosEvent[@"event"];
                            NSInteger nbPhotos = [(NSNumber *)infosEvent[@"nb_photos"] integerValue];
                            NSMutableArray *arrayPhotos = (NSMutableArray *)infosEvent[@"photos"];
                            
                            NSDate *start_date;
                            
                            if (lastUploadDate) {
                                NSDate *start_date_event = (NSDate *)event[@"start_time"];
                                
                                
                                if ([start_date_event compare:lastUploadDate]==NSOrderedDescending) {
                                    start_date = (NSDate *)event[@"start_time"];
                                }
                                else{
                                    start_date = lastUploadDate;
                                }
                            }
                            else{
                                start_date = (NSDate *)event[@"start_time"];
                            }
                            
                            
                            
                            
                            NSDate *end_date = [FbEventsUtilities getEndDateEvent:event];
                            
                            
                            if ([MOUtility date:photoDate isBetweenDate:start_date andDate:end_date]) {
                                nbPhotos++;
                                if (nbPhotos<2) {
                                    Photo *photo = [[Photo alloc] init];
                                    photo.thumbnail = [UIImage imageWithCGImage:result.thumbnail];
                                    photo.assetUrl = [result valueForProperty:ALAssetPropertyAssetURL];
                                    photo.date = photoDate;
                                    
                                    [arrayPhotos addObject:photo];
                                }

                                
                                [infosEvent setObject:arrayPhotos forKey:@"photos"];
                                [infosEvent setObject:[NSNumber numberWithInteger:nbPhotos ] forKey:@"nb_photos"];
                                
                                break;
                            }
                        }
                        
    
                    }
                }];
                
            }
            else{
                [task setResult:eventsInfosPhotos];
            }
        }
        
        //[self updateNavBar];
    } failureBlock:^(NSError *error) {
        [task setError:error];
    }];

    
    
    return task.task;
}




@end

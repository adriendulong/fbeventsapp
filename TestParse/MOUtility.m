//
//  MOUtility.m
//  TestParse
//
//  Created by Adrien Dulong on 16/10/13.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "MOUtility.h"
#import "EventUtilities.h"

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


#pragma mark - Facebook

+(NSDate *)parseFacebookDate:(NSString *)date isDateOnly:(BOOL)isDateOnly{
    
    NSDateFormatter *dateFullFormatter = [[NSDateFormatter alloc] init];
    [dateFullFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH:mm:ssZ"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSDateFormatter *oldDateFormat = [[NSDateFormatter alloc] init];
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
    
    return dateToReturn;
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



@end

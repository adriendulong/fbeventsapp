//
//  MOUtility.m
//  TestParse
//
//  Created by Adrien Dulong on 16/10/13.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "MOUtility.h"

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
    
    NSDate* dateToReturn;
    
    
    if(!isDateOnly){
        dateToReturn = [dateFullFormatter dateFromString:date];
    }
    else{
        dateToReturn = [dateFormatter dateFromString:date];
    }
    
    
    
    return dateToReturn;
}

+(NSURL *)UrlOfFacebooProfileImage:(NSString *)profileId{
    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=normal&return_ssl_resources=1", profileId]];
    
    return pictureURL;
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

@end

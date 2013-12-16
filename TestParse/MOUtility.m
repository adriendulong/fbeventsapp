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

+(BOOL)isATestUser:(NSString *)facebookId{
    NSArray *testeurs = [NSArray arrayWithObjects:@"662393812", nil];
    
    if ([testeurs containsObject:facebookId]) {
        return YES;
    }
    
    else return NO;
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


+(void)postLinkOnFacebookEventWall:(NSString *)eventId withUrl:(NSString *)url withMessage:(NSString *)message{
    
    NSString *requestString = [NSString stringWithFormat:@"%@/feed", eventId];
    FBRequest *request = [FBRequest requestWithGraphPath:requestString parameters:@{@"link": url, @"message":message} HTTPMethod:@"POST"];
    
    FBSession *session = [PFFacebookUtils session] ;
    
    NSArray *permissions =
    [NSArray arrayWithObjects:@"publish_actions",@"publish_stream", nil];
    
    NSLog(@"Permissions : %@", session.permissions );

    BOOL publish_perm = [[PFUser currentUser][@"has_publish_perm"] boolValue];

    if (([session.permissions indexOfObject:@"publish_stream"] == NSNotFound) && !publish_perm) {
        [PFFacebookUtils reauthorizeUser:[PFUser currentUser] withPublishPermissions:permissions audience:FBSessionDefaultAudienceFriends block:^(BOOL succeeded, NSError *error) {
            
            
            //Add permission rsvp to user
            FBRequest *requestPerms = [FBRequest requestForGraphPath:@"me/permissions"];
            [requestPerms startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                
                NSArray *permissions = result[@"data"];
                if ([[permissions objectAtIndex:0][@"publish_stream"] intValue] == 1) {
                    PFUser *currentUser =[PFUser currentUser];
                    currentUser[@"has_publish_perm"] = @YES;
                    [currentUser saveInBackground];
                }
                NSLog(@"TEST");
            }];
            
            
            
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    NSLog(@"Message posted");
                }
                else{
                    NSLog(@"%@", [error userInfo]);
                }
            }];
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

+(NSArray *)sortByStartDate:(NSMutableArray *)invitations isAsc:(BOOL)ascending{
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
            }
        }
    }
    
    return [sortedInvits copy];
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
    
    NSDate *test =[[NSDate date] dateByAddingTimeInterval:-12*3600];
    NSLog(@"TEST : %@", test);
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
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((event.start_date < %@) OR (event.end_date < %@)) AND ((rsvp_status like %@) OR (rsvp_status like %@)) AND (is_memory == %@)", [[NSDate date] dateByAddingTimeInterval:-12*3600], [NSDate date], FacebookEventMaybe, FacebookEventAttending, [NSNumber numberWithBool:YES]];
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
    [self emptyDatabase];
    
    // Clear all caches
    [PFQuery clearAllCachedResults];
    [PFUser logOut];
    
    return YES;
}



@end

//
//  Notification.h
//  FbEvents
//
//  Created by Adrien Dulong on 10/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event;

@interface Notification : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) Event *event;

@end

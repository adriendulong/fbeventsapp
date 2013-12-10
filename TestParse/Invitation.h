//
//  Invitation.h
//  FbEvents
//
//  Created by Adrien Dulong on 10/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event;

@interface Invitation : NSManagedObject

@property (nonatomic, retain) NSNumber * is_memory;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSString * rsvp_status;
@property (nonatomic, retain) Event *event;

@end

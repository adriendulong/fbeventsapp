//
//  Notification.h
//  FbEvents
//
//  Created by Adrien Dulong on 09/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Notification : NSManagedObject

@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * message;

@end

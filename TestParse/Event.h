//
//  Event.h
//  FbEvents
//
//  Created by Adrien Dulong on 09/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Event : NSManagedObject

@property (nonatomic, retain) NSString * cover;
@property (nonatomic, retain) NSString * descrip;
@property (nonatomic, retain) NSString * eventId;
@property (nonatomic, retain) NSNumber * is_date_only;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) id owner;
@property (nonatomic, retain) NSDate * start_date;
@property (nonatomic, retain) id venue;
@property (nonatomic, retain) NSDate * end_date;

@end

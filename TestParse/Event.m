//
//  Event.m
//  FbEvents
//
//  Created by Adrien Dulong on 09/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "Event.h"


@implementation Event

@dynamic cover;
@dynamic descrip;
@dynamic eventId;
@dynamic is_date_only;
@dynamic location;
@dynamic name;
@dynamic objectId;
@dynamic owner;
@dynamic start_date;
@dynamic venue;
@dynamic end_date;

@end

@implementation Owner : NSDictionary

+ (Class)transformedValueClass
{
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    return [NSKeyedArchiver archivedDataWithRootObject:value];
}

- (id)reverseTransformedValue:(id)value
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
}

@end

@implementation Venue : NSDictionary

+ (Class)transformedValueClass
{
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    return [NSKeyedArchiver archivedDataWithRootObject:value];
}

- (id)reverseTransformedValue:(id)value
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
}

@end



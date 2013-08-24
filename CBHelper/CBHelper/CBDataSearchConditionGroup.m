/* Copyright (C) 2012 cloudbase.io
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License, version 2, as published by
 the Free Software Foundation.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; see the file COPYING.  If not, write to the Free
 Software Foundation, 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA.
 */

#import "CBDataSearchConditionGroup.h"

@implementation CBDataSearchConditionGroup

@synthesize conditions, field, value, CBLink, CBOperator, sortKeys, limit, isUpsert, offset;

NSString * const CBConditionOperator_ToString[] = {
    @"",
    @"$lt",
    @"$lte",
    @"$gt",
    @"$gte",
    @"$all",
    @"$exists",
    @"$mod",
    @"$ne",
    @"$in",
    @"$nin",
    @"$size",
    @"$type",
    @"$within",
    @"$near"
};

NSString * const CBConditionLink_ToString[] = {
    @"$and",
    @"$or",
    @"$nor",
};

NSString * const CBSearchKey = @"cb_search_key";
NSString * const CBSortKey = @"cb_sort_key";
NSString * const CBUpsertKey = @"cb_upsert";
NSString * const CBLimitKey = @"cb_limit";
NSString * const CBOffsetKey = @"cb_offset";

- (id)init
{
    if (self = [super init])
    {
        self.conditions = [[NSMutableArray alloc] init];
        self.limit = -1;
        self.offset = -1;
        self.isUpsert = NO;
        self.commandType = CBDataAggregationMatch;
        return self;
    }
    return nil;
}
- (id)initWithoutSubConditions
{
    self = [super init];
    self.limit = -1;
    self.offset = -1;
    return self;
}

- (id)initWithField:(NSString *)fieldName is:(CBConditionOperator)op to:(id)compareValue
{
    if (self = [super init])
    {
        self.field = fieldName;
        self.CBOperator = op;
        self.value = compareValue;
        self.limit = -1;
        self.offset = -1;
        self.isUpsert = NO;
        self.commandType = CBDataAggregationMatch;
        return self;
    }
    return nil;
}

- (id)initWithFreeText:(NSString *)text {
    if (self = [super init])
    {
        self.field = @"text";
        self.CBOperator = CBOperatorEqual;
        self.value = text;
        self.limit = -1;
        self.offset = -1;
        self.isUpsert = NO;
        self.commandType = CBDataAggregationMatch;
        return self;
    }
    return nil;
}

// the geolocation search conditions require some special parameters and are created and structured differently from a
// standard CBSearchConditionGroup directly from this methods
- (id)initWithGeoSearchNear:(CLLocationCoordinate2D)coords withinMaxDistance:(NSInteger)distance
{
    if (self = [super init])
    {
        //{ loc : { $near : [50,50] , $maxDistance : 5 } }
        NSArray *point = [[NSArray alloc] initWithObjects:[NSNumber numberWithDouble:coords.latitude], [NSNumber numberWithDouble:coords.longitude], nil];
        NSMutableDictionary *searchQuery = [[NSMutableDictionary alloc] init];
        
        self.field = @"cb_location";
        self.CBOperator = CBOperatorEqual;
        
        [searchQuery setValue:point forKey:@"$near"];
        if (distance != -1) {
            // convert meters to radius, 111.12 km in 1 degree
            [searchQuery setValue:[NSNumber numberWithLong:(distance/1000)/111.12] forKey:@"$maxDistance"];
        }
        
        self.value  = searchQuery;
        self.limit = -1;
        self.offset = -1;
        self.isUpsert = NO;
        self.commandType = CBDataAggregationMatch;
        return self;
    }
    
    return nil;
}

- (id)initWithGeoBoxWithNECorner:(CLLocationCoordinate2D)NECorner andSWCorner:(CLLocationCoordinate2D)SWCorner
{
    if (self = [super init])
    {
        //box = [[40.73083, -73.99756], [40.741404,  -73.988135]]
        // {"loc" : {"$within" : {"$box" : box}}})
        NSArray *box = [[NSArray alloc] initWithObjects:
                        [NSArray arrayWithObjects:[NSDecimalNumber numberWithDouble:SWCorner.latitude], [NSDecimalNumber numberWithDouble:SWCorner.longitude], nil],
                        [NSArray arrayWithObjects:[NSDecimalNumber numberWithDouble:NECorner.latitude], [NSDecimalNumber numberWithDouble:NECorner.longitude], nil], 
                        nil];
        NSMutableDictionary *boxCond = [[NSMutableDictionary alloc] init];
        [boxCond setValue:box forKey:@"$box"];
        
        NSMutableDictionary *searchQuery = [[NSMutableDictionary alloc] init];
        
        self.field = @"cb_location";
        self.CBOperator = CBOperatorEqual;
        
        [searchQuery setValue:boxCond forKey:@"$within"];

        self.value  = searchQuery;
        self.limit = -1;
        self.offset = -1;
        self.isUpsert = NO;
        self.commandType = CBDataAggregationMatch;
        return self;
    }
    
    return nil;
}

- (void)addAnd:(NSString *)fieldName is:(CBConditionOperator)op to:(id)compareValue
{
    if (!self.conditions)
        self.conditions = [[NSMutableArray alloc] init];
    CBDataSearchConditionGroup *newGroup = [[CBDataSearchConditionGroup alloc] initWithoutSubConditions];
    newGroup.field = fieldName;
    newGroup.CBOperator = op;
    newGroup.CBLink = CBConditionLinkAnd;
    newGroup.value = compareValue;
    
    [self.conditions addObject:newGroup];
}
- (void)addAnd:(CBDataSearchConditionGroup *)andGroup
{
    if (!self.conditions)
        self.conditions = [[NSMutableArray alloc] init];

    andGroup.CBLink = CBConditionLinkAnd;
    [self.conditions addObject:andGroup];
}
- (void)addOr:(NSString *)fieldName is:(CBConditionOperator)op to:(id)compareValue
{
    if (!self.conditions)
        self.conditions = [[NSMutableArray alloc] init];

    CBDataSearchConditionGroup *newGroup = [[CBDataSearchConditionGroup alloc] initWithoutSubConditions];
    newGroup.field = fieldName;
    newGroup.CBOperator = op;
    newGroup.CBLink = CBConditionLinkOr;
    newGroup.value = compareValue;
    
    [self.conditions addObject:newGroup];
}
- (void)addOr:(CBDataSearchConditionGroup *)orGroup
{
    if (!self.conditions)
        self.conditions = [[NSMutableArray alloc] init];

    orGroup.CBLink = CBConditionLinkOr;
    [self.conditions addObject:orGroup];
}
- (void)addNor:(NSString *)fieldName is:(CBConditionOperator)op to:(id)compareValue
{
    if (!self.conditions)
        self.conditions = [[NSMutableArray alloc] init];

    CBDataSearchConditionGroup *newGroup = [[CBDataSearchConditionGroup alloc] initWithoutSubConditions];
    newGroup.field = fieldName;
    newGroup.CBOperator = op;
    newGroup.CBLink = CBConditionLinkNor;
    newGroup.value = compareValue;
    
    [self.conditions addObject:newGroup];
}
- (void)addNor:(CBDataSearchConditionGroup *)norGroup
{
    if (!self.conditions)
        self.conditions = [[NSMutableArray alloc] init];

    norGroup.CBLink = CBConditionLinkNor;
    [self.conditions addObject:norGroup];
}

- (void)addSortField:(NSString *)fieldName withSortingDirection:(CBSortDirection)dir
{
    if (self.sortKeys == NULL)
        self.sortKeys = [[NSMutableArray alloc] init];
    
    NSMutableDictionary* newSort = [[NSMutableDictionary alloc] init];
    [newSort setObject:[NSString stringWithFormat:@"%i", dir] forKey:fieldName];
    
    [self.sortKeys addObject:newSort];
}

- (NSObject *)serializeAggregateConditions {
    NSMutableDictionary *conds = [self serializeConditions:self];
    
    return conds;
}

- (NSMutableDictionary *)serializeConditions
{
    NSMutableDictionary *conds = [self serializeConditions:self];
    NSMutableDictionary *finalConditions = [[NSMutableDictionary alloc] init];
    if (![conds valueForKey:CBSearchKey])
        [finalConditions setValue:conds forKey:CBSearchKey];
    else
        finalConditions = conds;
    
    if (self.sortKeys != NULL && [self.sortKeys count] > 0)
        [finalConditions setObject:self.sortKeys forKey:CBSortKey];
    
    if (self.limit > 0)
        [finalConditions setObject:[NSString stringWithFormat:@"%i", self.limit] forKey:CBLimitKey];
    
    if (self.offset > 0)
        [finalConditions setValue:[NSString stringWithFormat:@"%i", self.offset] forKey:CBOffsetKey];
        
    return finalConditions;
}

- (NSMutableDictionary *)serializeConditions:(CBDataSearchConditionGroup *)conditionsGroup
{
    NSMutableDictionary *output = [[NSMutableDictionary alloc] init];
    
    if (!conditionsGroup.field)
    {
        if ([conditionsGroup.conditions count] > 1) {
            NSMutableArray *curObject = [[NSMutableArray alloc] init];
            
            int prevLink = -1;
            int count = 0;
            for (CBDataSearchConditionGroup *curGroup in conditionsGroup.conditions)
            {
                if (prevLink != -1 && prevLink != curGroup.CBLink) {
                    [output setValue:curObject forKey:CBConditionLink_ToString[prevLink]];
                    curObject = [[NSMutableArray alloc] init];
                }
                [curObject addObject:[self serializeConditions:curGroup]];
                prevLink = curGroup.CBLink;
                count++;
                if (count == [conditionsGroup.conditions count]) {
                    [output setValue:curObject forKey:CBConditionLink_ToString[prevLink]];
                }
            }
        }
        else if ([conditionsGroup.conditions count] == 1)
        {
            output = [self serializeConditions:[conditionsGroup.conditions objectAtIndex:0]];
        }
    }
    else
    {
        NSMutableDictionary *cond = [[NSMutableDictionary alloc] init];
        NSMutableArray *modArray = [[NSMutableArray alloc] init];
        switch (conditionsGroup.CBOperator) {
            case CBOperatorEqual:
                [output setValue:conditionsGroup.value forKey:conditionsGroup.field];
                break;
            case CBOperatorAll:
            case CBOperatorExists:
            case CBOperatorNe:
            case CBOperatorIn:
            case CBOperatorBigger:
            case CBOperatorBiggerOrEqual:
            case CBOperatorLess:
            case CBOperatorLessOrEqual:
            case CBOperatorNin:
            case CBOperatorSize:
            case CBOperatorType:
                [cond setValue:conditionsGroup.value forKey:CBConditionOperator_ToString[conditionsGroup.CBOperator]];
                [output setValue:cond forKey:conditionsGroup.field];
                break;
            case CBOperatorMod:
                [modArray addObject:conditionsGroup.value];
                [modArray addObject:[NSNumber numberWithInt:1]];
                [cond setValue:modArray forKey:CBConditionOperator_ToString[conditionsGroup.CBOperator]];
                [output setValue:cond forKey:conditionsGroup.field];
            default:
                break;
        }
    }
    return output;
}

@end

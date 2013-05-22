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

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "CBDataAggregationCommand.h"

@interface CBDataSearchConditionGroup : CBDataAggregationCommand <NSCoding>

typedef enum {
    CBOperatorEqual,
    CBOperatorLess,
    CBOperatorLessOrEqual,
    CBOperatorBigger,
    CBOperatorBiggerOrEqual,
    CBOperatorAll,
    CBOperatorExists,
    CBOperatorMod,
    CBOperatorNe,
    CBOperatorIn,
    CBOperatorNin,
    CBOperatorSize,
    CBOperatorType,
    CBOperatorWithin,
    CBOperatorNear
} CBConditionOperator;

typedef enum {
    CBConditionLinkAnd,
    CBConditionLinkOr,
    CBConditionLinkNor
} CBConditionLink;

typedef enum {
    CBSortAscending = 1,
    CBSortDescending = -1
} CBSortDirection;

@property (nonatomic, retain) NSMutableArray *conditions;
@property (nonatomic, retain) NSMutableArray *sortKeys;
@property (nonatomic) BOOL isUpsert;
@property (nonatomic, retain) NSString *field;
@property (nonatomic, retain) id value;
/**
 * This property is the maximum number of results to be returned by the search
 */
@property (nonatomic) NSInteger limit;

@property (nonatomic) NSInteger offset;

@property (nonatomic) CBConditionOperator CBOperator;
@property (nonatomic) CBConditionLink CBLink;

/** @name Initialisation methods */
/**
 * Initialise an empty CBSearchConditionGroup object
 * @return an mepty CBDataSearchConditionGroup object
 */
- (id)init;
/**
 * Createsa new CBDataSearchConditionGroup object without intialising the sub-conditions array.
 * This is just to save memory if case sub conditions are not needed.
 * @return an mepty CBDataSearchConditionGroup object
 */
- (id)initWithoutSubConditions;
/**
 * Shortcut to initialise a simple condition object
 * Sub conitions array is not initialised to save memory if case sub conditions are not needed.
 *
 * The possible operators for each condition are:
 * CBOperatorEqual,
 * CBOperatorLess,
 * CBOperatorLessOrEqual,
 * CBOperatorBigger,
 * CBOperatorBiggerOrEqual,
 * CBOperatorAll,
 * CBOperatorExists,
 * CBOperatorMod,
 * CBOperatorNe,
 * CBOperatorIn,
 * CBOperatorNin,
 * CBOperatorSize,
 * CBOperatorType
 *
 * @param fieldName The field we are filtering on
 * @param op The operator for the condition from the CBConditionOperator types
 * @param compareValue The value we are comparing the field against
 * @return an mepty CBDataSearchConditionGroup object
 */
- (id)initWithField:(NSString *)fieldName is:(CBConditionOperator)op to:(id)compareValue;

/**
 * Creates a new search condition based on the location data stored in the cloudbase database.
 * Finds points near the given coordinates.
 * @param coords The location of the point to look for
 * @param distance The maximum distance in meters of the items to locate from the given object. Send this paramter as -1
 *  to use unlimited distance
 * @return an initialised CBDataSearchConditionGroup object
 */
- (id)initWithGeoSearchNear:(CLLocationCoordinate2D)coords withinMaxDistance:(NSInteger)distance;

/**
 * Looks for items within the given bounding box.
 * @param NECorner North Eastern corner of the boundary box
 * @param SWCorner South Western corner of the boundary box
 * @return an initialised CBDataSearchConditionGroup object
 */
- (id)initWithGeoBoxWithNECorner:(CLLocationCoordinate2D)NECorner andSWCorner:(CLLocationCoordinate2D)SWCorner;

/** @name Adding sub-conditions */
/**
 * Add a sub-condition (creating a new CBDataSearchConditionGroup object)to the current 
 * condition linking the two with an AND
 * @param fieldName The field we are filtering on
 * @param op The operator for the condition from the CBConditionOperator types
 * @param compareValue The value we are comparing the field against
 */
- (void)addAnd:(NSString *)fieldName is:(CBConditionOperator)op to:(id)compareValue;
/**
 * Add a sub-condition to the current condition linking the two with an AND
 * @param andGroup the new sub-conditions group.
 */
- (void)addAnd:(CBDataSearchConditionGroup *)andGroup;
/**
 * Add a sub-condition (creating a new CBDataSearchConditionGroup object)to the current 
 * condition linking the two with an OR
 * @param fieldName The field we are filtering on
 * @param op The operator for the condition from the CBConditionOperator types
 * @param compareValue The value we are comparing the field against
 */
- (void)addOr:(NSString *)fieldName is:(CBConditionOperator)op to:(id)compareValue;
/**
 * Add a sub-condition to the current condition linking the two with an OR
 * @param orGroup the new sub-conditions group.
 */
- (void)addOr:(CBDataSearchConditionGroup *)orGroup;
/**
 * Add a sub-condition (creating a new CBDataSearchConditionGroup object)to the current 
 * condition linking the two with an NOR
 * @param fieldName The field we are filtering on
 * @param op The operator for the condition from the CBConditionOperator types
 * @param compareValue The value we are comparing the field against
 */
- (void)addNor:(NSString *)fieldName is:(CBConditionOperator)op to:(id)compareValue;
/**
 * Add a sub-condition to the current condition linking the two with an NOR
 * @param norGroup the new sub-conditions group.
 */
- (void)addNor:(CBDataSearchConditionGroup *)norGroup;
/**
 * Add a sorting condition to your search. You can add multiple fields to sort by.
 * It is only possible to sort on top level fields and not on objects.
 * @param fieldName The name of the field in the collection
 * @param dir A CBSortDirection value
 */
- (void)addSortField:(NSString *)fieldName withSortingDirection:(CBSortDirection)dir;

/** @name Serialising the object */
/**
 * returns an NSDictionary containing the representation of the given
 * condition group. This can be sent to the cloudbase.io restful APIs.
 * @param conditionsGroup The set of conditions to be serialised
 * @return The NSMutableDictionary representation of the given conditions
 */
- (NSMutableDictionary *)serializeConditions:(CBDataSearchConditionGroup *)conditionsGroup;
/**
 * returns an NSDictionary containing the representation of the current
 * condition group. This can be sent to the cloudbase.io restful APIs.
 * @return The NSMutableDictionary representation of the current conditions
 */
- (NSMutableDictionary *)serializeConditions;


@end

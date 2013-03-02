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

/**
 * This interface should be implemented by any class to send 
 * Data Aggregation commands to cloudbase.io
 *
 * The serializeAggregateConditions should resturn a Dictionary
 * exactly in the format needed by the CBHelper class to be added
 * to the list of parmeters, serliazed and sent to cloudbase.io
 */
@interface CBDataAggregationCommand : NSObject <NSCoding>

typedef enum {
    CBDataAggregationProject,
    CBDataAggregationUnwind,
    CBDataAggregationGroup,
    CBDataAggregationMatch
} CBDataAggregationCommandType;

/**
 * Serializes the Command object to its JSON representation
 *
 * @return A NSDictionary representation of the Command object. This
 *  method should be implemented in each subclass
 */
- (NSObject *)serializeAggregateConditions;

/**
 * Transforms the current command type to a string for the purpose
 * of serialization.
 *
 * @return The NSString to be sent to cloudbase.io
 */
- (NSString *)getCommandTypeString;

/**
 * This property should be set by each sub-class and it represent which
 * kind of Aggregation operation this object is.
 * Without this paramter the object cannot be sent to cloudbase.io
 */
@property (nonatomic) CBDataAggregationCommandType commandType;

@end

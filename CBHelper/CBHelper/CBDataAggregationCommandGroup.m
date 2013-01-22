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

#import "CBDataAggregationCommandGroup.h"

@implementation CBDataAggregationCommandGroup

NSString * const CBDataAggregationGroupOperator_ToString[] = {
    @"$sum",
    @"$max",
    @"$min",
    @"$avg"
};

- (id)init {
    self.commandType = CBDataAggregationGroup;
    idFields = [[NSMutableArray alloc] init];
    groupField = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)addOutputField:(NSString*)fieldName {
    NSString *varFieldName = [NSString stringWithFormat:@"$%@", fieldName];
    [idFields addObject:varFieldName];
}

- (void)addGroupFormulaFor:(NSString*)fieldName withOperator:(CBDataAggregationGroupOperator)op onField:(NSString*)groupFieldName {
    NSString *fieldVar = [NSString stringWithFormat:@"$%@", groupFieldName];
    
    [self addGroupFormulaFor:fieldName withOperator:op onValue:fieldVar];
}

- (void)addGroupFormulaFor:(NSString*)fieldName withOperator:(CBDataAggregationGroupOperator)op onValue:(NSString*)value {
    NSMutableDictionary *newOperator = [[NSMutableDictionary alloc] init];
    [newOperator setObject:value forKey:CBDataAggregationGroupOperator_ToString[op]];
    [groupField setObject:newOperator forKey:fieldName];
}

- (NSObject *)serializeAggregateConditions {
    NSMutableDictionary *finalSet = [[NSMutableDictionary alloc] init];
    if ([idFields count] > 1) {
        [finalSet setObject:idFields forKey:@"_id"];
    } else {
        [finalSet setObject:[idFields objectAtIndex:0] forKey:@"_id"];
    }
    
    [finalSet addEntriesFromDictionary:groupField];

    return finalSet;
}

@end

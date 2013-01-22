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

#import "CBDataAggregationCommandProject.h"

@implementation CBDataAggregationCommandProject

@synthesize includeFields, excludeFields;

- (id)init {
    self.commandType = CBDataAggregationProject;
    self.includeFields = [[NSMutableArray alloc] init];
    self.excludeFields = [[NSMutableArray alloc] init];
    return self;
}

- (NSObject *)serializeAggregateConditions {
    NSMutableDictionary *fieldList = [[NSMutableDictionary alloc] init];
    
    if (self.includeFields != NULL) {
        for (NSString *fieldName in self.includeFields) {
            NSLog(@"including");
            [fieldList setObject:[NSNumber numberWithInt:1] forKey:fieldName];
        }
    }
    
    if (self.excludeFields != NULL) {
        for (NSString *fieldName in self.excludeFields) {
            [fieldList setObject:[NSNumber numberWithInt:0] forKey:fieldName];
        }
    }
    
    return fieldList;
}

@end

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

#import "CBDataAggregationCommand.h"

@implementation CBDataAggregationCommand

@synthesize commandType;

NSString * const CBDataAggregationCommand_ToString[] = {
    @"$project",
    @"$unwind",
    @"$group",
    @"$match"
};


- (NSObject *)serializeAggregateConditions {
    NSAssert(NO, @"This is an abstract method and should be overridden");
    return NULL;
}

- (NSString *)getCommandTypeString {
    return CBDataAggregationCommand_ToString[self.commandType];
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    
    [encoder encodeObject:[self serializeAggregateConditions] forKey:@"dataCommands"];
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (self = [super init]) {
    }
    return self;
}


@end

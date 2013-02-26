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

#include "CBHelperAttachment.h"

@implementation CBHelperAttachment

@synthesize fileData, fileName;

- (id)initForFile:(NSString *)name withData:(NSData *)content 
{
    self.fileData = content;
    self.fileName = name;
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    // If parent class also adopts NSCoding, include a call to
    // [super encodeWithCoder:encoder] as the first statement.
    
    [encoder encodeObject:self.fileData forKey:@"fileData"];
    [encoder encodeObject:self.fileName forKey:@"fileName"];
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (self = [super init]) {
        // If parent class also adopts NSCoding, replace [super init]
        // with [super initWithCoder:decoder] to properly initialize.
        
        // NOTE: Decoded objects are auto-released and must be retained
        self.fileData = [decoder decodeObjectForKey:@"fileData"];
        self.fileName = [decoder decodeObjectForKey:@"fileName"];
    }
    return self;
}

@end

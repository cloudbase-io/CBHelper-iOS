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

#import "CBQueuedRequest.h"

@implementation CBQueuedRequest

@synthesize url, formData, function, originalObject, processedObject, additionalParams, files, subAction, collectionName;

- (id) initForRequest:(NSString*)cbFunction toUrl:(NSString*)requestUrl withObject:(id)object {
    self.function = cbFunction;
    self.url = requestUrl;
    self.processedObject = object;
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    // If parent class also adopts NSCoding, include a call to
    // [super encodeWithCoder:encoder] as the first statement.
    
    [encoder encodeObject:self.function forKey:@"function"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.formData forKey:@"formData"];
    [encoder encodeObject:self.originalObject forKey:@"originalObject"];
    [encoder encodeObject:self.processedObject forKey:@"processedObject"];
    [encoder encodeObject:self.additionalParams forKey:@"additionalParams"];
    [encoder encodeObject:self.files forKey:@"files"];
    [encoder encodeObject:self.subAction forKey:@"subAction"];
    [encoder encodeObject:self.collectionName forKey:@"collectionName"];
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (self = [super init]) {
        // If parent class also adopts NSCoding, replace [super init]
        // with [super initWithCoder:decoder] to properly initialize.
        
        // NOTE: Decoded objects are auto-released and must be retained
        self.function = [decoder decodeObjectForKey:@"function"];
        self.url = [decoder decodeObjectForKey:@"url"];
        self.formData = [decoder decodeObjectForKey:@"formData"];
        self.originalObject = [decoder decodeObjectForKey:@"originalObject"];
        self.processedObject = [decoder decodeObjectForKey:@"processedObject"];
        self.additionalParams = [decoder decodeObjectForKey:@"additionalParams"];
        self.files = [decoder decodeObjectForKey:@"files"];
        self.subAction = [decoder decodeObjectForKey:@"subAction"];
        self.collectionName = [decoder decodeObjectForKey:@"collectionName"];
    }
    return self;
}

@end

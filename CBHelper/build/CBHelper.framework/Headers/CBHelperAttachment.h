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

#include <UIKit/UIKit.h>

#ifndef CBHELPERATTACHMENT_H_
#define CBHELPERATTACHMENT_H_

@interface CBHelperAttachment : NSObject <NSCoding>

@property (nonatomic, retain) NSString* fileName;
@property (nonatomic, retain) NSData* fileData;

/**
 * creates a new attachment
 * @param fileName The original name of the file
 * @param content the NSData representation of the file.
 */
- (id)initForFile:(NSString *)name withData:(NSData *)content;
@end

#endif
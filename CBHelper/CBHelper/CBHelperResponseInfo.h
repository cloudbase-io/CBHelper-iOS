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

/***
 * This object represents a response from the cloudbase.io servers. It is returned to both
 * the protocol methods and the block handlers for the various API calls. The only exception
 * to this is the downloadFile method which returnes the file NSData directly.
 */
@interface CBHelperResponseInfo : NSObject

@property (nonatomic, retain) NSString *errorMessage; /// the error message if one is returned by cloudbase.io
@property (nonatomic, retain) NSString *function; /// the cloudbase.io function called by the api (data/notification/etc)
@property (nonatomic) NSInteger statusCode; /// the http status code - anything other than 200 is an error
@property (nonatomic, retain) id responseData; /// the NSDictionary containing the response data. this is the content of the "message" element in the JSON response from cloudbase.io
@property (nonatomic) BOOL postSuccess; /// whether the API call was successfull

@end

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

#include <Foundation/Foundation.h>
#include "CBQueuedRequest.h"

#ifndef CBHELPERRESPONSEINFO_H_
#define CBHELPERRESPONSEINFO_H_

/**
 * This object represents a response from the cloudbase.io servers. It is returned to both
 * the protocol methods and the block handlers for the various API calls. The only exception
 * to this is the downloadFile method which returnes the file NSData directly.
 */
@interface CBHelperResponseInfo : NSObject

/**
 * indicates whether the request has been queued and will be sent to the APIs
 * once internet connectivity becomes available
 */
@property (nonatomic) BOOL isQueued;
/**
 * The original request object sent to the APIs
 */
@property (nonatomic, retain) CBQueuedRequest* originalRequest;
/**
 * the error message if one is returned by cloudbase.io
 */
@property (nonatomic, retain) NSString *errorMessage;
/**
 * the cloudbase.io function called by the api (data/notification/etc)
 */
@property (nonatomic, retain) NSString *function;
/**
 * the http status code - anything other than 200 is an error
 */
@property (nonatomic) NSInteger statusCode;
/**
 * the NSDictionary containing the response data. this is the content of the "message" element in the JSON response from cloudbase.io
 */
@property (nonatomic, retain) id responseData;
/**
 * whether the API call was successfull
 */
@property (nonatomic) BOOL postSuccess;
/**
 * contains the full response string from cloudbase.io
 */
@property (nonatomic, retain) NSString *responseString;

@end

#endif

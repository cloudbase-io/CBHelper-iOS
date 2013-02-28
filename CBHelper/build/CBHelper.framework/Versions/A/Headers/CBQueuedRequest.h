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


#ifndef CBQUEUEDREQUEST_H_
#define CBQUEUEDREQUEST_H_

/**
 * This serializable object is used to save API calls on the file system
 * if internet connectivity is not available or the APIs are not responding
 */
@interface CBQueuedRequest : NSObject <NSCoding>

/**
 * The cloudbase.io API function being called
 */
@property (nonatomic, retain) NSString* function;
/**
 * The API url for the request
 */
@property (nonatomic, retain) NSString* url;
/**
 * The full multipart request for the http call
 */
@property (nonatomic, retain) NSMutableData* formData;
/**
 * The object originally handed to the API call
 */
@property (nonatomic, retain) id originalObject;
/**
 * The object processed by the cloudbase.io helper class that will
 * be sent to the APIs. For example if the insertObject method is called
 * with a non-array object this property will contain an array with its 
 * first element set to the original object.
 */
@property (nonatomic, retain) id processedObject;
/**
 * The additional parameters given to the API call. For example
 * used to call a CloudFunction or Applet
 */
@property (nonatomic, retain) NSDictionary* additionalParams;
/**
 * The files attached to the API request
 */
@property (nonatomic, retain) NSArray* files;
/**
 * The additional sub-action for an api. For example if the function called
 * is data the possible sub-actions are insert, update, search, searchAggregate
 */
@property (nonatomic, retain) NSString* subAction;
/**
 * If we are executing a data command this will be set to the name of the collection
 * affected
 */
@property (nonatomic, retain) NSString* collectionName;

/**
 * Creates a new instance of the CBQueuedRequest object with the given values
 */
- (id) initForRequest:(NSString*)cbFunction toUrl:(NSString*)requestUrl withObject:(id)object;

@end

#endif


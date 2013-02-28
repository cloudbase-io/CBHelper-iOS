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
#import "CBHelper.h"

@interface NSURLConnection (CBHelper)

@property (readwrite, nonatomic, copy) void (^outputHanlder)(CBHelperResponseInfo *);
@property (readwrite, nonatomic, copy) void (^downloadHandler)(NSData *);
@property (nonatomic, retain) NSString *CBFunctionName;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) NSNumber *totalResponseBytes;
@property (nonatomic, retain) NSNumber *responseStatusCode;

@property (nonatomic, retain) NSString *shouldQueue;
@property (nonatomic, retain) NSString *queueFileName;

@property (nonatomic, retain) CBQueuedRequest *requestObject;

+ (NSURLConnection *)connectionWithRequest:(NSURLRequest *)request andHandler:(void (^) (CBHelperResponseInfo *response))handler andDelegate:(id)delegate;

@end

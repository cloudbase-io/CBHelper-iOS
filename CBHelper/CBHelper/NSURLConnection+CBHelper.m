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

#import "NSURLConnection+CBHelper.h"

@implementation NSURLConnection (CBHelper)

@dynamic outputHanlder;
@dynamic CBFunctionName;
@dynamic responseData;
@dynamic totalResponseBytes;
@dynamic responseStatusCode;

+ (NSURLConnection *)connectionWithRequest:(NSURLRequest *)request andHandler:(void (^) (CBHelperResponseInfo *response))handler andDelegate:(id)delegate {
	NSURLConnection *con = [[[self class] alloc] initWithRequest:request delegate:delegate];
    [con setOutputHandler:handler];
    return con;
}


- (void (^) (CBHelperResponseInfo *response))outputHanlder {
	return (void (^) (CBHelperResponseInfo *response))objc_getAssociatedObject(self, @"outputHandler");
}

- (void)setOutputHandler:(void (^) (CBHelperResponseInfo *response))block {
	objc_setAssociatedObject(self,@"outputHandler",block,OBJC_ASSOCIATION_RETAIN);
}

- (void (^) (NSData *response))downloadHandler {
	return (void (^) (NSData *response))objc_getAssociatedObject(self, @"downloadHandler");
}

- (void)setDownloadHandler:(void (^) (NSData *response))block {
	objc_setAssociatedObject(self,@"downloadHandler",block,OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableData *)responseData {
    return (NSMutableData *)objc_getAssociatedObject(self, @"responseData");
}

- (void)setResponseData:(NSMutableData *)responseData
{
    objc_setAssociatedObject(self,@"responseData",responseData,OBJC_ASSOCIATION_RETAIN);
}

- (NSNumber *)totalResponseBytes {
    return (NSNumber *)objc_getAssociatedObject(self, @"totalResponseBytes");
}

- (void)setTotalResponseBytes:(NSNumber *)totalResponseBytes
{
    objc_setAssociatedObject(self,@"totalResponseBytes",totalResponseBytes,OBJC_ASSOCIATION_RETAIN);
}


- (NSString *)CBFunctionName {
    return (NSString *)objc_getAssociatedObject(self, @"CBFunctionName");
}

- (void)setCBFunctionName:(NSString *)CBFunctionName
{
    objc_setAssociatedObject(self,@"CBFunctionName",CBFunctionName,OBJC_ASSOCIATION_RETAIN);
}

- (NSNumber *)responseStatusCode {
    return (NSNumber *)objc_getAssociatedObject(self, @"responseStatusCode");
}

- (void)setResponseStatusCode:(NSNumber *)statusCode
{
    objc_setAssociatedObject(self,@"responseStatusCode",statusCode,OBJC_ASSOCIATION_RETAIN);
}
@end

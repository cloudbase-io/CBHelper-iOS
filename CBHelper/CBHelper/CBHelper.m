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

#import "CBHelper.h"
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

@implementation CBHelper

@synthesize appCode, appSecret, isHttps, domain, currentLocation, defaultDateFormat, defaultLogCategory, deviceUniqueIdentifier, notificationToken, notificationCertificateType, authUsername, authPassword;
@synthesize delegate;

NSString * const CBLogLevel_ToString[] = {
    @"DEBUG",
    @"INFO",
    @"WARNING",
    @"ERROR",
    @"FATAL",
    @"EVENT"
};

static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const short _base64DecodingTable[256] = {
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
	-2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
	-2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
};

// initialise all the basic variables and extract the device information
- (void)baseInit 
{
    self.isHttps                = YES;
    self.domain                 = @"api.cloudbase.io";
    deviceRegistered            = NO;
    self.currentLocation        = nil;
    self.defaultDateFormat      = @"yyyy-MM-dd'T'HH:mm:ss";
    self.defaultLogCategory     = @"DEFAULT";
    if (SYSTEM_VERSION_GREATER_THAN(@"5.1")) {
        self.deviceUniqueIdentifier = [UIDevice currentDevice].identifierForVendor.UUIDString;
    } else {
        //self.deviceUniqueIdentifier = [UIDevice currentDevice].identifierForVendor.UUIDString;
        self.deviceUniqueIdentifier = [CBHelper getMacaddress];
        if (self.deviceUniqueIdentifier == NULL) {
            self.deviceUniqueIdentifier = [CBHelper GetUUID];
        }
    }
    self.notificationCertificateType = @"poduction";
    requestParamBoundary        = @"---------------------------14737809831466499882746641449";
    language                    = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSLocale* currentLocale = [NSLocale currentLocale];  // get the current locale.
    country                     = [currentLocale objectForKey:NSLocaleCountryCode];
    currentLocale = NULL;
}

- (id)initForApp:(NSString *)code withSecret:(NSString *)secret
{
    [self baseInit];
    self.appCode = code;
    self.appSecret = secret;
    
    return self;
}

- (void)setPassword:(NSString *)value
{
    password = value;
    [self registerDevice]; // once we have set the password then we can register the device with the cloudbase.io server
}

- (NSString *)getSessionID
{
    return sessionid;
}

- (NSString *)generateURL
{
    return [NSString stringWithFormat:@"%@://%@", (self.isHttps?@"https":@"http"), self.domain];
}


#pragma mark - Register device
- (void)registerDevice
{
    NSMutableDictionary *device = [[NSMutableDictionary alloc] init];
    
    [device setValue:@"iOS" forKey:@"device_type"];
    [device setValue:[[UIDevice currentDevice] model] forKey:@"device_name"];
    [device setValue:[[UIDevice currentDevice] systemVersion] forKey:@"device_model"];
    [device setValue:language forKey:@"language"];
    [device setValue:country forKey:@"country"];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/register", [self generateURL], self.appCode];
    
    // once we have received the response set the session id variable.
    // this will be used when tracking navigation information (see logNavigation) with cloudbase.io
    [self sendPost:@"register-device" withForm:device andParameters:NULL toUrl:postUrl whenDone:^(CBHelperResponseInfo *response) {
        if (response.postSuccess && [response.responseData isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *tmpData = (NSDictionary *)response.responseData;
            if ([tmpData objectForKey:@"sessionid"] != NULL)
                sessionid = (NSString *)[tmpData objectForKey:@"sessionid"];
            
            tmpData = NULL;
        }
    }];
    device = nil;
    postUrl = nil;
}

#pragma mark - Logging
- (void)log:(NSString *)line forCategory:(NSString *)cat atLevel:(CBLogLevel)level
{
    NSMutableDictionary *logdata = [[NSMutableDictionary alloc] init];
    
    [logdata setValue:cat forKey:@"category"];
    [logdata setValue:CBLogLevel_ToString[level] forKey:@"level"];
    [logdata setValue:line forKey:@"log_line"];
    [logdata setValue:[[UIDevice currentDevice] model] forKey:@"device_name"];
    [logdata setValue:[[UIDevice currentDevice] systemVersion] forKey:@"device_model"];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/log", [self generateURL], self.appCode];
    
    [self sendPost:@"log" withForm:logdata toUrl:postUrl];
    logdata = nil;
    postUrl = nil;
}

- (void)logDebug:(NSString *)line forCategory:(NSString *)cat
{
    [self log:line forCategory:cat atLevel:CBLogLevelDebug];
}
- (void)logDebug:(NSString *)line
{
    [self log:line forCategory:defaultLogCategory atLevel:CBLogLevelDebug];
}
- (void)logInfo:(NSString *)line forCategory:(NSString *)cat
{
    [self log:line forCategory:cat atLevel:CBLogLevelInfo];
}
- (void)logInfo:(NSString *)line
{
    [self log:line forCategory:defaultLogCategory atLevel:CBLogLevelInfo];
}
- (void)logWarning:(NSString *)line forCategory:(NSString *)cat
{
    [self log:line forCategory:cat atLevel:CBLogLevelWarning];
}
- (void)logWarning:(NSString *)line
{
    [self log:line forCategory:defaultLogCategory atLevel:CBLogLevelWarning];
}
- (void)logError:(NSString *)line forCategory:(NSString *)cat
{
    [self log:line forCategory:cat atLevel:CBLogLevelError];
}
- (void)logError:(NSString *)line
{
    [self log:line forCategory:defaultLogCategory atLevel:CBLogLevelError];
}
- (void)logFatal:(NSString *)line forCategory:(NSString *)cat
{
    [self log:line forCategory:cat atLevel:CBLogLevelFatal];
}
- (void)logFatal:(NSString *)line
{
    [self log:line forCategory:defaultLogCategory atLevel:CBLogLevelFatal];
}
- (void)logEvent:(NSString *)line forCategory:(NSString *)cat
{
    [self log:line forCategory:cat atLevel:CBLogLevelEvent];
}
- (void)logEvent:(NSString *)line
{
    [self log:line forCategory:defaultLogCategory atLevel:CBLogLevelEvent];
}
- (void)logNavigation:(NSString *)viewName
{
    if (!sessionid)
        return;
    
    NSMutableDictionary *logdata = [[NSMutableDictionary alloc] init];
    
    [logdata setValue:sessionid forKey:@"session_id"];
    [logdata setValue:viewName forKey:@"screen_name"];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/lognavigation", [self generateURL], self.appCode];
    
    [self sendPost:@"log-navigation" withForm:logdata toUrl:postUrl];
    logdata = nil;
    postUrl = nil;
}

#pragma mark - Data methods
- (void)insertDocument:(id)obj inCollection:(NSString *)collectionName
{
    NSMutableArray *insertObjects = [[NSMutableArray alloc] init];
    
    if ([obj isKindOfClass:[NSArray class]])
        [insertObjects setArray:obj];
    else
        [insertObjects addObject:obj];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/%@/insert", [self generateURL], self.appCode, collectionName];
    
    [self sendPost:@"data" withForm:insertObjects toUrl:postUrl];
    insertObjects = nil;
    postUrl = nil;
}

- (void)insertDocument:(id)obj inCollection:(NSString *)collectionName withFiles:(NSArray *)attachments
{
    NSMutableArray *insertObjects = [[NSMutableArray alloc] init];
    
    if ([obj isKindOfClass:[NSArray class]])
        [insertObjects setArray:obj];
    else
        [insertObjects addObject:obj];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/%@/insert", [self generateURL], self.appCode, collectionName];
    
    [self sendPost:@"data" withForm:insertObjects andFiles:attachments toUrl:postUrl];
    insertObjects = nil;
    postUrl = nil;
}

- (void)insertDocument:(id)obj inCollection:(NSString *)collectionName whenDone:(void (^) (CBHelperResponseInfo *response))handler
{
    NSMutableArray *insertObjects = [[NSMutableArray alloc] init];
    
    if ([obj isKindOfClass:[NSArray class]])
        [insertObjects setArray:obj];
    else
        [insertObjects addObject:obj];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/%@/insert", [self generateURL], self.appCode, collectionName];
    [self sendPost:@"data" withForm:insertObjects andParameters:nil toUrl:postUrl whenDone:handler];
    insertObjects = nil;
    postUrl = nil;
}

- (void)insertDocument:(id)obj inCollection:(NSString *)collectionName withFiles:(NSArray *)attachments whenDone:(void (^) (CBHelperResponseInfo *response))handler
{
    NSMutableArray *insertObjects = [[NSMutableArray alloc] init];
    
    if ([obj isKindOfClass:[NSArray class]])
        [insertObjects setArray:obj];
    else
        [insertObjects addObject:obj];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/%@/insert", [self generateURL], self.appCode, collectionName];
    [self sendPost:@"data" withForm:insertObjects andFiles:attachments andParameters:nil toUrl:postUrl whenDone:handler];
    insertObjects = nil;
    postUrl = nil;

}

- (void)searchAllDocumentsInCollection:(NSString *)collection 
{
    [self searchDocumentWithConditions:nil inCollection:collection];
}

- (void)searchAllDocumentsInCollection:(NSString *)collection whenDone:(void (^) (CBHelperResponseInfo *response))handler
{
    [self searchDocumentWithConditions:nil inCollection:collection whenDone:handler];
}

- (void)searchDocumentWithConditions:(CBDataSearchConditionGroup *)conditions inCollection:(NSString *)collection
{
    [self searchDocumentWithConditions:conditions inCollection:collection whenDone:nil];
}

- (void)searchDocumentWithConditions:(CBDataSearchConditionGroup *)conditions inCollection:(NSString *)collection whenDone:(void (^) (CBHelperResponseInfo *response))handler
{
    NSMutableDictionary *serializedConditions = [conditions serializeConditions];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/%@/search", [self generateURL], self.appCode, collection];
    
    [self sendPost:@"data" withForm:serializedConditions andParameters:nil toUrl:postUrl whenDone:handler];
    serializedConditions = nil;
    postUrl = nil;
}

- (void)searchDocumentWithAggregates:(NSMutableArray *)aggregateConditions inCollection:(NSString *)collection whenDone:(void (^) (CBHelperResponseInfo *response))handler {
    NSMutableArray *serializedAggregateConditions = [[NSMutableArray alloc] init];
    
    
    for (CBDataAggregationCommand *curCommand in aggregateConditions) {
        NSMutableDictionary *curSerializedCondition = [[NSMutableDictionary alloc] init];
        
        [curSerializedCondition setObject:[curCommand serializeAggregateConditions] forKey:[curCommand getCommandTypeString]];
        
        [serializedAggregateConditions addObject:curSerializedCondition];
    }
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/%@/aggregate", [self generateURL], self.appCode, collection];
    
    NSMutableDictionary *finalCond = [[NSMutableDictionary alloc] init];
    [finalCond setObject:serializedAggregateConditions forKey:@"cb_aggregate_key"];
    
    [self sendPost:@"data" withForm:finalCond andParameters:nil toUrl:postUrl whenDone:handler];
    
    postUrl = nil;
}

- (void)updateDocument:(id)obj where:(CBDataSearchConditionGroup *)conditions inCollection:(NSString *)collection
{
    [self updateDocument:obj where:conditions inCollection:collection whenDone:nil];
}

- (void)updateDocument:(id)obj where:(CBDataSearchConditionGroup *)conditions inCollection:(NSString *)collection whenDone:(void (^) (CBHelperResponseInfo *response))handler
{
    NSMutableArray *insertObjects = [[NSMutableArray alloc] init];
    
    // we need to add the cb_search_key element to the object. This represents the "WHERE" clause
    // in the update statement
    if ([obj isKindOfClass:[NSArray class]])
    {
        for (id curObj in obj)
        {
            NSMutableDictionary *tmpDict = [self objectToDictionaryOrArray:curObj];
            [tmpDict setValue:[conditions serializeConditions] forKey:@"cb_search_key"];
            [insertObjects addObject:tmpDict];
            tmpDict = nil;
        }
    }
    else
    {
        NSMutableDictionary *tmpDict = [self objectToDictionaryOrArray:obj];
        [tmpDict setValue:[conditions serializeConditions] forKey:@"cb_search_key"];
        [insertObjects addObject:tmpDict];
        tmpDict = nil;
    }
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/%@/update", [self generateURL], self.appCode, collection];
    
    [self sendPost:@"data" withForm:insertObjects andParameters:nil toUrl:postUrl whenDone:handler];
    insertObjects = nil;
    postUrl = nil;
}

- (void)downloadFileData:(NSString *)fileId whenDone:(void (^)(NSData *fileContent))handler
{
    // we create a new URLRequest to download a file rather then using the standard methods included in this
    // class.
    NSMutableData *postData = [NSMutableData data];
    [postData appendData:[self requestBodyForParameter:@"app_uniq" withValue:self.appSecret]];
    [postData appendData:[self requestBodyForParameter:@"app_pwd" withValue:password]];
    [postData appendData:[self requestBodyForParameter:@"device_uniq" withValue:self.deviceUniqueIdentifier]];
    [postData appendData:[[NSString stringWithFormat:@"--%@--\r\n", requestParamBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/file/%@", [self generateURL], self.appCode, fileId];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:postUrl]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", requestParamBoundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    [request setHTTPBody:postData];
    
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:request andHandler:nil andDelegate:self]; 
    
    if (handler != nil)
        conn.downloadHandler = handler;
    
    conn.CBFunctionName = @"download";
    [conn start];

}

#pragma mark - Push Notifications
- (void)subscribeDeviceWithToken:(NSData *)deviceToken toNotificationChannel:(NSString *)channel
{
    NSMutableDictionary *subForm = [[NSMutableDictionary alloc] init];
    const unsigned* tokenBytes = [deviceToken bytes];
    // generate the string of the token
    NSString *pushToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                                   ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                                   ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                                   ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    
    [subForm setValue:@"subscribe" forKey:@"action"];
    [subForm setValue:pushToken forKey:@"device_key"];
    [subForm setValue:@"ios" forKey:@"device_network"];
    [subForm setValue:channel forKey:@"channel"];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/notifications-register", [self generateURL], self.appCode];
    
    [self sendPost:@"notifications-register" withForm:subForm toUrl:postUrl];
    subForm = nil;
    pushToken = nil;
    postUrl = nil;
}

- (void)unsubscribeDeviceWithToken:(NSData *)deviceToken fromNotificationChannel:(NSString *)channel andAll:(BOOL)removeCompletely
{
    NSMutableDictionary *subForm = [[NSMutableDictionary alloc] init];
    const unsigned* tokenBytes = [deviceToken bytes];
    NSString *pushToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                           ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                           ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                           ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    
    [subForm setValue:@"unsubscribe" forKey:@"action"];
    [subForm setValue:pushToken forKey:@"device_key"];
    [subForm setValue:@"ios" forKey:@"device_network"];
    [subForm setValue:channel forKey:@"channel"];
    if (removeCompletely)
        [subForm setValue:(removeCompletely?@"true":@"false") forKey:@"from_all"];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/notifications-register", [self generateURL], self.appCode];
    
    [self sendPost:@"notifications-register" withForm:subForm toUrl:postUrl];
    subForm = nil;
    pushToken = nil;
    postUrl = nil;
}

- (void)sendEmail:(NSString *)templateCode to:(NSString *)recipient withSubject:(NSString *)subject andVars:(NSDictionary *)vars
{
    NSMutableDictionary *subForm = [[NSMutableDictionary alloc] init];
    [subForm setValue:templateCode forKey:@"template_code"];
    [subForm setValue:recipient forKey:@"recipient"];
    [subForm setValue:subject forKey:@"subject"];
    [subForm setValue:vars forKey:@"variables"];
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/email", [self generateURL], self.appCode];
    
    [self sendPost:@"email" withForm:subForm toUrl:postUrl];
    subForm = nil;
    postUrl = nil;
}

- (void)sendNotification:(NSString *)text withBadge:(NSInteger)badgeNum andSound:(NSString *)soundName toChannels:(NSArray *)channel
{
    NSMutableDictionary *subForm = [[NSMutableDictionary alloc] init];
    
    [subForm setValue:channel forKey:@"channel"];
    // the certificate type is a parameter used only for iOS as it is possible to have a
    // development and production certificate to use the Apple push notification service.
    // by default this is set to "production"
    [subForm setValue:self.notificationCertificateType forKey:@"cert_type"];
    [subForm setValue:text forKey:@"alert"];
    [subForm setValue:[NSNumber numberWithInt:badgeNum] forKey:@"badge"];
    [subForm setValue:soundName forKey:@"sound"];    
    
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/notifications", [self generateURL], self.appCode];
    
    [self sendPost:@"notifications" withForm:subForm toUrl:postUrl];
    subForm = nil;
    postUrl = nil;
}

- (void)sendNotification:(NSString *)text withBadge:(NSInteger)badgeNum andSound:(NSString *)soundName toChannel:(NSString *)channel
{
    NSArray *channels = [NSArray arrayWithObject:channel];
    [self sendNotification:text withBadge:badgeNum andSound:soundName toChannels:channels];
    channels = nil;
}

#pragma mark - CloudFunction
- (void)executeCloudFunction:(NSString *)fcode
{
    [self executeCloudFunction:fcode withParameters:nil];
}

- (void)executeCloudFunction:(NSString *)fcode withParameters:(NSDictionary *)params
{
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/cloudfunction/%@", [self generateURL], self.appCode, fcode];
    
    [self sendPost:@"cloudfunction" withForm:nil andParameters:params toUrl:postUrl];
    postUrl = nil;
}

- (void)executeCloudFunction:(NSString *)fcode withParameters:(NSDictionary *)params whenDone:(void (^) (CBHelperResponseInfo *response))handler
{
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/cloudfunction/%@", [self generateURL], self.appCode, fcode];
    
    [self sendPost:@"cloudfunction" withForm:nil andParameters:params toUrl:postUrl whenDone:handler];
    postUrl = nil;

}

- (void)executeApplet:(NSString *)fcode withParameters:(NSDictionary *)params
{
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/applet/%@", [self generateURL], self.appCode, fcode];
    
    [self sendPost:@"applet" withForm:nil andParameters:params toUrl:postUrl];
    postUrl = nil;

}

- (void)executeApplet:(NSString *)fcode withParameters:(NSDictionary *)params whenDone:(void (^) (CBHelperResponseInfo *response))handler
{
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/applet/%@", [self generateURL], self.appCode, fcode];
    
    [self sendPost:@"applet" withForm:nil andParameters:params toUrl:postUrl whenDone:handler];
    postUrl = nil;
}

#pragma mark - PayPal
- (void)preparePayPalPurchase:(CBPayPalBill*)bill onLiveEnvironment:(BOOL)isLive whenDone:(void (^) (CBHelperResponseInfo *response))handler
{
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/paypal/prepare", [self generateURL], self.appCode];
    NSMutableDictionary* postForm = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary* payment = [bill serializePurchase];
    
    [postForm setObject:payment forKey:@"purchase_details"];
    [postForm setObject:(isLive?@"live":@"sandbox") forKey:@"environment"];
    [postForm setObject:bill.currency forKey:@"currency"];
    [postForm setObject:@"purchase" forKey:@"type"];
    [postForm setObject:bill.paymentCompletedFunction forKey:@"completed_cloudfunction"];
    [postForm setObject:bill.paymentCancelledFunction forKey:@"cancelled_cloudfunction"];
    if (bill.paymentCompletedUrl != NULL)
        [postForm setObject:bill.paymentCompletedUrl forKey:@"payment_completed_url"];
    if (bill.paymentCancelledUrl != NULL)
        [postForm setObject:bill.paymentCancelledUrl forKey:@"payment_cancelled_url"];
    
    [self sendPost:@"paypal" withForm:postForm andParameters:NULL toUrl:postUrl whenDone:handler];
}

- (BOOL)readPayPalResponse:(NSURLRequest*)request whenDone:(void (^) (CBHelperResponseInfo *response))handler
{
    NSString* urlString = [request.URL absoluteString];
    if ([urlString rangeOfString:@"paypal/update-status"].location == NSNotFound)
    {
        return YES;
    }
    else
    {
        [self sendPost:@"paypal" withForm:NULL andParameters:NULL toUrl:urlString whenDone:handler];
        return NO;
    }
}

- (void)getPayPalPaymentDetails:(NSString*)paymentId whenDone:(void (^) (CBHelperResponseInfo *response))handler
{
    NSString *postUrl = [NSString stringWithFormat:@"%@/%@/paypal/payment-details", [self generateURL], self.appCode];
    NSMutableDictionary* postForm = [[NSMutableDictionary alloc] init];
    
    [postForm setObject:paymentId forKey:@"payment_id"];
    
    [self sendPost:@"paypal" withForm:postForm andParameters:NULL toUrl:postUrl whenDone:handler];
}

#pragma mark - Common
- (void)sendPost:(NSString *)function withForm:(id)form andParameters:(NSDictionary *)params toUrl:(NSString *)url
{
    [self sendPost:function withForm:form andParameters:params toUrl:url whenDone:nil];
}

- (void)sendPost:(NSString *)function withForm:(id)form andFiles:(NSArray *)attachments andParameters:(NSDictionary *)params toUrl:(NSString *)url
{
    [self sendPost:function withForm:form andFiles:attachments andParameters:params toUrl:url whenDone:nil];
}

- (void)sendPost:(NSString *)function withForm:(id)form toUrl:(NSString *)url
{
    [self sendPost:function withForm:form andFiles:nil andParameters:nil toUrl:url whenDone:nil];
}

- (void)sendPost:(NSString *)function withForm:(id)form andFiles:(NSArray *)attachments toUrl:(NSString *)url
{
    [self sendPost:function withForm:form andFiles:attachments andParameters:nil toUrl:url whenDone:nil];
}

- (void)sendPost:(NSString *)function withForm:(id)form andParameters:(NSDictionary *)params toUrl:(NSString *)url whenDone:(void (^) (CBHelperResponseInfo *response))handler
{
    [self sendPost:function withForm:form andFiles:nil andParameters:params toUrl:url whenDone:handler];
}

- (void)sendPost:(NSString *)function withForm:(id)form andFiles:(NSArray *)attachments andParameters:(NSDictionary *)params toUrl:(NSString *)url whenDone:(void (^) (CBHelperResponseInfo *response))handler
{

    NSString *JSONData = @"";
    if (form != nil)
        JSONData = [form JSONRepresentation]; // use the SBJson library to get the json version of the parameters
    
    NSMutableData *postData = [NSMutableData data];
    // write all the required parameters for the request
    [postData appendData:[self requestBodyForParameter:@"app_uniq" withValue:self.appSecret]];
    [postData appendData:[self requestBodyForParameter:@"app_pwd" withValue:password]];
    [postData appendData:[self requestBodyForParameter:@"device_uniq" withValue:self.deviceUniqueIdentifier]];
    [postData appendData:[self requestBodyForParameter:@"post_data" withValue:JSONData]];
    
    for (id key in params)
    {
        [postData appendData:[self requestBodyForParameter:(NSString *)key withValue:(NSString *)[params objectForKey:key]]];
    }
    
    // if the application is set to require user authentication and the authUsername parameter is set
    // then we send the login information. Without this information the application can only read/write
    // to the collection specified in the security settings as the "user" collection - this is to allow new
    // users to be registered
    if (self.authUsername != nil)
    {
        [postData appendData:[self requestBodyForParameter:@"cb_auth_user" withValue:self.authUsername]];
        [postData appendData:[self requestBodyForParameter:@"cb_auth_password" withValue:self.authPassword]];
    }
    
    // if location data is set in the CBHelper object then send it with the request
    if (currentLocation != nil)
    {
        NSString *locdata = @"";
        NSMutableDictionary *loc = [[NSMutableDictionary alloc] init];
        [loc setValue:[NSNumber numberWithDouble:currentLocation.coordinate.latitude]  forKey:@"lat"];
        [loc setValue:[NSNumber numberWithDouble:currentLocation.coordinate.longitude]  forKey:@"lng"];
        [loc setValue:[NSNumber numberWithDouble:currentLocation.altitude]  forKey:@"alt"];
        
        locdata = [loc JSONRepresentation]; //[myWriter stringWithObject:loc];
        
        [postData appendData:[self requestBodyForParameter:@"location_data" withValue:locdata]];
        loc = nil;
    }
    
    if (attachments != nil)
    {
        int cnt = 0;
        for (id attachment in attachments)
        {
            [postData appendData:[self requestBodyForFile:(CBHelperAttachment *)attachment withOrder:cnt]];
            cnt++;
        }
    }
    //close the form
    [postData appendData:[[NSString stringWithFormat:@"--%@--\r\n", requestParamBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self sendRequest:function toUrl:url withData:postData whenDone:handler];
    postData = nil;

}

- (NSData *)requestBodyForParameter:(NSString *)paramName withValue:(NSString *)paramValue
{
    NSMutableData *paramBody = [NSMutableData data];
    
    [paramBody appendData:[[NSString stringWithFormat:@"--%@\r\n", requestParamBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [paramBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", paramName] dataUsingEncoding:NSUTF8StringEncoding]];
    [paramBody appendData:[paramValue dataUsingEncoding:NSUTF8StringEncoding]];
    [paramBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    return paramBody;
}

- (NSData *)requestBodyForFile:(CBHelperAttachment *)attachment withOrder:(NSInteger)fileNum
{
    NSMutableData *paramBody = [NSMutableData data];
    
    [paramBody appendData:[[NSString stringWithFormat:@"--%@\r\n", requestParamBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [paramBody appendData:[[NSString stringWithFormat:@"Content-Disposition: attachment; name=\"file_%i\"; filename=\"%@\"\r\n", fileNum, attachment.fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [paramBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [paramBody appendData:[NSData dataWithData:attachment.fileData]];
    [paramBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    return paramBody;
}

- (void)sendRequest:(NSString *)function toUrl:(NSString *)url withData:(NSData *)formData
{
    [self sendRequest:function toUrl:url withData:formData whenDone:nil];
}

- (void)sendRequest:(NSString *)function toUrl:(NSString *)url withData:(NSData *)formData whenDone:(void (^) (CBHelperResponseInfo *response))handler

{
    //NSLog(@"Calling url %@", url);
    
    // send the request
    NSString *postLength = [NSString stringWithFormat:@"%d", [formData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", requestParamBoundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];

    [request setHTTPBody:formData];
    
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:request andHandler:handler andDelegate:self];
    conn.CBFunctionName = function;
    [conn start];
    request = nil;
}

+ (NSString *)getMacaddress {
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
        
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
        
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
        
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
        
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
        
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
        
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                               *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
        
    return outstring;
  
}

+ (NSString *)GetUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

+ (NSString *) md5:(NSString *)str {
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result );
    return [[NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], 
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ] lowercaseString]; 
}

+ (NSString *)encodeBase64WithData:(NSData *)objData {
    
    const uint8_t* input = (const uint8_t*)[objData bytes];
    NSInteger length = [objData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

+ (NSData *)decodeBase64WithString:(NSString *)strBase64 {
	const char * objPointer = [strBase64 cStringUsingEncoding:NSASCIIStringEncoding];
	int intLength = strlen(objPointer);
	int intCurrent;
	int i = 0, j = 0, k;
    
	unsigned char * objResult;
	objResult = calloc(intLength, sizeof(char));
    
	// Run through the whole string, converting as we go
	while ( ((intCurrent = *objPointer++) != '\0') && (intLength-- > 0) ) {
		if (intCurrent == '=') {
			if (*objPointer != '=' && ((i % 4) == 1)) {// || (intLength > 0)) {
				// the padding character is invalid at this point -- so this entire string is invalid
				free(objResult);
				return nil;
			}
			continue;
		}
        
		intCurrent = _base64DecodingTable[intCurrent];
		if (intCurrent == -1) {
			// we're at a whitespace -- simply skip over
			continue;
		} else if (intCurrent == -2) {
			// we're at an invalid character
			free(objResult);
			return nil;
		}
        
		switch (i % 4) {
			case 0:
				objResult[j] = intCurrent << 2;
				break;
                
			case 1:
				objResult[j++] |= intCurrent >> 4;
				objResult[j] = (intCurrent & 0x0f) << 4;
				break;
                
			case 2:
				objResult[j++] |= intCurrent >>2;
				objResult[j] = (intCurrent & 0x03) << 6;
				break;
                
			case 3:
				objResult[j++] |= intCurrent;
				break;
		}
		i++;
	}
    
	// mop things up if we ended on a boundary
	k = j;
	if (intCurrent == '=') {
		switch (i % 4) {
			case 1:
				// Invalid state
				free(objResult);
				return nil;
                
			case 2:
				k++;
				// flow through
			case 3:
				objResult[k] = 0;
		}
	}
    
	// Cleanup and setup the return NSData
	NSData * objData = [[NSData alloc] initWithBytes:objResult length:j];
	free(objResult);
	return objData;
}

- (id)objectToDictionaryOrArray:(id)obj
{
    if ([obj isKindOfClass:[NSDictionary class]])
    {
        //NSLog(@"Is dictionary");
        NSMutableDictionary *outputObject = [[NSMutableDictionary alloc] init];
        for(id key in obj)
        {
            //NSLog(@"Reading key: %@", key);
            [outputObject setValue:[self objectToDictionaryOrArray:[obj valueForKey:key]] forKey:key];
        }
        
        return outputObject;
    }
    else if ([obj isKindOfClass:[NSArray class]])
    {
        //NSLog(@"Is Array");
        NSMutableArray *outputObject = [[NSMutableArray alloc] init];
        for (id object in obj) 
        {
            [outputObject addObject:[self objectToDictionaryOrArray:object]];
        }
        
        return outputObject;
    }
    else if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]])
    {
        return obj;
    }
    else if ([obj isKindOfClass:[NSDate class]])
    {
        NSDateFormatter *dateWriter = [[NSDateFormatter alloc] init];
        [dateWriter setDateFormat:self.defaultDateFormat];
        return [dateWriter stringFromDate:(NSDate *)obj];
    }
    else if ([obj isKindOfClass:[NSData class]])
    {
        return [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
    }
    else
    {
        NSMutableDictionary *outputObject = [[NSMutableDictionary alloc] init];
        NSDateFormatter *dateWriter = [[NSDateFormatter alloc] init];
        [dateWriter setDateFormat:self.defaultDateFormat];
        
        Class clazz = [obj class];
        u_int count;
        
        Ivar* ivars = class_copyIvarList(clazz, &count);
        for (int i = 0; i < count ; i++)
        {
            const char* ivarName = ivar_getName(ivars[i]);
            //NSLog(@"Reading iVar: %@", [NSString  stringWithCString:ivarName encoding:NSUTF8StringEncoding]);
            id ivarValue = [obj valueForKey:[NSString  stringWithCString:ivarName encoding:NSUTF8StringEncoding]];
            //object_getInstanceVariable(obj, ivarName, (void**)&ivarValue);
            //[ivarArray addObject:[NSString  stringWithCString:ivarName encoding:NSUTF8StringEncoding]];
            [outputObject setValue:ivarValue forKey:[NSString  stringWithCString:ivarName encoding:NSUTF8StringEncoding]];
        }
        free(ivars);
        
        objc_property_t* properties = class_copyPropertyList(clazz, &count);
        for (int i = 0; i < count ; i++)
        {
            const char* propertyName = property_getName(properties[i]);
            //NSLog(@"Reading property: %@", [NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]);
            id propValue = nil;
            @try {
                propValue = [obj valueForKey:[NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]];
            }
            @catch (NSException *exception) {
                NSLog(@"Error while reading the value for %@", [NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]);
            }
            
            if (propValue)
            {
                [outputObject setValue:[self objectToDictionaryOrArray:propValue] forKey:[NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]];
            }
            
            //[propertyArray addObject:[NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]];
        }
        free(properties);
        
        return outputObject;
    }
}

- (id)dictionaryOrArray:(id)dictionaryOrArray toObject:(Class)objectClass
{
    id outputObject = NSClassFromString(NSStringFromClass(objectClass));
    u_int count;
    
    if ([dictionaryOrArray isKindOfClass:[NSDictionary class]])
    {
        for(id key in dictionaryOrArray)
        {
            Class valuetype = nil;
            objc_property_t* properties = class_copyPropertyList(objectClass, &count);
            for (int i = 0; i < count ; i++)
            {
                const char* propertyName = property_getName(properties[i]);
                if ([(NSString *)key isEqualToString:[NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]])
                {
                    valuetype = [[outputObject propertyForKey:key] class];
                }
            }
            free(properties);

            if (valuetype)
                [outputObject setValue:[self dictionaryOrArray:[dictionaryOrArray valueForKey:key] toObject:valuetype ] forKey:key];
        }
        return outputObject;
    }
    else if ([dictionaryOrArray isKindOfClass:[NSArray class]])
    {
        //for (id obj in dictionaryOrArray)
        //{
            
        //}
        return outputObject;
    }
    else if ([dictionaryOrArray isKindOfClass:[NSString class]] || [dictionaryOrArray isKindOfClass:[NSNumber class]])
    {
        return dictionaryOrArray;
    }
    else if ([dictionaryOrArray isKindOfClass:[NSDate class]])
    {
        NSDateFormatter *dateWriter = [[NSDateFormatter alloc] init];
        [dateWriter setDateFormat:self.defaultDateFormat];
        return [dateWriter stringFromDate:(NSDate *)dictionaryOrArray];
    }
    return nil;
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Received error while calling APIs: %@", error.debugDescription);
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"Received authentication challenge");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //NSLog(@"Did finish loading");
    if (!deviceRegistered)
    {
        // we don't need to register the device at this point anymore as it is registered as
        // soon as the password for the application connection is set
        //[self registerDevice];
        deviceRegistered = YES;
    }
    
    // if we are downloading a file then call the handler without parsing the response
    // as a string
    if (connection.CBFunctionName == @"download" && connection.downloadHandler != nil)
    {
        connection.downloadHandler(connection.responseData);
        return;
    }
    else
    {
        // parse the response
        CBHelperResponseInfo *res = [[CBHelperResponseInfo alloc] init];
        res.function = connection.CBFunctionName;
        res.statusCode = [connection.responseStatusCode integerValue];
        res.responseString = [[NSString alloc] initWithData:connection.responseData encoding:NSUTF8StringEncoding];
        // uncomment this to see the full response data
        //NSLog(@"Received: %@", res.responseString);
        if (res.statusCode != 200)
            NSLog(@"Status code: %i", res.statusCode);
        
        if ([connection.responseStatusCode intValue] == 200) {
            NSDictionary *respData = [connection.responseData JSONValue];
    
            NSDictionary *functionOutput = [respData objectForKey:res.function];
            
            if ([functionOutput objectForKey:@"status"] != nil)
            {
                res.postSuccess = ([[functionOutput objectForKey:@"status"] isEqualToString:@"OK"]);
                res.errorMessage = (NSString *)[functionOutput objectForKey:@"error"];
                res.responseData = [functionOutput objectForKey:@"message"];
            }
            else
                [NSException raise:@"unexpected" format:@"Could not find message object"];
        }

        // if we the delegate protocol has been implemented then call the method
        if ([delegate respondsToSelector:@selector(requestCompleted:)])
        {
            [delegate performSelector:@selector(requestCompleted:) withObject:res];
        }
        // if we have a block handler for the response then trigger the handler
        if (connection.outputHanlder != nil)
        {
             connection.outputHanlder(res);
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // progressively add data chuncks to the response data as they are received
    if (connection.responseData == nil)
    {
        connection.responseData = [[NSMutableData alloc] init];
    }
    
    [connection.responseData appendData:data];
    
    // if the protocol method is implemented then trigger it - this is mostly used to display progress bars
    // for large upload/downloads
    if ([self.delegate respondsToSelector:@selector(didReceiveResponseData:totalBytesExpected:)])
    {
        NSNumber *receivedDataSize = [NSNumber numberWithInt:connection.responseData.length];
        [self.delegate performSelector:@selector(didReceiveResponseData:totalBytesExpected:) withObject:receivedDataSize withObject:connection.totalResponseBytes];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    connection.totalResponseBytes = [NSNumber numberWithLong:response.expectedContentLength];
    connection.responseStatusCode = [NSNumber numberWithInteger:response.statusCode];
}


- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    // if the protocol method is implemented then trigger it - this is mostly used to display progress bars
    // for large upload/downloads
    if ([self.delegate respondsToSelector:@selector(didSendBodyData:totalBytesExpectedToWrite:)])
    {
        [self.delegate performSelector:@selector(didSendBodyData:totalBytesExpectedToWrite:) withObject:[NSNumber numberWithInt:totalBytesWritten] withObject:[NSNumber numberWithInt:totalBytesExpectedToWrite]];
    }
}

@end

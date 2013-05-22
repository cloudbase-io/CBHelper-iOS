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
#include <CommonCrypto/CommonDigest.h>
#include <objc/runtime.h>
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/socket.h>
#include <netinet/in.h>
// we need the SystemConfiguration framework to detect whether an internet
// connection is available
#include <SystemConfiguration/SystemConfiguration.h>
#include "CBHelperResponseInfo.h"
#include "SBJson.h"
#include "NSData+Additions.h"
#include "NSObject+SBJson.h"
#include "CBDataSearchConditionGroup.h"
#include "NSURLConnection+CBHelper.h"
#include "CBHelperAttachment.h"
#include "CBPayPalBill.h"
#include "CBDataAggregationCommand.h"
#include "CBDataAggregationCommandGroup.h"
#include "CBDataAggregationCommandProject.h"
#include "CBQueuedRequest.h"

#define SYSTEM_VERSION_GREATER_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)


#ifndef CBHELPER_H_
#define CBHELPER_H_

/*! \mainpage cloudbase.io iOS Helper Class Reference
 *
 * \section intro_sec Introduction
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 2, as published by
 * the Free Software Foundation.<br/><br/>
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.<br/><br/>
 
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to the Free
 * Software Foundation, 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.<br/><br/>
 *
 * \section install_sec Getting Started
 *
 * The cloudbase.io iOS helper class compiles to .a library. The project
 * needs to be part of your workspace and the CBHelper directory in your path for
 * additional includes.<br/><br/>
 * To be able to compile your application make sure that the "Other Linker Flags"
 * for the CBHelperTestApp target include the following two options:<br/>
 * -ObjC<br/>
 * -all_load<br/><br/>
 *
 * This full reference is a companion to <a href="/documentation/ios/get-started" target="_blank">
 * the tutorial on the cloudbase.io website<a/>
 */

/*
 * Methods available to the delegate class
 */ 
@protocol CBHelperDelegate

@optional
/**
 * This method is invoked whenever a new request is started right after the shouldQueueRequest cal.
 * This gives back control of the NSURLConnection to your application and you can use it to cancel
 * the connection. If you modify the delegate settings of the object then the CBHelper object won't be
 * able to process the response and return it to your application either through this protocol or the 
 * block methods.
 * @param request The cloudbase.io request object being sent
 * @param connection The NSURLConnection object.
 */
- (void)requestSent:(CBQueuedRequest *)request withConnection:(NSURLConnection *)connection;
/**
 * This method is invoked whenever a request to the APIs is completed.
 * @param response The CBHelperResponseInfo object representing the data received from the APIs
 */
- (void)requestCompleted:(CBHelperResponseInfo *)response;
/**
 * Use this method to monitor the status of the upload of a post request. Particularly useful
 * if what you are sending is large data such as an image
 * @param totalBytesWritten The number of bytes sent so far in the request
 * @param totalBytesExpectedToWrite The total size of the request in bytes
 */
- (void)didSendBodyData:(NSNumber *)totalBytesWritten totalBytesExpectedToWrite:(NSNumber *)totalBytesExpectedToWrite;
/**
 * This method is triggered as data is received for a response. Useful for big responses as it will
 * allow you to display a progress bar
 * @param bytesReceived the total bytes received so far
 * @param totalBytesExpected The total number of bytes expected for the response. -1 if not known
 */
- (void)didReceiveResponseData:(NSNumber *)bytesReceived totalBytesExpected:(NSNumber *)totalBytesExpected;
/**
 * This method is called on the delegate before each request to decide whether the call should be queued in case of 
 * failure.
 * @param A CBQueuedRequest object containing all of the parameters for the API call
 * @return YES if the request should be queued in case of failure
 */
- (BOOL)shouldQueueRequest:(CBQueuedRequest*)request;
/**
 * This selector is called every time a request that was queued is successfully executed
 * @param the CBQueuedRequest object
 * @param the parsed CBHelperResponseInfo object
 */
- (void)queuedRequestExecuted:(CBQueuedRequest*)request withResponse:(CBHelperResponseInfo*)resp;
/**
 * @param The CBQueuedRequest object
 * @param The output data from the download
 */
- (void)queuedDownloadExecuted:(CBQueuedRequest*)request withResponse:(NSMutableData*)resp;
@end

// private variables for teh helper class
@interface CBHelper : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    BOOL deviceRegistered;
    
    NSString *_password;
    NSString *sessionid; // the session id generated when the device is registered.
    NSString *language; // the language of the device
    NSString *country;
    
    SBJsonStreamParser *parser; // the json parser an adapter
    SBJsonStreamParserAdapter *adapter;
    
    // Response data for the http posts
    NSString *apiCallURL;
    
    // http request
    NSString *requestParamBoundary;
}

/// possible log levels
typedef enum {
    CBLogLevelDebug,
    CBLogLevelInfo,
    CBLogLevelWarning,
    CBLogLevelError,
    CBLogLevelFatal,
    CBLogLevelEvent
} CBLogLevel;

@property (nonatomic, strong, retain) NSString *password;

@property (nonatomic, retain) NSString *defaultLogCategory; /// default cateogory for logs. If not set this will be automatically initialised to "DEFAULT"
/// a unique identifier for the device. By default we'll use the uniqueIdentifier of the UIDevice which
/// has since been deprecated. This can be overwritter by the developer with whatever unique they will want to use
@property (nonatomic, retain) NSString *deviceUniqueIdentifier;

/**
 * This is the default timeout for http connections sent to the cloudbase.io APIs.
 * by default this is set to 5 seconds. Override this value when the helper class is
 * initialized to set custom timeouts in seconds.
 */
@property (nonatomic) NSTimeInterval httpConnectionTimeout;

@property (retain) NSString *domain; /// domain for the apis. default to api.cloudbase.io
@property (nonatomic) BOOL isHttps; /// HTTPS or not?
@property (retain) NSString *appCode; /// application code
@property (retain) NSString *appSecret; /// application secret code
//@property (nonatomic, retain) NSString *password; /// md5 of the application password
/// the formatting for the dates. This is important as the frontend of the website expects dates to be
/// formatted in the default CBHelper format. If this is changed the website will no longer be able to parse dates
@property (nonatomic, retain) NSString *defaultDateFormat;
@property (nonatomic, retain) CLLocation *currentLocation; /// property to store the location if useLocation is enabled

@property (nonatomic, retain) id delegate;

@property (nonatomic, retain) NSString *authUsername;
@property (nonatomic, retain) NSString *authPassword;

/// Apple push notification token
@property (nonatomic, retain) NSData *notificationToken;

/// The notification certificate to use, either development or production
@property (nonatomic, retain) NSString *notificationCertificateType;

@property (nonatomic) BOOL debugMode;


- (NSString *)generateURL;


// exposed methods

/**
 * Initialisation method for the helper class with the required parameters. The password is sent separately in the
 * password field.
 * @param code The applcation code from the cloudbase website (for example test-app)
 * @param secret The application secret code generated by cloudbase. This is accessible from you application home page
 * @return An initialised CBHelper object
 */
- (id)initForApp:(NSString *)code withSecret:(NSString *)secret;

/** @name Accessory methods */
- (void)setPassword:(NSString *)value;

/**
 * Returns the sessionid generated by cloudbase.io for the current session for the device
 * @return The generated sessionid. This may be null if the cloudbase.io server were unable to generate a session id
 */
- (NSString *)getSessionID;

/**
 * Generates the request body for a parameter
 * @param paramName the name of the request parameter
 * @param paramValue The value for the parameter
 * @return An NSData object with the request body data for the parameter
 */
- (NSData *)requestBodyForParameter:(NSString *)paramName withValue:(NSString *)paramValue;

/**
 * Generates the request body for an attachment file
 * @param attachment The CBHelperAttachment object representing the file
 * @return An NSData object with the request body data for the parameter
 */
- (NSData *)requestBodyForFile:(CBHelperAttachment *)attachment withOrder:(NSInteger)fileNum;

/**
 * Converts the given object to a MutableDictionary or Array. Only @property elements of the object will be considered.
 * @param obj The object to be converted.
 * @return An NSMutableDictionary or NSMutableArray depending on the object passed as input
 */
- (id)objectToDictionaryOrArray:(id)obj;

/**
 * !!! EXPERIMENTAL !!!
 * Tries to populate a new object of the given Class with the data contained in the Dictionary or Array passed. This 
 * will only process top level properties and cannot populate Dictionary/Array within the object as it will have no 
 * indication of what Class the contained objects should be.
 * @param dictionaryOrArray The dictionary or array containing the data for the object
 * @param objectClass The Class representation of the object to be filled
 * @return A populated object of the given Class
 */
- (id)dictionaryOrArray:(id)dictionaryOrArray toObject:(Class)objectClass;

/**
 * Prepares the JSON encoded form and attaches the location data if needed then calls the sendRequest. 
 * It also appends additional paramters to the HTTP Post. This is used for CloudFunction calls
 * This method should not be used directly.
 * @param A CBQueuedRequest object
 * @param handler The block to be executed once the request is completed
 */
- (void)sendPost:(CBQueuedRequest*)request whenDone:(void (^) (CBHelperResponseInfo *response))handler;

/**
 * Returns a unique identifier for the user/application on the device
 * Use in iOS5 instad of the deprecated Device > UniqueIdentifier
 * @return An NSString containing a unique identifier for the device/user
 */
+ (NSString *)GetUUID;
/**
 * Encodes an NSString with md5
 * @param str The string to be encoded
 * @return The md5 hash of the given string
 */
+ (NSString *) md5:(NSString *)str;
/**
 * Produces a base64 encoded string with the given data. This is used by this class to prepare images
 * to upload to your database
 * @param objData The NSData object to be encoded
 * @return The base64 encoded string
 */
+ (NSString *)encodeBase64WithData:(NSData *)objData;
/**
 * creates an NSData object from a base46 encoded string
 * @param strBase64 The base64 encoded string
 * @return The NSData 
 */
+ (NSData *)decodeBase64WithString:(NSString *)strBase64;

/**
 * return the Mac Address of the current device. This is used to generate a unique id
 * if all else fails
 * @return The NSString representation of the mac address
 */
+ (NSString *)getMacaddress;

/**
 * This method is copied from the Apple Reachability example and checks whether an internet
 * connection is available
 * @return NO if the internet connection is offline
 */
+ (BOOL)hasConnectivity;

/**
 * Returns the directory used by the cloudbase.io helper class to store queued requests.
 * @return The NSString path to the requeust queue folder
 */
+ (NSString*)getRequestQueueDirectory;

/**
 * Empties the queue of requests.
 */
- (void)flushQueue;

- (void)registerDevice;
/** @name Logging functions */
/**
 * Logs a message to the application database in the given cateogry and level. This is a generic method and should not
 * be called directly unless there is a need to go outside the standard logging levels. It is possible to use a custom
 * level however it is not advised as it might not work correctly with the statistics functionality.
 * Once the execution is completed the requestCompleted method in the delegate object is triggered.
 * @param line The log message
 * @param cat The string Category for the message
 * @param level The severity level of the log message
 */
- (void)log:(NSString *)line forCategory:(NSString *)cat atLevel:(CBLogLevel)level;
/**
 * Log a debug message. Once the execution is completed the requestCompleted method in the delegate object is called.
 * @param line The log message
 * @param cat The logging category
 */
- (void)logDebug:(NSString *)line forCategory:(NSString *)cat;
/**
 * Log a debug message in the default cateogory. Once the execution is completed the requestCompleted method in 
 * the delegate object is called.
 * @param line The log message
 */
- (void)logDebug:(NSString *)line;
/**
 * Log an info message. Once the execution is completed the requestCompleted method in the delegate object is called.
 * @param line The log message
 * @param cat The logging category
 */
- (void)logInfo:(NSString *)line forCategory:(NSString *)cat;
/**
 * Log an info message in the default cateogory. Once the execution is completed the requestCompleted method in 
 * the delegate object is called.
 * @param line The log message
 */
- (void)logInfo:(NSString *)line;
/**
 * Log a warning message. Once the execution is completed the requestCompleted method in the delegate object is called.
 * @param line The log message
 * @param cat The logging category
 */
- (void)logWarning:(NSString *)line forCategory:(NSString *)cat;
/**
 * Log a warning message in the default cateogory. Once the execution is completed the requestCompleted method in 
 * the delegate object is called.
 * @param line The log message
 */
- (void)logWarning:(NSString *)line;
/**
 * Log an error message. Once the execution is completed the requestCompleted method in the delegate object is called.
 * @param line The log message
 * @param cat The logging category
 */
- (void)logError:(NSString *)line forCategory:(NSString *)cat;
/**
 * Log an error message in the default cateogory. Once the execution is completed the requestCompleted method in 
 * the delegate object is called.
 * @param line The log message
 */
- (void)logError:(NSString *)line;
/**
 * Log a fatal message. Once the execution is completed the requestCompleted method in the delegate object is called.
 * @param line The log message
 * @param cat The logging category
 */
- (void)logFatal:(NSString *)line forCategory:(NSString *)cat;
/**
 * Log a fatal message in the default cateogory. Once the execution is completed the requestCompleted method in 
 * the delegate object is called.
 * @param line The log message
 */
- (void)logFatal:(NSString *)line;
/**
 * Log an event message. Once the execution is completed the requestCompleted method in the delegate object is called.
 * @param line The log message
 * @param cat The logging category
 */
- (void)logEvent:(NSString *)line forCategory:(NSString *)cat;
/**
 * Log an event message in the default cateogory. Once the execution is completed the requestCompleted method in 
 * the delegate object is called.
 * @param line The log message
 */
- (void)logEvent:(NSString *)line;
/**
 * Log the navigation to a new UIViewController
 * @param viewName An NSString representing the unique name for the loaded UIViewController
 */
- (void)logNavigation:(NSString *)viewName;


/** @name Data functions */
/**
 * Inserts the given object in a cloudbase collection. If the collection does not exist it is automatically created.
 * Similarly if the data structure of the given object is different from documents already present in the collection
 * the structure is automatically altered to accommodate the new object.
 * The system will automatically try to serialise any object sent to this function. However, we recommend you use
 * the simplest possible objects to hold data if not an NSDictionary or NSArray directly. The objectToDictionaryOrArray
 * method of this class can be used to serialise objects before handing them over to this function and check what the
 * generated NSArray would be.
 * Once the call to the APIs is completed the requestCompleted method is triggered in the delegate.
 * @param obj The objec to be inserted in the collection
 * @param collectionName The name of the collection (table) in your cloudbase database.
 */
- (void)insertDocument:(id)obj inCollection:(NSString *)collectionName;

/**
 * Inserts the given object in a cloudbase collection. If the collection does not exist it is automatically created.
 * Similarly if the data structure of the given object is different from documents already present in the collection
 * the structure is automatically altered to accommodate the new object.
 * The system will automatically try to serialise any object sent to this function. However, we recommend you use
 * the simplest possible objects to hold data if not an NSDictionary or NSArray directly. The objectToDictionaryOrArray
 * method of this class can be used to serialise objects before handing them over to this function and check what the
 * generated NSArray would be.
 * Once the call to the APIs is completed the requestCompleted method is triggered in the delegate.
 * @param obj The objec to be inserted in the collection
 * @param collectionName The name of the collection (table) in your cloudbase database.
 * @param attachments An array of CBHelperAttachment objects to be associated with the document
 */
- (void)insertDocument:(id)obj inCollection:(NSString *)collectionName withFiles:(NSArray *)attachments;

/**
 * Inserts the given object in a cloudbase collection. If the collection does not exist it is automatically created.
 * Similarly if the data structure of the given object is different from documents already present in the collection
 * the structure is automatically altered to accommodate the new object.
 * The system will automatically try to serialise any object sent to this function. However, we recommend you use
 * the simplest possible objects to hold data if not an NSDictionary or NSArray directly. The objectToDictionaryOrArray
 * method of this class can be used to serialise objects before handing them over to this function and check what the
 * generated NSArray would be.
 * Once the call to the APIs is completed the requestCompleted method is triggered in the delegate.
 * @param obj The objec to be inserted in the collection
 * @param collectionName The name of the collection (table) in your cloudbase database.
 * @param handler A block to handle the response from the web services
 */
- (void)insertDocument:(id)obj inCollection:(NSString *)collectionName whenDone:(void (^) (CBHelperResponseInfo *response))handler;

/**
 * Inserts the given object in a cloudbase collection. If the collection does not exist it is automatically created.
 * Similarly if the data structure of the given object is different from documents already present in the collection
 * the structure is automatically altered to accommodate the new object.
 * The system will automatically try to serialise any object sent to this function. However, we recommend you use
 * the simplest possible objects to hold data if not an NSDictionary or NSArray directly. The objectToDictionaryOrArray
 * method of this class can be used to serialise objects before handing them over to this function and check what the
 * generated NSArray would be.
 * Once the call to the APIs is completed the requestCompleted method is triggered in the delegate.
 * @param obj The objec to be inserted in the collection
 * @param collectionName The name of the collection (table) in your cloudbase database.
 * @param attachments An array of CBHelperAttachment objects to be associated with the document
 * @param handler A block to handle the response from the web services
 */
- (void)insertDocument:(id)obj inCollection:(NSString *)collectionName withFiles:(NSArray *)attachments whenDone:(void (^) (CBHelperResponseInfo *response))handler;

/**
 * !!!EXPERIMENTAL!!!
 * Updates all of the documents in the given collection matching the search conditions with the given object.
 * @param obj The object to update the documents' values to.
 * @param conditions The search conditions to find the documents to tbe updated
 * @param collection The name of the collection (table) in your cloudbase database.
 */
- (void)updateDocument:(id)obj where:(CBDataSearchConditionGroup *)conditions inCollection:(NSString *)collection;

/**
 * !!!EXPERIMENTAL!!!
 * Updates all of the documents in the given collection matching the search conditions with the given object.
 * @param obj The object to update the documents' values to.
 * @param conditions The search conditions to find the documents to tbe updated
 * @param collection The name of the collection (table) in your cloudbase database.
 * @param handler block of code to execute once the request is completed
 */
- (void)updateDocument:(id)obj where:(CBDataSearchConditionGroup *)conditions inCollection:(NSString *)collection whenDone:(void (^) (CBHelperResponseInfo *response))handler;
;
/**
 * Returns all of the document elements within a collection. The data is accessible from the CBHelperResponseOInfo
 * object passed to the requestCompleted method of the delegate.
 * @param collection The name of the collection to be extracted
 */
- (void)searchAllDocumentsInCollection:(NSString *)collection;

/**
 * Returns all of the document elements within a collection. The data is accessible from the CBHelperResponseOInfo
 * object passed to the requestCompleted method of the delegate.
 * @param collection The name of the collection to be extracted
 * @param handler block of code to execute once the request is completed
 */
- (void)searchAllDocumentsInCollection:(NSString *)collection whenDone:(void (^) (CBHelperResponseInfo *response))handler;
/**
 * Runs a search over a collection with the given criteria. The documents matching the search critirea are then
 * returned in the CBHelperResponseInfo object passed to the requestCompleted method of the delegate.
 * @param conditions A set of search conditions
 * @param collection The name of the collection to run the search over
 */
- (void)searchDocumentWithConditions:(CBDataSearchConditionGroup *)conditions inCollection:(NSString *)collection;
/**
 * Runs a search over a collection with the given criteria. The documents matching the search criteria are then
 * returned in the CBHelperResponseInfo object passed to the requestCompleted method of the delegate.
 * @param conditions A set of search conditions
 * @param collection The name of the collection to run the search over
 * @param handler block of code to execute once the request is completed
 */
- (void)searchDocumentWithConditions:(CBDataSearchConditionGroup *)conditions inCollection:(NSString *)collection whenDone:(void (^) (CBHelperResponseInfo *response))handler;

/**
 * Runs a search over a collection and applies the given list of aggregation commands to the output.
 * @param aggregateConditions A List of CBDataAggregationCommand objects
 * @param collection The name of the collection to run the search over
 * @param handler a block of code to be executed once the request is completed
 */
- (void)searchDocumentWithAggregates:(NSMutableArray *)aggregateConditions inCollection:(NSString *)collection whenDone:(void (^) (CBHelperResponseInfo *response))handler;
/**
 * This methods downloads a file associated with a record in the cloudbase database. The data is then returned to the handler 
 * block.
 * During the download of the data the didReceiveResponseData method of the protocol is triggered.
 * @param fileId The cloudbase file ID returned as part of a document
 * @param handler A block to handle the data being downloaded
 */
- (void)downloadFileData:(NSString *)fileId whenDone:(void (^)(NSData *fileContent))handler;


/** @name Push notification functions */

/**
 * Subscribes the devices with the current token received from Apple to a notification channel. All devices are
 * autmatically subscribed to the channel <strong>all</strong>.
 * @param deviceToken The token received from the didRegisterForRemoteNotifications method
 * @param channel The name of the channel to subscribe to. If the channel doesn't yet exist it will be created
 */
- (void)subscribeDeviceWithToken:(NSData *)deviceToken toNotificationChannel:(NSString *)channel;

/**
 * Unsubscribes the devices with the current token received from Apple from a notification channel. 
 * @param deviceToken The token received from the didRegisterForRemoteNotifications method
 * @param channel The name of the channel to unsubscribe from.
 * @param removeCompletely If true the device is also unsubscribed from the <strong>all</strong> channel
 */
- (void)unsubscribeDeviceWithToken:(NSData *)deviceToken fromNotificationChannel:(NSString *)channel andAll:(BOOL)removeCompletely;

/**
 * Send an email to the specified recipient using the given template
 * @param templateCode The template code generated on cloudbase.io
 * @param recipient The email address of the email recipient
 * @param subject The subject of the email
 * @param vars The variables to fill the template
 */
- (void)sendEmail:(NSString *)templateCode to:(NSString *)recipient withSubject:(NSString *)subject andVars:(NSDictionary *)vars;
/**
 * If client notifications are enabled then this method will send a notification to all devices subscribed to a 
 * particular channel.
 * @param text The notification text
 * @param badgeNum The badge number for the notification
 * @param soundName The string representing the sound to be played with the notification
 * @param channel The name of the channel to send the notification to <strong>all</strong> will send to all the devices
 * using the application
 */
- (void)sendNotification:(NSString *)text withBadge:(NSInteger)badgeNum andSound:(NSString *)soundName toChannel:(NSString *)channel;

/**
 * If client notifications are enabled then this method will send a notification to all devices subscribed to the 
 * channels in the given array
 * @param text The notification text
 * @param badgeNum The badge number for the notification
 * @param soundName The string representing the sound to be played with the notification
 * @param channel The name of the channel to send the notification to <strong>all</strong> will send to all the devices
 * using the application
 */
- (void)sendNotification:(NSString *)text withBadge:(NSInteger)badgeNum andSound:(NSString *)soundName toChannels:(NSArray *)channel;

/** @name CloudFunctions methods */

/**
 * Executes a CloudFunction on demand.
 * @param fcode The function code for the function to be executed
 */
- (void)executeCloudFunction:(NSString *)fcode;

/**
 * Executes a CloudFunction on demand.
 * @param fcode The function code for the function to be executed
 * @param params The parameters for the function
 */
- (void)executeCloudFunction:(NSString *)fcode withParameters:(NSDictionary *)params;

/**
 * Executes a CloudFunction on demand and handles the response from the service with a block.
 * @param fcode The function code for the function to be executed
 * @param params The parameters for the function
 * @param handler A block to manage the results returned from the server
 */
- (void)executeCloudFunction:(NSString *)fcode withParameters:(NSDictionary *)params whenDone:(void (^) (CBHelperResponseInfo *response))handler;

/**
 * Executes an applet on demand.
 * @param fcode The applet code for the function to be executed
 * @param params The parameters for the applet
 */
- (void)executeApplet:(NSString *)fcode withParameters:(NSDictionary *)params;

/**
 * Executes an applet on demand and handles the response from the service with a block.
 * @param fcode The applet code for the function to be executed
 * @param params The parameters for the applet
 * @param handler A block to manage the results returned from the server
 */
- (void)executeApplet:(NSString *)fcode withParameters:(NSDictionary *)params whenDone:(void (^) (CBHelperResponseInfo *response))handler;

/**
 * Executes an Shared API on demand and handles the response from the service with a block.
 * @param fcode The applet code for the function to be executed
 * @param params The parameters for the applet
 * @param password The password for the Shared API if required
 * @param handler A block to manage the results returned from the server
 */
- (void)executeSharedApi:(NSString *)fcode withParameters:(NSDictionary *)params andPassword:(NSString *)password whenDone:(void (^) (CBHelperResponseInfo *response))handler;

/** @name PayPal digital goods sale integration */

/**
 * Calls PayPal and requests a token for the express checkout of digital goods.
 * The PayPal API credentials must be set in the cloudbase.io control panel for this method to work.
 * @param bill A populated CBPayPalBill object with at least one detail item
 * @param isLive Whether the call should be made to the PayPal production or sandbox environments
 * @param handler A block to manage the results returned from the server - specifically the token and checkout url
 */
- (void)preparePayPalPurchase:(CBPayPalBill*)bill onLiveEnvironment:(BOOL)isLive whenDone:(void (^) (CBHelperResponseInfo *response))handler;

/**
 * Calls PayPal and requests a token for the express checkout.
 * The PayPal API credentials must be set in the cloudbase.io control panel for this method to work.
 * @param bill A populated CBPayPalBill object with at least one detail item
 * @param isLive Whether the call should be made to the PayPal production or sandbox environments
 * @param digital Whether it is a digital goods transaction
 * @param handler A block to manage the results returned from the server - specifically the token and checkout url
 */
- (void)preparePayPalPurchase:(CBPayPalBill*)bill onLiveEnvironment:(BOOL)isLive forDigitalGoods:(BOOL)digital whenDone:(void (^) (CBHelperResponseInfo *response))handler;

/**
 * This method should be used from the UIWebView delegate method to intercept the web pages loaded and detect
 * the completion of the payment process. The method:
 * - (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
 * should be implemented returning the result of this CBHelper method.
 * @param request The request handed to the delegate method
 * @param handler A method to handle the completion of the payment once the user has gone through all the steps
 * @return NO if we have reached the end of the payment and we can go back to the cloudbase.io APIs
 */
- (BOOL)readPayPalResponse:(NSURLRequest*)request whenDone:(void (^) (CBHelperResponseInfo *response))handler;

/**
 * Retrieves the information about a PayPal purchase which has been initiated with the preparePayPalPurchase method.
 * The paymentId is returned when the payment is prepared and completed.
 * @param paymentId The payment id returned by cloudbase.io
 * @param handler A method to use the details returned by the cloudbase.io APIs
 */
- (void)getPayPalPaymentDetails:(NSString*)paymentId whenDone:(void (^) (CBHelperResponseInfo *response))handler;
@end

#endif

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

#include "CBHelper.h"
#include "CBGeoLocatedObject.h"

#ifndef CBGEODATASTREAM_H_
#define CBGEODATASTREAM_H_

#define CBGEODATASTREAM_UPDATE_SPEED    1.0
#define CBGEODATASTREAM_RADIUS_RATIO    4.0

/**
 * Objects implementing this protocol will interact with a CBGeoDataStream
 * object and will instruct it how to download the data as well as receive the 
 * data stream
 */
@protocol CBGeoDataStreamDelegate

/**
 * Returns the latest known position to the CBGeoDataStream object.
 * This is used to retrieve the data and compute the movement speed to
 * increase or decrease the speed of refresh
 *
 * @param streamName The unique identifier for the stream requesting an updated position
 * @return A valid CLLocation object
 */
- (CLLocation*) getLatestPositionFor:(NSString*)streamName;

/**
 * receives a new point to be visualized
 *
 * @param streamName The name of the stream object that received the updated point
 * @param CBGeoLocatedObject An object representing a new point on the map
 */
- (void) stream:(NSString*)streamName receivedPoint:(CBGeoLocatedObject*)point;

@optional
/**
 * Informs the application that the CBGeoDataStream is removing a point from its cache
 *
 * @param streamName The name of the stream object removing the point from its cache
 * @param CBGeoLocatedObject The point being removed
 */
- (void) stream:(NSString*)streamName isRemovingPoint:(CBGeoLocatedObject*)point;

@end

/**
 * Opens a persistent connection to a particular geo-coded connection on a
 * cloudbase.io Cloud Database and retrieves geo located data for the application.
 *
 * Data is handed back to the application using the protocol.
 *
 * This is meant to be used for augment reality applications.
 */
@interface CBGeoDataStream : NSObject
{
    CBHelper* helper;
    
    // The time to execute the call
    NSTimer* updateTimer;
    
    CLLocation* previousPosition;
    double previousSpeed;
    
    double queryRadius;
    
    NSMutableDictionary* foundObjects;
    
    NSString* streamName;
}

/**
 * The collection on which to run the search
 */
@property (nonatomic, retain) NSString* collection;
/**
 * The delegate object implementing the CBGeoDataStreamDelegate protocol
 */
@property (nonatomic, retain) id delegate;
/**
 * The radius for the next search in meters from the point returned by the 
 * getLatestPosition method
 */
@property (nonatomic) double searchRadius;

/**
 * Initializes a new CBGeoDataStream object and uses the given CBHelper
 * object to retrieve data from the cloudbase.io APIS.
 *
 * @param name A unique identifier for the stream object. This will be handed over to all the delegate calls
 * @param CBHelper An initialized CBHelper object
 * @param NSString The name of the collection to search
 */
- (id) initStream:(NSString*)name withHelper:(CBHelper*)initializedHelper onCollection:(NSString*)collectionName;

/**
 * Begins querying the cloudbase.io APIs and returning data periodically.
 */
- (void) startStream;

/**
 * Stops the data stream
 */
- (void) stopStream;

@end

#endif

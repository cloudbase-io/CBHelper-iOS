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


#import "CBGeoDataStream.h"

@interface CBGeoDataStream()

- (void) updateInformation: (NSTimer*)timer;

@end

@implementation CBGeoDataStream

@synthesize collection;
@synthesize delegate;
@synthesize searchRadius;

- (id) initStream:(NSString*)name withHelper:(CBHelper*)initializedHelper onCollection:(NSString*)collectionName {
    self = [super init];
    
    streamName = name;
    helper = initializedHelper;
    self.collection = collectionName;
    queryRadius = 50.0; // we start with 50 meters
    previousSpeed = 0.0;
    
    foundObjects = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void) startStream {
    // starts the timer
    updateTimer = [NSTimer scheduledTimerWithTimeInterval: CBGEODATASTREAM_UPDATE_SPEED target:self selector:@selector(updateInformation:) userInfo:nil repeats:YES];
}

- (void) updateInformation: (NSTimer*)timer {
    if ([self.delegate respondsToSelector:@selector(getLatestPositionFor:)]) {
        // get the latest position from the delegate
        CLLocation* currentLocation = [self.delegate performSelector:@selector(getLatestPositionFor:) withObject:streamName];
        
        if (helper.debugMode) {
            NSLog(@"running a search for %f, %f within %f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude, searchRadius);
            if (previousPosition != NULL) {
                NSLog(@"have previous position");
            }
        }
        
        // if we have a previous position calculate distance and speed
        // to decide whether it's worth running another search and the
        // queryRadius should be increased
        if (previousPosition != NULL) {
            CLLocationDistance distance = [currentLocation distanceFromLocation:previousPosition];
            
            // we haven't covered enough distance. no need for new data.
            if (distance < queryRadius / CBGEODATASTREAM_RADIUS_RATIO) {
                if (helper.debugMode) {
                    NSLog(@"Not enough distance between the two points. returning without fetching data");
                }
                return;
            }
            
            double speed = distance / CBGEODATASTREAM_UPDATE_SPEED;
            double ratio = 1.0;
            
            if (helper.debugMode) {
                NSLog(@"Computed speed %f meters per second", speed);
            }
            if (previousSpeed != 0.0) {
                ratio = speed/previousSpeed;
            }
            if (queryRadius * ratio < self.searchRadius) {
                queryRadius = self.searchRadius;
            } else {
                queryRadius = queryRadius * ratio;
            }
            
            previousSpeed = speed;
        }
        previousPosition = currentLocation;
        
        CBDataSearchConditionGroup* condition = [[CBDataSearchConditionGroup alloc] initWithGeoSearchNear:currentLocation.coordinate withinMaxDistance:queryRadius];
        
        [helper searchDocumentWithConditions:condition inCollection:self.collection whenDone:^(CBHelperResponseInfo *response) {
            if (response.postSuccess) {
                if ([response.responseData isKindOfClass:[NSArray class]]) {
                    
                    // loop over the result array
                    for (id curObject in response.responseData) {
                        if (![curObject isKindOfClass:[NSDictionary class]]) {
                            if (helper.debugMode) {
                                NSLog(@"Object is not of type NSDictionary");
                            }
                            continue;
                        }
                        NSMutableDictionary* dictionaryObject = curObject;
                        NSDictionary* locationData = [dictionaryObject valueForKey:@"cb_location"];
                        CLLocationDegrees lat = [[locationData valueForKey:@"lat"] doubleValue];
                        CLLocationDegrees lng = [[locationData valueForKey:@"lng"] doubleValue];
                
                        CBGeoLocatedObject* obj = [[CBGeoLocatedObject alloc] init];
                        obj.coordinate = CLLocationCoordinate2DMake(lat, lng);
                        obj.altitude = [[dictionaryObject valueForKey:@"cb_location_altitude"] doubleValue];
                        [dictionaryObject removeObjectForKey:@"cb_location"];
                        [dictionaryObject removeObjectForKey:@"cb_location_altitude"];
                        obj.objectData = dictionaryObject;
                        
                        if ([foundObjects valueForKey:[NSString stringWithFormat:@"%i", [obj hash]]] == NULL) {
                            [foundObjects setValue:obj forKey:[NSString stringWithFormat:@"%i", [obj hash]]];
                            
                            if ([delegate respondsToSelector:@selector(stream:receivedPoint:)]) {
                                [delegate performSelector:@selector(stream:receivedPoint:) withObject:streamName withObject:obj];
                            }
                        }
                    }
                }
            } else {
                if (helper.debugMode) {
                    NSLog(@"Error while calling the cloubdase.io APIs:\n%@", response.responseString);
                }
            }
            NSMutableArray *itemsToRemove = [[NSMutableArray alloc] init];
            [foundObjects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                CBGeoLocatedObject* curObj = obj;
                CLLocation* loc = [[CLLocation alloc] initWithLatitude:curObj.coordinate.latitude longitude:curObj.coordinate.longitude];
                //NSLog(@"computed distance between existing point and new center: %f with radius %f", [loc distanceFromLocation:currentLocation], searchRadius);
                if ([loc distanceFromLocation:currentLocation] > searchRadius) {
                    if ([delegate respondsToSelector:@selector(stream:isRemovingPoint:)]) {
                        [delegate performSelector:@selector(stream:isRemovingPoint:) withObject:streamName withObject:curObj];
                    }
                    [itemsToRemove addObject:key];
                }
            }];
            
            if ([itemsToRemove count] > 0) {
                [itemsToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [foundObjects removeObjectForKey:obj];
                }];
            }
            //NSLog(@"Done fetching");
        }];
        
    } else {
        [NSException raise:@"Missing delegate method" format:@"getLatestPosition selector not implemented in delegate"];
    }
}

- (void) stopStream {
    [updateTimer invalidate];
    [foundObjects removeAllObjects];
}

@end

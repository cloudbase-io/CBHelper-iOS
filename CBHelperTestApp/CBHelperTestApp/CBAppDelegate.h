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

#import <UIKit/UIKit.h>
#import "CBHelper.h"
// for the additional SBJson libraries to be loaded add these
// directives to the Other Linker Flags of your project -ObjC -all_load
#import "Settings.h"

@interface CBAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) CBHelper *helper; // The shared CBHelper object used throughout the application

// The token returned by apple when the application registers for push notification.
// For this to work the application needs to be signed.
@property (nonatomic, retain) NSData *notificationDeviceToken;

-(void)initNotificationsForApp:(UIApplication *)application;

@end

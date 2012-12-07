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

#import "Settings.h"

@implementation Settings

@synthesize appPwd, appCode, appSecret, deviceToken;

// the instance of this class is stored here
static Settings *myInstance = nil;

+ (Settings *)sharedInstance
{
    // check to see if an instance already exists
    if (nil == myInstance) {
        myInstance  = [[[self class] alloc] init];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self getFilePath]])
        {
            NSLog(@"Loading settings from file");
            NSMutableDictionary *set = [[NSMutableDictionary alloc] initWithContentsOfFile:[self getFilePath]];
            [self sharedInstance].appCode = [set objectForKey:@"app_code"];
            [self sharedInstance].appSecret = [set objectForKey:@"app_secret"];
            [self sharedInstance].appPwd = [set objectForKey:@"app_pwd"];
        }
        else
        {
            NSLog(@"Settings to empty");
            [self sharedInstance].appCode = @"";
            [self sharedInstance].appSecret = @"";
            [self sharedInstance].appPwd = @"";
        }
    }
    // return the instance of this class
    return myInstance;
}
+ (void)saveToFile
{
    NSMutableDictionary *set = [[NSMutableDictionary alloc] init];
    [set setValue:[self sharedInstance].appCode forKey:@"app_code"];
    [set setValue:[self sharedInstance].appPwd forKey:@"app_pwd"];
    [set setValue:[self sharedInstance].appSecret forKey:@"app_secret"];
    
    NSString *documentsDirectory = [self getFilePath];
    
    [set writeToFile:documentsDirectory atomically:NO];
}

+ (NSString *)getFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"cb_settings.plist"];
    NSLog(@"File path %@", documentsDirectory);
    return documentsDirectory;
}

@end

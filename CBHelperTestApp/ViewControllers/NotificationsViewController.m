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

#import "NotificationsViewController.h"

@interface NotificationsViewController ()

@end

@implementation NotificationsViewController

@synthesize channelName, notificationText;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)subscribeToChannel:(id)sender {
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.notificationDeviceToken != NULL) {
        [appDelegate.helper subscribeDeviceWithToken:appDelegate.notificationDeviceToken toNotificationChannel:channelName.text];
    }
    
}
-(IBAction)unsubscribeFromChannel:(id)sender {
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.notificationDeviceToken != NULL) {
        [appDelegate.helper unsubscribeDeviceWithToken:appDelegate.notificationDeviceToken fromNotificationChannel:channelName.text andAll:YES];
    }
}
-(IBAction)sendNotification:(id)sender {
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.notificationDeviceToken != NULL) {
        [appDelegate.helper sendNotification:notificationText.text withBadge:-1 andSound:NULL toChannel:channelName.text];
    }
}

// hide the keyboard once editing of a test field is done.
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end

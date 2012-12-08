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
#import <CoreLocation/CoreLocation.h>
#import "CBAppDelegate.h"
#import "TestDataObject.h"
#import "DataTableViewController.h"

@interface DataViewController : UIViewController <CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) CLLocationManager* locationManager;
@property (nonatomic, retain) UIImagePickerController* picker;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* activityIndicator;
@property (nonatomic, retain) IBOutlet UILabel* outputLabel;
@property (nonatomic, retain) IBOutlet UITextField* fileIdField;
@property (nonatomic, retain) NSMutableArray* searchData;

- (IBAction)switchLocationData:(id)sender;

- (IBAction)insertObject:(id)sender;
- (IBAction)insertObjectWithFiles:(id)sender;
- (IBAction)searchObjects:(id)sender;

- (IBAction)downloadFile:(id)sender;

- (BOOL) textFieldShouldReturn:(UITextField *)textField;

@end

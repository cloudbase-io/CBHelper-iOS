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

#import "DataViewController.h"

@interface DataViewController ()

- (TestDataObject*) createTestObject;

@end

@implementation DataViewController

@synthesize locationManager, picker, activityIndicator, outputLabel, searchData, fileIdField;

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

- (IBAction)switchLocationData:(id)sender
{
    bool isEnabled = ((UISwitch*)sender).on;
    
    NSLog(@"Switch location data: %s ", (isEnabled?"YES":"NO"));
    
    if (isEnabled)
    {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        [self.activityIndicator startAnimating];
        [self.locationManager startUpdatingLocation];
        
    }
    else
    {
        if (self.locationManager) {
            [self.locationManager stopUpdatingLocation];
        }
        self.locationManager = NULL;
    }
}

- (IBAction)insertObject:(id)sender
{
    TestDataObject *newObj = [self createTestObject];
    
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.helper)
    {
        [appDelegate.helper insertDocument:[appDelegate.helper objectToDictionaryOrArray:newObj] inCollection:@"test_users" whenDone:^(CBHelperResponseInfo *response) {
            // in this case we expect the response to be only a string saying "INSERTED"
            NSLog(@"response data is %@", NSStringFromClass([response.responseData class]));
            self.outputLabel.text = (NSString*)[response.responseData lowercaseString];//[response.responseData JSONRepresentation];
        }];
    }
}

- (IBAction)insertObjectWithFiles:(id)sender
{
    self.picker = [[UIImagePickerController alloc] init];
    
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    //[self presentModalViewController:picker animated:YES];
    [self presentViewController:picker animated:YES completion:^{
        NSLog(@"Presented view controller");
    }];
}

- (IBAction)searchObjects:(id)sender
{
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.helper)
    {
        [appDelegate.helper searchAllDocumentsInCollection:@"test_users" whenDone:^(CBHelperResponseInfo *response) {
            self.searchData = [[NSMutableArray alloc] init];
            
            if (response.postSuccess) {
                if ([response.responseData isKindOfClass:[NSArray class]])
                {
                    for (NSDictionary *tip in response.responseData)
                    {
                        //[tips addObject:[tip valueForKey:@"tip_text"]];
                        TestDataObject *obj = [[TestDataObject alloc] init];
                        obj.firstName = [tip valueForKey:@"firstName"];
                        obj.lastName = [tip valueForKey:@"lastName"];
                        obj.title = [tip valueForKey:@"title"];
                        
                        [self.searchData addObject:obj];
                    }
                    
                [self performSegueWithIdentifier:@"DataTableSegue" sender:self];
                }
            }
        }];
    }
}

- (IBAction)downloadFile:(id)sender {
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [appDelegate.helper downloadFileData:self.fileIdField.text whenDone:^(NSData *fileContent) {
        UIImage *downloadedImg = [UIImage imageWithData:fileContent];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:downloadedImg];
        
        [self.view addSubview:imageView];
    }];
}

-(IBAction)removeKeyboard
{
    [self.fileIdField resignFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"DataTableSegue"]) {
        DataTableViewController *destViewController = segue.destinationViewController;
        destViewController.data = self.searchData;
    }
}



#pragma mark - private methods
- (TestDataObject*) createTestObject {
    TestDataObject *newObj = [[TestDataObject alloc] init];
    newObj.firstName = @"Cloud";
    newObj.lastName = @"Base";
    newObj.title = @".io";
    
    return newObj;
}

#pragma mark - CLLocationManagerDelegate methods
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.helper.currentLocation = newLocation;
    [self.locationManager stopUpdatingLocation];
    [self.activityIndicator stopAnimating];
}

#pragma mark - UIPockerViewControllerDelegate methods
- (void)imagePickerControllerDidCancel:(UIImagePickerController *) Picker {
    
    //[[Picker parentViewController] dismissModalViewControllerAnimated:YES];
    [Picker dismissViewControllerAnimated:YES completion:^{

    }];
    
    self.picker = NULL;
}

- (void)imagePickerController:(UIImagePickerController *)Picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage* theImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    NSMutableArray* files = [[NSMutableArray alloc] init];
    
    CBHelperAttachment* att = [[CBHelperAttachment alloc] initForFile:@"firstimage.jpg" withData:UIImagePNGRepresentation(theImage)];
    
    [files addObject:att];
    
    TestDataObject* newObj = [self createTestObject];
    
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.helper)
    {
        [appDelegate.helper insertDocument:[appDelegate.helper objectToDictionaryOrArray:newObj] inCollection:@"test_users" withFiles:files whenDone:^(CBHelperResponseInfo *response) {
            NSLog(@"response data is %@", NSStringFromClass([response.responseData class]));
            self.outputLabel.text = (NSString*)[response.responseData lowercaseString];
        }];
    }
    
    [Picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}
@end

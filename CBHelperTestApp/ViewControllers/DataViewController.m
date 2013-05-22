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

    // present the picker - the insert completes in the delegate method below
    [self presentViewController:picker animated:YES completion:^{
        NSLog(@"Presented view controller");
    }];
}

- (IBAction)searchObjects:(id)sender
{
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.helper)
    {

        CBDataSearchConditionGroup* searchCondition = [[CBDataSearchConditionGroup alloc] initWithoutSubConditions];//[[CBDataSearchConditionGroup alloc] initWithField:@"firstName" is:CBOperatorEqual to:@"Cloud"];
        [searchCondition addSortField:@"firstName" withSortingDirection:CBSortDescending];
        searchCondition.limit = 10;
        
        [appDelegate.helper searchDocumentWithConditions:searchCondition inCollection:@"test_users" whenDone:^(CBHelperResponseInfo *response) {
            self.searchData = [[NSMutableArray alloc] init];
            
            if (response.postSuccess) {
                if ([response.responseData isKindOfClass:[NSArray class]])
                {
                    for (NSDictionary *tip in response.responseData)
                    {
                        TestDataObject *obj = [[TestDataObject alloc] init];
                        obj.firstName = [tip valueForKey:@"firstName"];
                        obj.lastName = [tip valueForKey:@"lastName"];
                        obj.title = [tip valueForKey:@"title"];
                        
                        [self.searchData addObject:obj];
                    }
                    
                    // show the data table screen. The method prepareforsegue passes along the searchData
                    // object.
                    [self performSegueWithIdentifier:@"DataTableSegue" sender:self];
                }
            }

        }];
    }
}

- (IBAction)searchAggregateObjects:(id)sender {
    NSMutableArray *aggregateCond = [[NSMutableArray alloc] init];
    
    CBDataAggregationCommandProject *projectCommand = [[CBDataAggregationCommandProject alloc] init];
    [projectCommand.includeFields addObject:@"Symbol"];
    [projectCommand.includeFields addObject:@"Price"];
    [projectCommand.includeFields addObject:@"total"];
    [projectCommand.includeFields addObject:@"count"];
    
    [aggregateCond addObject:projectCommand];
    
    NSMutableArray *symbols = [[NSMutableArray alloc] init];
    [symbols addObject:@"AAPL"];
    [symbols addObject:@"AMZN"];
    CBDataSearchConditionGroup *searchCond = [[CBDataSearchConditionGroup alloc] initWithField:@"Symbol" is:CBOperatorIn to:symbols];
    [searchCond addSortField:@"_id" withSortingDirection:CBSortAscending];
    searchCond.limit = 1;
    
    [aggregateCond addObject:searchCond];
    
    CBDataAggregationCommandGroup *groupCommand = [[CBDataAggregationCommandGroup alloc] init];
    [groupCommand addOutputField:@"Symbol"];
    [groupCommand addGroupFormulaFor:@"total" withOperator:CBDataAggregationGroupSum onField:@"Price"];
    [groupCommand addGroupFormulaFor:@"count" withOperator:CBDataAggregationGroupSum onValue:@1];
    
    [aggregateCond addObject:groupCommand];
    
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate.helper searchDocumentWithAggregates:aggregateCond inCollection:@"security_master_3" whenDone:^(CBHelperResponseInfo *response) {
        NSLog(@"received: %@", response.responseString);
    }];
    
}

- (IBAction)downloadFile:(id)sender {
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    // download the file id and display the image into a floating UIImageView
    [appDelegate.helper downloadFileData:self.fileIdField.text whenDone:^(NSData *fileContent) {
        UIImage *downloadedImg = [UIImage imageWithData:fileContent];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:downloadedImg];
        
        // TODO: The UIImageView should probably close itself once tapped.
        [self.view addSubview:imageView];
    }];
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
    
    // read the picked image into a CBHelperAttachment object
    UIImage* theImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    NSMutableArray* files = [[NSMutableArray alloc] init];
    
    CBHelperAttachment* att = [[CBHelperAttachment alloc] initForFile:@"firstimage.jpg" withData:UIImagePNGRepresentation(theImage)];
    
    [files addObject:att];
    
    TestDataObject* newObj = [self createTestObject];
    
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.helper)
    {
        // send the insert with the attachment
        [appDelegate.helper insertDocument:[appDelegate.helper objectToDictionaryOrArray:newObj] inCollection:@"test_users" withFiles:files whenDone:^(CBHelperResponseInfo *response) {
            NSLog(@"response data is %@", NSStringFromClass([response.responseData class]));
            self.outputLabel.text = (NSString*)[response.responseData lowercaseString];
        }];
    }
    
    [Picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

// hide the keyboard once editing of a test field is done.
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end

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

#import "FunctionsViewController.h"

@interface FunctionsViewController ()

@end

@implementation FunctionsViewController

@synthesize functionCodeField, payPalUrl;

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

-(IBAction)executeFunction:(id)sender {
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [appDelegate.helper executeCloudFunction:functionCodeField.text withParameters:NULL whenDone:^(CBHelperResponseInfo *response) {
        NSLog(@"received response: %@", [response.responseData JSONRepresentation]);
    }];
}
-(IBAction)executeApplet:(id)sender {
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:@"#bgee" forKey:@"search"];
    
    [appDelegate.helper executeApplet:@"cb_twitter_search" withParameters:dic whenDone:^(CBHelperResponseInfo *response) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitter output"
                                                        message:[response.responseData JSONRepresentation]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }];
}

-(IBAction)testPayPalPayment:(id)sender {
    CBPayPalBill *newBill = [[CBPayPalBill alloc] init];
    newBill.name = @"test bill";
    newBill.description = @"test bill for $9.99";
    newBill.currency = @"USD";
    newBill.invoiceNumber = @"test-invoice-01";
    newBill.paymentCompletedFunction = @"";
    newBill.paymentCancelledFunction = @"";

    CBPayPalBillItem *item = [[CBPayPalBillItem alloc] init];
    item.name = @"test item";
    item.description = @"test item for $9.99";
    item.amount = [NSNumber numberWithDouble:9.99];
    item.tax = [NSNumber numberWithDouble:0.00];
    item.quantity = [NSNumber numberWithInt:1];
    
    [newBill addNewItem:item];
    
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate.helper preparePayPalPurchase:newBill onLiveEnvironment:YES whenDone:^(CBHelperResponseInfo *response) {
        if (response.postSuccess && [response.responseData isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *tmpData = (NSDictionary *)response.responseData;
            if ([tmpData objectForKey:@"checkout_url"] != NULL)
            {
                self.payPalUrl = (NSString *)[tmpData objectForKey:@"checkout_url"];
            
                [self performSegueWithIdentifier:@"PayPalBrowserModalSegue" sender:self];
                tmpData = NULL;
            }
        }
    }];
}

// hide the keyboard once editing of a test field is done.
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PayPalBrowserModalSegue"]) {
        PayPalBrowserViewController *destViewController = segue.destinationViewController;
        destViewController.payPalUrl = self.payPalUrl;
    }
}

@end

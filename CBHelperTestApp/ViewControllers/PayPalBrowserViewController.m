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

#import "PayPalBrowserViewController.h"

@interface PayPalBrowserViewController ()

@end

@implementation PayPalBrowserViewController

@synthesize webView, payPalUrl;

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
    NSURL *url = [NSURL URLWithString:self.payPalUrl];
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    self.webView.delegate = self;
    //Load the request in the UIWebView.
    [self.webView loadRequest:requestObj];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeModal:(id)sender
{
    [self dismissViewControllerAnimated:true completion:^{
        return;
    }];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate.helper readPayPalResponse:request whenDone:^(CBHelperResponseInfo *response) {
        [self closeModal:NULL];
        NSDictionary *tmpData = (NSDictionary *)response.responseData;
        if ([tmpData objectForKey:@"status"] != NULL)
        {
            NSString* status = (NSString *)[tmpData objectForKey:@"status"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Payment completed"
                                                            message:[NSString stringWithFormat:@"status: %@", status]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}

@end

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

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize appCode, appSecret, appPwd, activityIndicator;

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
    
    Settings *sharedInstance = [Settings sharedInstance];
    
    if (sharedInstance.appCode) {
        self.appCode.text = sharedInstance.appCode;
        self.appSecret.text = sharedInstance.appSecret;
    }
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveSettings:(id)sender
{
    // get the singleton from the Settings object and save the values
    Settings *sharedInstance = [Settings sharedInstance];
    
    sharedInstance.appCode = self.appCode.text;
    sharedInstance.appSecret = self.appSecret.text;
    sharedInstance.appPwd = [CBHelper md5:self.appPwd.text];
    
    [Settings saveToFile];
    
    // initialise the shared CBHelper object
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    appDelegate.helper = [[CBHelper alloc] initForApp:sharedInstance.appCode withSecret:sharedInstance.appSecret];
    [appDelegate.helper setPassword:sharedInstance.appPwd];
}

// downloads an image from flickr into the phone media library. This is because the simulator is not allowed
// to use the camera and we need some pictures in the library to test the data APIs with attachments
- (IBAction)downloadImage:(id)sender
{
    [self.activityIndicator startAnimating];
    NSURL *url = [NSURL URLWithString:@"http://farm8.staticflickr.com/7166/6822341053_bc82750f7f_n.jpg"];
    
    NSData * imageData = [[NSData alloc] initWithContentsOfURL: url];
    
    UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:imageData], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL)
    {
        NSLog(@"error while saving image %@", error);
    }
    else
    {
        
    }
    [self.activityIndicator stopAnimating];
}

// hide the keyboard once editing of a test field is done.
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end

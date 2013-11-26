//
//  DetailInfosViewController.m
//  TestParse
//
//  Created by Adrien Dulong on 12/10/13.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "DetailInfosViewController.h"

@interface DetailInfosViewController ()
- (IBAction)logout:(id)sender;

@end

@implementation DetailInfosViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    // If not logged in, present login view controller
    if (![PFUser currentUser]) {
        [self performSegueWithIdentifier:@"FirstLaunch" sender:nil];
    }
    else{
        PFUser *currentUser = [PFUser currentUser];
        NSLog(@"%@",currentUser.username);
        
        self.nameLabel.text = currentUser[@"name"];
        self.birthdayLabel.text = currentUser[@"birthday"];
        self.emailLabel.text = currentUser.email;
        
        // Download the user's facebook profile picture
        self.imageData = [[NSMutableData alloc] init]; // the data will be loaded in here
        
        if ([[PFUser currentUser] objectForKey:@"pictureURL"]) {
            NSURL *pictureURL = [NSURL URLWithString:[[PFUser currentUser] objectForKey:@"pictureURL"]];
            
            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                      cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                  timeoutInterval:2.0f];
            // Run network request asynchronously
            NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
            if (!urlConnection) {
                NSLog(@"Failed to download picture");
            }
        }
        
    }
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

- (IBAction)logout:(id)sender {
    [PFUser logOut];
    [self performSegueWithIdentifier:@"FirstLaunch" sender:nil];
}

#pragma mark - NSURLConnectionDataDelegate

/* Callback delegate methods used for downloading the user's profile picture */

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // As chuncks of the image are received, we build our data file
    [self.imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // All data has been downloaded, now we can set the image in the header image view
    self.imageView.image = [UIImage imageWithData:self.imageData];
    
    // Add a nice corner radius to the image
    self.imageView.layer.cornerRadius = 50.0f;
    self.imageView.layer.masksToBounds = YES;
}


@end

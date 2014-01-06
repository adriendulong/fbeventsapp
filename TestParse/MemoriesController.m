//
//  MemoriesController.m
//  TestParseAgain
//
//  Created by Adrien Dulong on 05/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "MemoriesController.h"


@interface MemoriesController ()

@end

@implementation MemoriesController

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
    self.nbTotalEvents = 0;
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)getOldEvents:(id)sender {
    [self loadOldFacebookEvents:nil];
}

-(void)loadOldFacebookEvents:(NSString *)requestFacebook{
    int startTimeInterval = (int)[[NSDate date] timeIntervalSince1970];
    NSString *stopDate = [NSString stringWithFormat:@"%i", startTimeInterval];
    
    //Request
    if (requestFacebook==nil) {
        requestFacebook = [NSString stringWithFormat:@"/me/events?fields=owner.fields(id,name,picture),name,location,start_time,end_time,rsvp_status,cover,updated_time,description,is_date_only,admins.fields(id,name,picture)&until=%@", stopDate];
    }

    FBRequest *request = [FBRequest requestForGraphPath:requestFacebook];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            //NSLog(@"%@", result);
            
            for(id event in result[@"data"]){
                self.nbTotalEvents++;
            }
            
            if(result[@"paging"][@"next"]){
                NSURL *previous = [NSURL URLWithString:result[@"paging"][@"next"]];
                NSString *goodRequest = [NSString stringWithFormat:@"%@?%@", [previous path], [previous query]];
                [self loadOldFacebookEvents:goodRequest];
            }
            
            
        }
        else{
            NSLog(@"%@", error);
        }
    }];
    
}


@end

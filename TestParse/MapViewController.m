//
//  MapViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 25/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "MapViewController.h"
#import <GoogleMaps/GoogleMaps.h>

@interface MapViewController ()

@end

@implementation MapViewController

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
    
    CLLocationDegrees latitude;
    CLLocationDegrees longitude;
    float zoom;
    if (self.event[@"venue"][@"latitude"]) {
        latitude = [self.event[@"venue"][@"latitude"] doubleValue];
        longitude = [self.event[@"venue"][@"longitude"] doubleValue];
        zoom = 9;
    }
    else{
        latitude = 48;
        longitude = 2;
        zoom = 1;
        
    }
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:latitude
                                                            longitude:longitude
                                                                 zoom:zoom];
    GMSMapView *mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    
    if (self.event[@"location"] || self.event[@"venue"][@"name"]) {
        GMSMarker *marker = [[GMSMarker alloc] init];
        marker.position = CLLocationCoordinate2DMake(latitude, longitude);
        if (self.event[@"venue"][@"name"]) {
            marker.snippet = self.event[@"venue"][@"name"];
        }
        else{
            marker.snippet = self.event[@"location"];
        }
        marker.map = mapView;
    }
    
    
    self.view = mapView;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addTarget:self
               action:@selector(back:)
     forControlEvents:UIControlEventTouchDown];
    [button setTitle:NSLocalizedString(@"UIButton_Back", nil) forState:UIControlStateNormal];
    [button setTintColor:[UIColor orangeColor]];
    button.frame = CGRectMake(15.0, 20.0, 60.0, 40.0);
    [self.view addSubview:button];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)back:(id)sender{
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end

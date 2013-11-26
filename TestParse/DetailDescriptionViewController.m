//
//  DetailDescriptionViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 25/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "DetailDescriptionViewController.h"

@interface DetailDescriptionViewController ()

@end

@implementation DetailDescriptionViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"DESCRIPTION";
    self.descriptionTextView.text = self.description;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

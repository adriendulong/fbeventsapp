//
//  TestViewController.h
//  Woovent
//
//  Created by Jérémy on 04/02/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MOUtility.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface TestViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *postAndComments;

- (IBAction)sendMessageOnWall:(UIButton *)sender;

@end

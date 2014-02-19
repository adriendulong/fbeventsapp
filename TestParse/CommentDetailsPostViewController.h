//
//  CommentDetailsPostViewController.h
//  Woovent
//
//  Created by Jérémy on 18/02/2014.
//  Copyright (c) 2014 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface CommentDetailsPostViewController : UITableViewController

@property (nonatomic, strong) NSDictionary *postAndComments;
@property (nonatomic, strong) NSMutableDictionary *textViews;

@end

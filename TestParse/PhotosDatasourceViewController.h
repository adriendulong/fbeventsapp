//
//  WYPhotosDatasourceViewController.h
//  WYPopoverDemoSegue
//
//  Created by Jérémy on 03/02/2014.
//  Copyright (c) 2014 Nicolas CHENG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol PhotosDatasourceViewControllerDelegate;

@interface PhotosDatasourceViewController : UITableViewController

@property (nonatomic, weak) id <PhotosDatasourceViewControllerDelegate> delegate;

//@property (nonatomic) NSInteger selectedRow;
@property (nonatomic) NSString *selectedGroupPersistentID;
@property (nonatomic, strong) NSMutableArray *assetsGroupList;
@property (nonatomic, strong) NSString *datasourceName;

@end

@protocol PhotosDatasourceViewControllerDelegate <NSObject>

@optional

- (void)photosDatasourceViewControllerDidCancel:(PhotosDatasourceViewController *)controller;

- (void)photosDatasourceViewController:(PhotosDatasourceViewController *)controller
                 didSelectedDatasource:(NSString *)selectedDatasource
                     andDatasourceName:(NSString *)datasourceName;

@end

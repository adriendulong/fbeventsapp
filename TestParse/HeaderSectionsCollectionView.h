//
//  HeaderSectionsCollectionView.h
//  FbEvents
//
//  Created by Adrien Dulong on 22/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HeaderSectionsCollectionView : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UIImageView *imageLogo;
@property (weak, nonatomic) IBOutlet UILabel *dateEvent;
@property (weak, nonatomic) IBOutlet UILabel *eventName;
@property (weak, nonatomic) IBOutlet UIView *viewHeader;
@property (weak, nonatomic) IBOutlet UIButton *modifySelectionButton;
@property (assign, nonatomic) int position;


- (IBAction)modifySelection:(id)sender;
@end

//
//  MemoriesImportCell.h
//  FbEvents
//
//  Created by Adrien Dulong on 27/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MemoriesImportCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *placeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *peopleLabel;

@end

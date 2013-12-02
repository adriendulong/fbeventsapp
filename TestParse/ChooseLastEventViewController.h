//
//  ChooseLastEventViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 21/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChooseLastEventViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *placeLabel;
@property (weak, nonatomic) IBOutlet UILabel *invitedLabel;

@property (strong, nonatomic) PFObject *event;
@property (strong, nonatomic) NSArray *invited;
@property (assign, nonatomic) int selectedType;
@property (strong, nonatomic) NSArray *elementsForEvening;
@property (strong, nonatomic) NSArray *elementsForDay;
@property (strong, nonatomic) NSArray *elementsForWE;
@property (strong, nonatomic) NSArray *elementsForHolidays;

@property (strong, nonatomic) NSArray *pickerArray;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UIView *viewOne;
@property (weak, nonatomic) IBOutlet UIView *viewTwo;
@property (weak, nonatomic) IBOutlet UIView *viewThree;
@property (weak, nonatomic) IBOutlet UIView *viewFour;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *validateButton;

@property (assign, nonatomic) int levelRoot;

- (IBAction)validate:(id)sender;
- (IBAction)chosedType:(id)sender;
@end

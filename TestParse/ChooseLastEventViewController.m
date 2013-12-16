//
//  ChooseLastEventViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 21/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "ChooseLastEventViewController.h"
#import "PhotosImportedViewController.h"

@interface ChooseLastEventViewController ()

@end


#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@implementation ChooseLastEventViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (!IS_IPHONE_5) {
        self.verticalConstrainLeft.constant = 10.0;
        self.verticalConstraintRight.constant = 10.0;
    }
    
   
}

-(void)viewDidAppear:(BOOL)animated{
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(animateIfHasAType) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self initArraysPickers];
    
    //Title
    self.title = NSLocalizedString(@"ChooseLastEventViewController_Title", nil);
    
    //Init View
    NSDate *start_date = self.event[@"start_time"];
    NSDateFormatter *formatterMonth = [NSDateFormatter new];
    [formatterMonth setDateFormat:@"MMM"];
    NSDateFormatter *formatterDay = [NSDateFormatter new];
    [formatterDay setDateFormat:@"d"];
    self.titleLabel.text = self.event[@"name"];
    self.placeLabel.text = [NSString stringWithFormat:@"%@", self.event[@"location"]];
    self.monthLabel.text = [[NSString stringWithFormat:@"%@", [formatterMonth stringFromDate:start_date]] uppercaseString];
    self.dateLabel.text = [NSString stringWithFormat:@"%@", [formatterDay stringFromDate:start_date]];
    
    
    
    NSMutableString *listInvited = [[NSMutableString alloc] init];
    [listInvited appendFormat:@"%@ ", NSLocalizedString(@"ChooseLastEventViewController_with", nil)];
    //[listInvited appendString:@"avec "];
    for (int i=0; i<self.invited.count; i++) {
        if ([self.invited objectAtIndex:i][@"user"]) {
            [listInvited appendFormat:@"%@", [self.invited objectAtIndex:i][@"user"][@"name"]];
            break;
        }
        else if ([self.invited objectAtIndex:i][@"prospect"]) {
            [listInvited appendFormat:@"%@", [self.invited objectAtIndex:i][@"prospect"][@"name"]];
            break;
        }
    }
    
    if (self.invited.count > 1) {
        [listInvited appendFormat:@" %@ %i %@", NSLocalizedString(@"ChooseLastEventViewController_and", nil), (self.invited.count - 1), NSLocalizedString(@"ChooseLastEventViewController_more_friends", nil)];
    } /*else if (self.invited.count == 1) {
        [listInvited appendFormat:@" %@ %i %@", NSLocalizedString(@"ChooseLastEventViewController_and", nil), (self.invited.count - 1), NSLocalizedString(@"ChooseLastEventViewController_more_friend", nil)];
    }*/
    
    self.invitedLabel.text = listInvited;
    
    //Validate button not available
    [self.validateButton setEnabled:NO];
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)modifyType:(id)sender {
    [self.buttonModify setHidden:YES];
    [self.pickerView setHidden:YES];
    
    if (self.selectedType == 1) {

        [UIView animateWithDuration:0.5 animations:^{
            self.viewOne.center = self.centerSelected;
        } completion:^(BOOL finished) {[self.validateButton setEnabled:NO]; [self.viewFour setHidden:NO];[self.viewThree setHidden:NO];[self.viewTwo setHidden:NO];}];
    }
    else if (self.selectedType == 2) {
        
        [UIView animateWithDuration:0.5 animations:^{
            self.viewTwo.center = self.centerSelected;
        } completion:^(BOOL finished) {[self.validateButton setEnabled:NO];[self.viewOne setHidden:NO];[self.viewThree setHidden:NO];[self.viewFour setHidden:NO];}];
    }
    else if (self.selectedType == 3) {
        
        [UIView animateWithDuration:0.5 animations:^{
            self.viewThree.center = self.centerSelected;
        } completion:^(BOOL finished) {[self.validateButton setEnabled:NO];[self.viewTwo setHidden:NO];[self.viewOne setHidden:NO];[self.viewFour setHidden:NO];}];
    }
    else if (self.selectedType == 4) {
        [UIView animateWithDuration:0.5 animations:^{
            self.viewFour.center = self.centerSelected;
        } completion:^(BOOL finished) {[self.validateButton setEnabled:NO];[self.viewTwo setHidden:NO];[self.viewOne setHidden:NO];[self.viewThree setHidden:NO];}];
    }
}

- (IBAction)validate:(id)sender {
    NSInteger rowSelected = [self.pickerView selectedRowInComponent:0];
    
    if (self.selectedType == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ChooseLastEventViewController_Choice", nil) message:NSLocalizedString(@"ChooseLastEventViewController_Party", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ChooseLastEventViewController_OK", nil), nil];
        [alert show];
        
        
        self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
        self.event[@"last"] = [NSNumber numberWithInt:(int)[self.elementsForEvening objectAtIndex:rowSelected][@"last"]];
        
    }
    else if (self.selectedType == 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ChooseLastEventViewController_Choice", nil) message:NSLocalizedString(@"ChooseLastEventViewController_Journey", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ChooseLastEventViewController_OK", nil), nil];
        [alert show];
        
        self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
        self.event[@"last"] = [NSNumber numberWithInt:(int)[self.elementsForDay objectAtIndex:rowSelected][@"last"]];
        
    }
    else if (self.selectedType == 3) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ChooseLastEventViewController_Choice", nil) message:NSLocalizedString(@"ChooseLastEventViewController_Week-End", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ChooseLastEventViewController_OK", nil), nil];
        [alert show];
        
        self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
        self.event[@"last"] = [NSNumber numberWithInt:(int)[self.elementsForWE objectAtIndex:rowSelected][@"last"]];
    }
    else if (self.selectedType == 4) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ChooseLastEventViewController_Choice", nil) message:NSLocalizedString(@"ChooseLastEventViewController_Holiday", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ChooseLastEventViewController_OK", nil), nil];
        [alert show];
        
        self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
        self.event[@"last"] = [NSNumber numberWithInt:(int)[self.elementsForHolidays objectAtIndex:rowSelected][@"last"]];
    }
    
    [self.event saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"OK");
        }
        else{
            NSLog(@"%@", [error userInfo]);
        }
    }];


    
}

- (IBAction)chosedType:(id)sender {
    UIButton *clickedButton = (UIButton *)sender;
    NSLog(@"Clicked : %i", clickedButton.tag);
    
    if(!self.validateButton.isEnabled){
        if (clickedButton.tag == 1) {
            [self animateElement:1 placePicker:6 animationTime:0.7];
        }
        else if (clickedButton.tag == 2) {
            [self animateElement:2 placePicker:6 animationTime:0.7];
        }
        else if (clickedButton.tag == 3) {
            
            [self animateElement:3 placePicker:2 animationTime:1.0];
        }
        else if (clickedButton.tag == 4) {
            
            [self animateElement:4 placePicker:4 animationTime:1.0];
        }
    }
    

    
}


# pragma mark - picker functions

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.pickerArray count];
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.pickerArray objectAtIndex:row][@"label"];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if (self.selectedType==1) {
        UILabel *label = (UILabel *)[self.viewOne viewWithTag:1000];
        label.text = [self.elementsForEvening objectAtIndex:row][@"label"];
    }
    else if (self.selectedType==2) {
        UILabel *label = (UILabel *)[self.viewTwo viewWithTag:1000];
        label.text = [self.elementsForDay objectAtIndex:row][@"label"];
    }
    else if (self.selectedType==3) {
        UILabel *label = (UILabel *)[self.viewThree viewWithTag:1000];
        label.text = [self.elementsForWE objectAtIndex:row][@"label"];
    }
    else if (self.selectedType==4) {
        UILabel *label = (UILabel *)[self.viewThree viewWithTag:1000];
        label.text = [self.elementsForHolidays objectAtIndex:row][@"label"];
    }
}

-(void)initArraysPickers{
    NSDictionary *oneHour = @{@"label": [NSString stringWithFormat:@"1 %@", NSLocalizedString(@"ChooseLastEventViewController_Hour", nil)],
                              @"last": @1};
    NSDictionary *twoHour = @{@"label": [NSString stringWithFormat:@"2 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                              @"last": @2};
    NSDictionary *threeHour = @{@"label": [NSString stringWithFormat:@"3 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                              @"last": @3};
    NSDictionary *fourHour = @{@"label": [NSString stringWithFormat:@"4 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                              @"last": @4};
    NSDictionary *fiveHour = @{@"label": [NSString stringWithFormat:@"5 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                              @"last": @5};
    NSDictionary *sixHours = @{@"label": [NSString stringWithFormat:@"6 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                               @"last": @6};
    NSDictionary *sevenHour = @{@"label": [NSString stringWithFormat:@"7 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                              @"last": @7};
    NSDictionary *heightHour = @{@"label": [NSString stringWithFormat:@"8 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                              @"last": @8};
    NSDictionary *nineHour = @{@"label": [NSString stringWithFormat:@"9 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                              @"last": @9};
    NSDictionary *tenHour = @{@"label": [NSString stringWithFormat:@"10 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                              @"last": @10};
    NSDictionary *elevenHour = @{@"label": [NSString stringWithFormat:@"11 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                              @"last": @11};
    NSDictionary *twelveHour = @{@"label": [NSString stringWithFormat:@"12 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                              @"last": @12};
    NSDictionary *fourteenHour = @{@"label": [NSString stringWithFormat:@"14 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                                 @"last": @14};
    NSDictionary *sixteenHour = @{@"label": [NSString stringWithFormat:@"16 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                                 @"last": @16};
    NSDictionary *heighteenHour = @{@"label": [NSString stringWithFormat:@"18 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                                 @"last": @18};
    NSDictionary *twentyHour = @{@"label": [NSString stringWithFormat:@"20 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                                 @"last": @20};
    NSDictionary *twentyTwoHour = @{@"label": [NSString stringWithFormat:@"22 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                                 @"last": @22};
    NSDictionary *twentyFourHour = @{@"label": [NSString stringWithFormat:@"24 %@", NSLocalizedString(@"ChooseLastEventViewController_Hours", nil)],
                                 @"last": @24};
    NSDictionary *oneDay = @{@"label": [NSString stringWithFormat:@"1 %@", NSLocalizedString(@"ChooseLastEventViewController_Day", nil)],
                                     @"last": @24};
    NSDictionary *twoDays = @{@"label": [NSString stringWithFormat:@"2 %@", NSLocalizedString(@"ChooseLastEventViewController_Days", nil)],
                                     @"last": @48};
    NSDictionary *threeDays = @{@"label": [NSString stringWithFormat:@"3 %@", NSLocalizedString(@"ChooseLastEventViewController_Days", nil)],
                                     @"last": @72};
    NSDictionary *fourDays = @{@"label": [NSString stringWithFormat:@"4 %@", NSLocalizedString(@"ChooseLastEventViewController_Days", nil)],
                                @"last": @96};
    NSDictionary *fiveDays = @{@"label": [NSString stringWithFormat:@"5 %@", NSLocalizedString(@"ChooseLastEventViewController_Days", nil)],
                                @"last": @120};
    NSDictionary *sixDays = @{@"label": [NSString stringWithFormat:@"6 %@", NSLocalizedString(@"ChooseLastEventViewController_Days", nil)],
                               @"last": @144};
    NSDictionary *sevenDays = @{@"label": [NSString stringWithFormat:@"7 %@", NSLocalizedString(@"ChooseLastEventViewController_Days", nil)],
                               @"last": @168};
    NSDictionary *oneWeek = @{@"label": [NSString stringWithFormat:@"1 %@", NSLocalizedString(@"ChooseLastEventViewController_Week", nil)],
                                @"last": @168};
    NSDictionary *twoWeeks = @{@"label": [NSString stringWithFormat:@"2 %@", NSLocalizedString(@"ChooseLastEventViewController_Weeks", nil)],
                              @"last": @336};
    NSDictionary *threeWeeks = @{@"label": [NSString stringWithFormat:@"3 %@", NSLocalizedString(@"ChooseLastEventViewController_Weeks", nil)],
                              @"last": @504};
    NSDictionary *fourWeeks = @{@"label": [NSString stringWithFormat:@"4 %@", NSLocalizedString(@"ChooseLastEventViewController_Weeks", nil)],
                              @"last": @672};
    NSDictionary *oneMonth = @{@"label": [NSString stringWithFormat:@"1 %@", NSLocalizedString(@"ChooseLastEventViewController_Month", nil)],
                                @"last": @720};
    NSDictionary *twoMonths = @{@"label": [NSString stringWithFormat:@"2 %@", NSLocalizedString(@"ChooseLastEventViewController_Months", nil)],
                                @"last": @1440};
    NSDictionary *threeMonths = @{@"label": [NSString stringWithFormat:@"3 %@", NSLocalizedString(@"ChooseLastEventViewController_Months", nil)],
                                @"last": @2160};
    
    
    self.elementsForEvening = [NSArray arrayWithObjects:oneHour, twoHour, threeHour, fourHour, fiveHour, sixHours, sevenHour, heightHour, nineHour, tenHour, nil];
    self.elementsForDay = [NSArray arrayWithObjects:heightHour, nineHour, tenHour, elevenHour, twelveHour, fourteenHour, sixteenHour, heighteenHour, twentyHour, twentyTwoHour, twentyFourHour, nil];
    self.elementsForWE = [NSArray arrayWithObjects:oneDay, twoDays, threeDays, fourDays, fiveDays, nil];
    self.elementsForHolidays = [NSArray arrayWithObjects:fourDays, fiveDays, sixDays, sevenDays, oneWeek, twoWeeks, threeWeeks, fourWeeks, oneMonth, twoMonths, threeMonths, nil];
    
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"ImportImages"]) {
         NSInteger rowSelected = [self.pickerView selectedRowInComponent:0];

        if (self.selectedType == 1) {
            
            self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
            self.event[@"last"] = [self.elementsForEvening objectAtIndex:rowSelected][@"last"];
            NSLog(@"LAST %@", [self.elementsForEvening objectAtIndex:rowSelected][@"last"]);
            
        }
        else if (self.selectedType == 2) {
            
            self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
            self.event[@"last"] = [self.elementsForDay objectAtIndex:rowSelected][@"last"];
            
        }
        else if (self.selectedType == 3) {
            
            self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
            self.event[@"last"] = [self.elementsForWE objectAtIndex:rowSelected][@"last"];
        }
        else if (self.selectedType == 4) {
            
            self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
            self.event[@"last"] = [self.elementsForHolidays objectAtIndex:rowSelected][@"last"];
        }
        
        
        
        //Save
        [self.event saveInBackground];
        
        
        PhotosImportedViewController *photoCollectionController = (PhotosImportedViewController *)segue.destinationViewController;
        photoCollectionController.event = self.event;
        photoCollectionController.levelRoot = self.levelRoot;
    }
    
}

-(void)animateIfHasAType{
    if (self.event[@"type"]) {
        if ([(NSNumber *)self.event[@"type"] intValue] == 1) {
            UIButton *button = (UIButton *)[self.viewOne viewWithTag:1];
            [button sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
        else if ([(NSNumber *)self.event[@"type"] intValue] == 2) {
            UIButton *button = (UIButton *)[self.viewTwo viewWithTag:2];
            [button sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
        else if ([(NSNumber *)self.event[@"type"] intValue] == 3) {
            UIButton *button = (UIButton *)[self.viewThree viewWithTag:3];
            [button sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
        else if ([(NSNumber *)self.event[@"type"] intValue] == 4) {
            UIButton *button = (UIButton *)[self.viewFour viewWithTag:4];
            [button sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }
}

-(void)animateElement:(int)position placePicker:(int)place animationTime:(NSTimeInterval)duration{
    
    if (position == 1) {
        self.pickerArray = self.elementsForEvening;
        [self.pickerView reloadAllComponents];
        
        [self.pickerView selectRow:[self positionInArrayForHours:1] inComponent:0 animated:YES];
        
        
        [self.viewTwo setHidden:YES];
        [self.viewThree setHidden:YES];
        [self.viewFour setHidden:YES];
        
        self.selectedType = 1;
        self.centerSelected = self.viewOne.center;
        
        [UIView animateWithDuration:duration animations:^{
            self.viewOne.center = CGPointMake(160, 280);
        } completion:^(BOOL finished) {[self.pickerView setHidden:NO]; [self.validateButton setEnabled:YES]; [self.buttonModify setHidden:NO];}];
    }
    else if (position == 2) {
        self.pickerArray = self.elementsForDay;
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:[self positionInArrayForHours:2] inComponent:0 animated:NO];
        
        [self.viewOne setHidden:YES];
        [self.viewThree setHidden:YES];
        [self.viewFour setHidden:YES];
        
        self.selectedType = 2;
        self.centerSelected = self.viewTwo.center;
        
        [UIView animateWithDuration:duration animations:^{
            self.viewTwo.center = CGPointMake(160, 280);
        } completion:^(BOOL finished) {[self.pickerView setHidden:NO]; [self.validateButton setEnabled:YES]; [self.buttonModify setHidden:NO];}];
    }
    else if (position == 3) {
        self.pickerArray = self.elementsForWE;
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:[self positionInArrayForHours:3] inComponent:0 animated:NO];
        
        [self.viewTwo setHidden:YES];
        [self.viewOne setHidden:YES];
        [self.viewFour setHidden:YES];
        
        self.selectedType = 3;
        self.centerSelected = self.viewThree.center;
        
        
        [UIView animateWithDuration:duration animations:^{
            self.viewThree.center = CGPointMake(160, 280);
        } completion:^(BOOL finished) {[self.pickerView setHidden:NO]; [self.validateButton setEnabled:YES]; [self.buttonModify setHidden:NO];}];
    }
    else if (position == 4) {
        self.pickerArray = self.elementsForHolidays;
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:[self positionInArrayForHours:4] inComponent:0 animated:NO];
        
        [self.viewTwo setHidden:YES];
        [self.viewOne setHidden:YES];
        [self.viewThree setHidden:YES];
        
        self.selectedType = 4;
        self.centerSelected = self.viewFour.center;
        
        [UIView animateWithDuration:duration animations:^{
            self.viewFour.center = CGPointMake(160, 280);
        } completion:^(BOOL finished) {[self.pickerView setHidden:NO]; [self.validateButton setEnabled:YES]; [self.buttonModify setHidden:NO];}];
    }
}


-(int)positionInArrayForHours:(int)type{
    int position = 4;
    
    if (type==1) {
        for (int i=0; i<self.elementsForEvening.count; i++) {
            if ([[self.elementsForEvening objectAtIndex:i][@"last"] intValue] == [self.event[@"last"] intValue]) {
                position = i;
                return position;
            }
        }
    }
    else if(type == 2){
        for (int i=0; i<self.elementsForDay.count; i++) {
            if ([[self.elementsForDay objectAtIndex:i][@"last"] intValue] == [self.event[@"last"] intValue]) {
                position = i;
                return position;
            }
        }
    }
    else if(type == 3){
        for (int i=0; i<self.elementsForWE.count; i++) {
            if ([[self.elementsForWE objectAtIndex:i][@"last"] intValue] == [self.event[@"last"] intValue]) {
                position = i;
                return position;
            }
        }
    }
    else if(type == 4){
        for (int i=0; i<self.elementsForHolidays.count; i++) {
            if ([[self.elementsForHolidays objectAtIndex:i][@"last"] intValue] == [self.event[@"last"] intValue]) {
                position = i;
                return position;
            }
        }
    }
    
    return position;
}

@end

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
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.7 target:self selector:@selector(animateIfHasAType) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self initArraysPickers];
    
    //Title
    self.title = @"Durée de l'évènement";
    
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
    [listInvited appendString:@"avec "];
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
        [listInvited appendFormat:@" et %i autres amis", (self.invited.count - 1)];
    }
    
    self.invitedLabel.text = listInvited;
    
    //Picker Array
    //@self.pickerArray = [NSArray arrayWithObjects:@"Bordeaux", @"Paris", @"New York", @"Shangai", @"San Francisco", nil];
    
    //Validate button not available
    [self.validateButton setEnabled:NO];
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)validate:(id)sender {
    NSInteger rowSelected = [self.pickerView selectedRowInComponent:0];
    
    if (self.selectedType == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choix" message:@"Soirée" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
        [alert show];
        
        
        self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
        self.event[@"last"] = [NSNumber numberWithInt:(int)[self.elementsForEvening objectAtIndex:rowSelected][@"last"]];
        
    }
    else if (self.selectedType == 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choix" message:@"Journée" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
        [alert show];
        
        self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
        self.event[@"last"] = [NSNumber numberWithInt:(int)[self.elementsForDay objectAtIndex:rowSelected][@"last"]];
        
    }
    else if (self.selectedType == 3) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choix" message:@"Week-End" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
        [alert show];
        
        self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
        self.event[@"last"] = [NSNumber numberWithInt:(int)[self.elementsForWE objectAtIndex:rowSelected][@"last"]];
    }
    else if (self.selectedType == 4) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choix" message:@"Vacances !" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
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
    NSDictionary *oneHour = @{@"label": @"1 Heure",
                              @"last": @1};
    NSDictionary *twoHour = @{@"label": @"2 Heure",
                              @"last": @2};
    NSDictionary *threeHour = @{@"label": @"3 Heure",
                              @"last": @3};
    NSDictionary *fourHour = @{@"label": @"4 Heure",
                              @"last": @4};
    NSDictionary *fiveHour = @{@"label": @"5 Heure",
                              @"last": @5};
    NSDictionary *sixHours = @{@"label": @"6 Heure",
                               @"last": @6};
    NSDictionary *sevenHour = @{@"label": @"7 Heure",
                              @"last": @7};
    NSDictionary *heightHour = @{@"label": @"8 Heure",
                              @"last": @8};
    NSDictionary *nineHour = @{@"label": @"9 Heure",
                              @"last": @9};
    NSDictionary *tenHour = @{@"label": @"10 Heure",
                              @"last": @10};
    NSDictionary *elevenHour = @{@"label": @"11 Heure",
                              @"last": @11};
    NSDictionary *twelveHour = @{@"label": @"12 Heure",
                              @"last": @12};
    NSDictionary *fourteenHour = @{@"label": @"14 Heure",
                                 @"last": @14};
    NSDictionary *sixteenHour = @{@"label": @"16 Heure",
                                 @"last": @16};
    NSDictionary *heighteenHour = @{@"label": @"18 Heure",
                                 @"last": @18};
    NSDictionary *twentyHour = @{@"label": @"20 Heure",
                                 @"last": @20};
    NSDictionary *twentyTwoHour = @{@"label": @"22 Heure",
                                 @"last": @22};
    NSDictionary *twentyFourHour = @{@"label": @"24 Heure",
                                 @"last": @24};
    NSDictionary *oneDay = @{@"label": @"1 Jour",
                                     @"last": @24};
    NSDictionary *twoDays = @{@"label": @"2 Jours",
                                     @"last": @48};
    NSDictionary *threeDays = @{@"label": @"3 Jours",
                                     @"last": @72};
    NSDictionary *fourDays = @{@"label": @"4 Jours",
                                @"last": @96};
    NSDictionary *fiveDays = @{@"label": @"5 Jours",
                                @"last": @120};
    NSDictionary *sixDays = @{@"label": @"6 Jours",
                               @"last": @144};
    NSDictionary *sevenDays = @{@"label": @"7 Jours",
                               @"last": @168};
    NSDictionary *oneWeek = @{@"label": @"1 Semaine",
                                @"last": @168};
    NSDictionary *twoWeeks = @{@"label": @"2 Semaines",
                              @"last": @336};
    NSDictionary *threeWeeks = @{@"label": @"3 Semaines",
                              @"last": @504};
    NSDictionary *fourWeeks = @{@"label": @"4 Semaines",
                              @"last": @672};
    NSDictionary *oneMonth = @{@"label": @"1 Mois",
                                @"last": @720};
    NSDictionary *twoMonths = @{@"label": @"2 Mois",
                                @"last": @1440};
    NSDictionary *threeMonths = @{@"label": @"3 Mois",
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choix" message:@"Soirée" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
            [alert show];
            
            
            self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
            self.event[@"last"] = [self.elementsForEvening objectAtIndex:rowSelected][@"last"];
            NSLog(@"LAST %@", [self.elementsForEvening objectAtIndex:rowSelected][@"last"]);
            
        }
        else if (self.selectedType == 2) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choix" message:@"Journée" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
            [alert show];
            
            self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
            self.event[@"last"] = [self.elementsForDay objectAtIndex:rowSelected][@"last"];
            
        }
        else if (self.selectedType == 3) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choix" message:@"Week-End" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
            [alert show];
            
            self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
            self.event[@"last"] = [self.elementsForWE objectAtIndex:rowSelected][@"last"];
        }
        else if (self.selectedType == 4) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choix" message:@"Vacances !" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
            [alert show];
            
            self.event[@"type"] = [NSNumber numberWithInt:self.selectedType];
            self.event[@"last"] = [self.elementsForHolidays objectAtIndex:rowSelected][@"last"];
        }
        
        
        
        //Save
        [self.event saveInBackground];
        
        
        PhotosImportedViewController *photoCollectionController = (PhotosImportedViewController *)segue.destinationViewController;
        photoCollectionController.event = self.event;
    }
    
}

-(void)animateIfHasAType{
    if (self.event[@"type"]) {
        if ([(NSNumber *)self.event[@"type"] intValue] == 1) {
            UIButton *button = (UIButton *)[self.viewOne viewWithTag:1];
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
        
        [UIView animateWithDuration:duration animations:^{
            self.viewOne.center = CGPointMake(160, 280);
        } completion:^(BOOL finished) {[self.pickerView setHidden:NO]; [self.validateButton setEnabled:YES];}];
    }
    else if (position == 2) {
        self.pickerArray = self.elementsForDay;
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:[self positionInArrayForHours:2] inComponent:0 animated:NO];
        
        [self.viewOne setHidden:YES];
        [self.viewThree setHidden:YES];
        [self.viewFour setHidden:YES];
        
        self.selectedType = 2;
        
        [UIView animateWithDuration:duration animations:^{
            self.viewTwo.center = CGPointMake(160, 280);
        } completion:^(BOOL finished) {[self.pickerView setHidden:NO]; [self.validateButton setEnabled:YES];}];
    }
    else if (position == 3) {
        self.pickerArray = self.elementsForWE;
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:[self positionInArrayForHours:3] inComponent:0 animated:NO];
        
        [self.viewTwo setHidden:YES];
        [self.viewOne setHidden:YES];
        [self.viewFour setHidden:YES];
        
        self.selectedType = 3;
        
        
        [UIView animateWithDuration:duration animations:^{
            self.viewThree.center = CGPointMake(160, 280);
        } completion:^(BOOL finished) {[self.pickerView setHidden:NO]; [self.validateButton setEnabled:YES]; }];
    }
    else if (position == 4) {
        self.pickerArray = self.elementsForHolidays;
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:[self positionInArrayForHours:4] inComponent:0 animated:NO];
        
        [self.viewTwo setHidden:YES];
        [self.viewOne setHidden:YES];
        [self.viewThree setHidden:YES];
        
        self.selectedType = 4;
        
        [UIView animateWithDuration:duration animations:^{
            self.viewFour.center = CGPointMake(160, 280);
        } completion:^(BOOL finished) {[self.pickerView setHidden:NO]; [self.validateButton setEnabled:YES];}];
    }
}


-(int)positionInArrayForHours:(int)type{
    int position = 4;
    
    if (type==1) {
        for (int i=0; i<self.elementsForEvening.count; i++) {
            int lastElement = (int)[self.elementsForEvening objectAtIndex:i][@"last"];
            if ([self.elementsForEvening objectAtIndex:i][@"last"] == self.event[@"last"]) {
                position = i;
                return position;
            }
        }
    }
    else if(type == 2){
        for (int i=0; i<self.elementsForDay.count; i++) {
            if ((int)[self.elementsForDay objectAtIndex:i][@"last"] == [(NSNumber *)self.event[@"last"] intValue]) {
                position = i;
                return position;
            }
        }
    }
    else if(type == 3){
        for (int i=0; i<self.elementsForWE.count; i++) {
            if ((int)[self.elementsForWE objectAtIndex:i][@"last"] == [(NSNumber *)self.event[@"last"] intValue]) {
                position = i;
                return position;
            }
        }
    }
    else if(type == 4){
        for (int i=0; i<self.elementsForHolidays.count; i++) {
            if ((int)[self.elementsForHolidays objectAtIndex:i][@"last"] == [(NSNumber *)self.event[@"last"] intValue]) {
                position = i;
                return position;
            }
        }
    }
    
    return position;
}

@end

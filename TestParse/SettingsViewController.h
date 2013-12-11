//
//  SettingsViewController.h
//  FbEvents
//
//  Created by Adrien Dulong on 11/12/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SettingsViewController : UITableViewController <MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *switchNotifTel;
@property (weak, nonatomic) IBOutlet UISwitch *swithNotifMail;
@property (assign, nonatomic) BOOL mustDismiss;


- (IBAction)finish:(id)sender;
- (IBAction)changeNotifTel:(id)sender;
- (IBAction)changeNotifMail:(id)sender;
@end

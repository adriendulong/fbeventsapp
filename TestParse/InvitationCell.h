//
//  InvitationCell.h
//  TestParseAgain
//
//  Created by Adrien Dulong on 31/10/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>


@interface InvitationCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelTest;
@property (weak, nonatomic) IBOutlet UIImageView *profilImageView;
@property (weak, nonatomic) IBOutlet UILabel *ownerInvitationLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *whenWhereLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *rsvpSegmentedControl;
@property(strong, nonatomic) PFObject *invitation;


- (IBAction)rsvpChanged:(id)sender;

@end

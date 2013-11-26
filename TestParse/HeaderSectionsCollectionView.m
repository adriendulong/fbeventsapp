//
//  HeaderSectionsCollectionView.m
//  FbEvents
//
//  Created by Adrien Dulong on 22/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "HeaderSectionsCollectionView.h"

@implementation HeaderSectionsCollectionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (IBAction)modifySelection:(id)sender {
    NSDictionary *userInfo = [[NSDictionary alloc] init];
    
    if (self.modifySelectionButton.isSelected) {
        //[self.modifySelectionButton setSelected:NO];
        userInfo = [NSDictionary dictionaryWithObject:@"0" forKey:@"new_state"];
    }
    else{
        //[self.modifySelectionButton setSelected:YES];
        userInfo = [NSDictionary dictionaryWithObject:@"1" forKey:@"new_state"];
    }
    
    if (self.position ==0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SelectAllPhotosPhone object:self userInfo:userInfo];
    }
    else{
        [[NSNotificationCenter defaultCenter] postNotificationName:SelectAllPhotosFacebook object:self userInfo:userInfo];
    }
}
@end

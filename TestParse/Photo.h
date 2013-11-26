//
//  Photo.h
//  FbEvents
//
//  Created by Adrien Dulong on 22/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Photo : NSObject

@property (nonatomic, strong) UIImage *thumbnail;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSURL *assetUrl;
@property (nonatomic) BOOL isSelected;

@property (strong, nonatomic) NSString *sourceUrl;
@property (strong, nonatomic) NSString *pictureUrl;
@property (strong, nonatomic) NSString *facebookId;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSString *userFBName;

@property (strong, nonatomic) PFUser *ownerPhoto;

@property (assign, nonatomic) float width;
@property (assign, nonatomic) float height;



@end

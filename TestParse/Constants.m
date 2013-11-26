//
//  Constants.m
//  TestParseAgain
//
//  Created by Adrien Dulong on 13/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "Constants.h"


#pragma mark - NSNotification
NSString *const ShowOrHideDetailsEventNotification  = @"com.moment.FbEvents.ShowOrHideDetailEvent";
NSString *const AddPhotoToEventNotification         = @"com.moment.FbEvents.AddPhotoToEvent";
NSString *const UpdateInvitedFinished               = @"com.moment.FbEvents.UpdateInvitedFinished";
NSString *const UploadPhotoFinished                 = @"com.moment.FbEvents.UploadPhotoHaveFinished";
NSString *const ClickLikePhoto                      = @"com.moment.FbEvents.UserClickedLike";
NSString *const MorePhoto                           = @"com.moment.FbEvents.MorePhoto";
NSString *const SelectAllPhotosPhone                = @"com.moment.FbEvents.SelectAllPhotosPhone";
NSString *const SelectAllPhotosFacebook             = @"com.moment.FbEvents.SelectAllPhotosFacebook";

#pragma mark - Facebook

NSString *const FacebookEventAttending           = @"attending";
NSString *const FacebookEventMaybe               = @"unsure";
NSString *const FacebookEventDeclined            = @"declined";
NSString *const FacebookEventNotReplied          = @"not_replied";


#pragma mark - Colors

NSString *const FacebookFirstBlue                = @"3b5998";
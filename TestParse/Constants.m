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
NSString *const ModifEventsInvitationsAnswers       = @"com.moment.FbEvents.ModifEventsInvitationsAnswers";
NSString *const HaveFinishedRefreshEvents           = @"com.moment.FbEvents.HaveFinishedRefreshEvents";
NSString *const fakeAnswerEvents                    = @"com.moment.FbEvents.fakeAnswerEvents";
NSString *const LogOutUser                          = @"com.moment.FbEvents.LogOutUser";
NSString *const LogInUser                           = @"com.moment.FbEvents.LogInUser";
NSString *const UpdateClosestEvent                  = @"com.moment.FbEvents.UpdateClosestEvent";
NSString *const InvitedDetailFinished               = @"com.moment.FbEvents.InvitedDetailFinished";

#pragma mark - Facebook

NSString *const FacebookEventAttending           = @"attending";
NSString *const FacebookEventMaybe               = @"unsure";
NSString *const FacebookEventMaybeAnswer         = @"maybe";
NSString *const FacebookEventDeclined            = @"declined";
NSString *const FacebookEventNotReplied          = @"not_replied";

NSString *const FacebookSmallProfileImage          = @"small";
NSString *const FacebookNormalProfileImage         = @"normal";
NSString *const FacebookLargeProfileImage          = @"large";
NSString *const FacebookSquareProfileImage         = @"square";


NSString *const FacebookEventsFields             = @"owner.fields(id,name,picture),name,location,start_time,end_time,rsvp_status,cover,updated_time,description,is_date_only,admins.fields(id,name,picture),venue";


#pragma mark - Colors

NSString *const FacebookFirstBlue                = @"3b5998";


#pragma mark - App Constants
int const DefaultNbHoursEvent                    = 24;

#pragma mark - Notif Type
int const NewPhotosEvent                         = 0;
int const NewLikePhoto                           = 1;

#pragma mark - Fetch Interval
NSTimeInterval const TimeIntervalFetch           = 7200;

#pragma mark - External Lib Constants
extern NSString *const MixpanelToken             = @"0ccc812dd7bb0ed7cf52a7225558803e";
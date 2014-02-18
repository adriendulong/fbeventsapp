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
NSString *const NewCommentAdded                     = @"com.moment.FbEvents.NewCommentAdded";

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
NSTimeInterval const TimeIntervalFetch           = 1800;

#pragma mark - External Lib Constants
NSString *const MixpanelToken             = @"0ccc812dd7bb0ed7cf52a7225558803e";

#pragma mark - API Keys DEV
NSString *const KeenProjectIdDev             = @"52ef60c6ce5e435bb3000002";
NSString *const KeenWriteKeyDev              = @"9747b7d96d59d3b6840e96ac55e08699f633f027a855b54b83ae6b07914a546c921d4f721a1a5f9b0b1be9f79f1cedb2f4b14f673f9cb2f9248d6f67fbb1f6cb0f6c32f4a849e062adbac65fe090fad68f6b9e9ad46c2e19b6c39c1727ddc8640e45722a932140559b325967c65e1d69";
NSString *const KeenReadKeyDev               = @"bf8e443b2c38af0a8ac68ad3e47f315cdfcfc7ba572f0248b3ed93f6052e4569dc9d9bab46cf5b980a6b74022958ab75cad28cb1b7fee51b739968479a62af8772353595168165d4eb636bb4df525a0977f06b0523c51553b92d8480456f7d0d00c1ac96d1edde8ab2c5665d4b10dbbe";
NSString *const ParseApplicationIDDev        = @"FtBRQLsJwozj3G32heaXVfCYALQbAmmJZnnopsrP";
NSString *const ParseClientKeyDev            = @"C2jEPO7tVj5qZC1rk1YvvDqpjJAIhgbB9YKaGVhm";

#pragma mark - API Keys PROD
NSString *const KeenProjectIdProd             = @"52efb3b9d97b852cb6000000";
NSString *const KeenWriteKeyProd              = @"2a5713b6923efdf0227f12e0869f6d882abcc7df5c2bab14df4d957e43965ccb98e237f652854592138ea877f80dc25ce575dcf88aa598b0d74c968307a40cd02561c815fd8e54325ab3ca735d1becae190ddb0aa70ef532efc296581d29322b5a6e124c89ff493fbc30ed725e29e277";
NSString *const KeenReadKeyProd               = @"0b8aa0b86ab69e1bad0042f9bb29f4ab895152d31e93902015831486ab44f9cf84cb9979a6382a2e84fa5fef9e9ee331145c5c07a8444f89af9982838a862a94f010e6c069eedf75b59783ad79328f32c5afe2101c5658fd70e16833c608114fe0814c26094c43e28b27e4fbe545f22b";
NSString *const ParseApplicationIDProd        = @"8UT7kL1fmD9Orti3P7obNJyTgSpJpEGvz4HkCrr8";
NSString *const ParseClientKeyProd            = @"dT15cWACdZqlNCu0UIb1goDN6KXmTjs9yolq9CVB";
NSString *const FacebookAppId                 = @"493616390746321";
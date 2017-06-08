//
//  KTVDuetVideoMixer.h
//  DuetVideoPlayback
//
//  Created by Ke on 5/12/15.
//  Copyright (c) 2015 Changba. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVDuetVideoMixer : NSObject
/**
 *  合成导出视频合唱的视频
 *
 *  @param segments  视频合唱动画分段数据
 *  @param firstURL  发起者视频
 *  @param secondURL 参与者视频
 *  @param outputURL 输出路径
 *
 *  @return
 */
- (instancetype)initWithAnimationSegments:(NSArray *)segments firstURL:(NSURL *)firstURL secondURL:(NSURL *)secondURL outputURL:(NSURL *)outputURL;
- (void)exportWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure progress:(void (^)(float progress))progress interuption:(void (^)(void))interuption;
@end

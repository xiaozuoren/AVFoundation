//
//  KTVDuetVideoMixer.m
//  DuetVideoPlayback
//
//  Created by Ke on 5/12/15.
//  Copyright (c) 2015 Changba. All rights reserved.
//

#import "KTVDuetVideoMixer.h"
#import "KTVDuetVideoAnimationSegment.h"
#import "KTVDuetVideoConstant.h"
#import "StatsServer.h"
@import AVFoundation;

@interface KTVDuetVideoMixer()
@property (nonatomic, strong) NSArray *segments;
@property (nonatomic, strong) NSURL *firstURL;
@property (nonatomic, strong) NSURL *secondURL;
@property (nonatomic, strong) NSURL *outputURL;
@property (nonatomic, copy) void (^success)(void);
@property (nonatomic, copy) void (^failure)(NSError *error);
@property (nonatomic, copy) void (^progress)(float progress);
@property (nonatomic, copy) void (^interuption)(void);
@property (nonatomic, strong) AVMutableCompositionTrack *track1;
@property (nonatomic, strong) AVMutableCompositionTrack *track2;
@property (nonatomic, strong) AVAssetExportSession *session;
@property (nonatomic, weak) NSTimer *timer;
@end

@implementation KTVDuetVideoMixer
- (instancetype)initWithAnimationSegments:(NSArray *)segments
                                 firstURL:(NSURL *)firstURL
                                secondURL:(NSURL *)secondURL
                                outputURL:(NSURL *)outputURL {
    self = [super init];
    if (self) {
        _segments = segments;
        _firstURL = firstURL;
        _secondURL = secondURL;
        _outputURL = outputURL;
        
    }
    return self;
}

- (void)exportWithSuccess:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure
                 progress:(void (^)(float progress))progress
              interuption:(void (^)(void))interuption {
    self.success = success;
    self.failure = failure;
    self.progress = progress;
    self.interuption = interuption;

    NSError *error = nil;
    AVMutableComposition *composition = [AVMutableComposition new];
    AVURLAsset *asset1 = [AVURLAsset URLAssetWithURL:self.firstURL options:nil];
    AVURLAsset *asset2 = [AVURLAsset URLAssetWithURL:self.secondURL options:nil];
    NSTimeInterval minDuration = MIN(asset1.duration.value * 1.0f / asset1.duration.timescale, asset2.duration.value * 1.0f / asset2.duration.timescale) * 1000;
    [self validateAndFilterSegmentsWithMinDuration:minDuration];
    
    AVAssetTrack *asssetTrack1 = [[asset1 tracksWithMediaType:AVMediaTypeVideo] firstObject];
    self.track1 = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTimeRange timeRange1 = CMTimeRangeMake(kCMTimeZero, CMTimeMake(minDuration, 1000));
    [self.track1 insertTimeRange:timeRange1 ofTrack:asssetTrack1 atTime:timeRange1.start error:&error];
    NSParameterAssert(!error);
    
    AVAssetTrack *asssetTrack2 = [[asset2 tracksWithMediaType:AVMediaTypeVideo] firstObject];
    self.track2 = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTimeRange timeRange2 = CMTimeRangeMake(kCMTimeZero, CMTimeMake(minDuration, 1000));
    [self.track2 insertTimeRange:timeRange2 ofTrack:asssetTrack2 atTime:timeRange2.start error:&error];
    NSParameterAssert(!error);
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderScale = 1.0f;
    videoComposition.renderSize = CGSizeMake(480.f, 480.f);
    videoComposition.frameDuration = CMTimeMake(1, 60);
    
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, 480, 480);
    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(0, 0, 480, 480);
    [parentLayer addSublayer:videoLayer];
    
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    videoComposition.instructions = [self instructions];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.outputURL path]]) {
        [[NSFileManager defaultManager] removeItemAtURL:self.outputURL error:&error];
    }
    NSParameterAssert(!error);
    
    self.session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    self.session.outputURL = self.outputURL;
    self.session.outputFileType = AVFileTypeQuickTimeMovie;
    self.session.videoComposition = videoComposition;
    [self.session exportAsynchronouslyWithCompletionHandler:^{
        NSString *event = @"视频合唱合成成功率";
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (self.session.status) {
                case AVAssetExportSessionStatusUnknown:
                case AVAssetExportSessionStatusWaiting:
                case AVAssetExportSessionStatusExporting: {
                    break;
                }
                case AVAssetExportSessionStatusCompleted: {
                    [StatsServer event:event attributes:@{@"result": @"1"}];
                    [self.timer invalidate];
                    self.timer = nil;
                    if (self.success) {
                        self.success();
                    }
                    break;
                }
                case AVAssetExportSessionStatusFailed: {
                    [self.timer invalidate];
                    self.timer = nil;
                    
                    BOOL isInterupted = (self.session.error.code == -11847);
                    if (isInterupted) {
                        NSParameterAssert(self.interuption);
                        if (self.interuption) {
                            self.interuption();
                        }
                    } else {
                        NSString *segmentsString = [[MTLJSONAdapter JSONArrayFromModels:self.segments] JSONSerialString];
                        NSString *durationString = [NSString stringWithFormat:@"\nDuration:%f", minDuration];
                        segmentsString = [segmentsString stringByAppendingString:durationString];
                        [[CommonDebugLogUtil shareInstance] addRecord:segmentsString];
                        NSLog(@"%@", self.session.error);
                        NSLog(@"%@", self.session.videoComposition.instructions);
                        [StatsServer event:event attributes:@{@"result": @"0"}];
                        if (self.failure) {
                            self.failure(self.session.error);
                        }
                    }
                    
                    break;
                }
                case AVAssetExportSessionStatusCancelled: {
                    [self.timer invalidate];
                    self.timer = nil;
                    if (self.failure) {
                        self.failure(self.session.error);
                    }
                    break;
                }
                default:
                    break;
            }
        });
    }];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:.1f block:^{
        if (self.progress) {
            self.progress(self.session.progress);
        }
    } repeats:YES];
}

- (void)validateAndFilterSegmentsWithMinDuration:(NSTimeInterval)minDuration {
    NSMutableArray *filteredSegments = [NSMutableArray array];
    [self.segments enumerateObjectsUsingBlock:^(KTVDuetVideoAnimationSegment *segment, NSUInteger index, BOOL *stop) {
        BOOL isLastSegment = (index == [self.segments count] - 1);
        if (segment.end < minDuration && !isLastSegment) {
            [filteredSegments addObject:segment];
        } else {
            KTVDuetVideoAnimationSegment *last = [[KTVDuetVideoAnimationSegment alloc] initWithStart:segment.start end:minDuration state:segment.state];
            [filteredSegments addObject:last];
            *stop = YES;
            return;
        }
    }];
    
    // Last segment might be too short after trimming by minDuartion. Should merge last two segments in this situation.
    KTVDuetVideoAnimationSegment *lastSegment = [filteredSegments lastObject];
    BOOL isLastSegmentTooShort = (lastSegment.end - lastSegment.start) < KTV_DUET_VIDEO_ANIMATION_DURATION;
    if ([filteredSegments count] > 1 && isLastSegmentTooShort) {
        KTVDuetVideoAnimationSegment *previousSegment = filteredSegments[[filteredSegments count] - 2];
        KTVDuetVideoAnimationSegment *mergedSegment = [[KTVDuetVideoAnimationSegment alloc] initWithStart:previousSegment.start end:lastSegment.end state:previousSegment.state];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([filteredSegments count] - 2, 2)];
        [filteredSegments removeObjectsAtIndexes:indexSet];
        [filteredSegments addObject:mergedSegment];
    }
    
    self.segments = filteredSegments;
}

- (NSArray *)instructions {
    const CGFloat animationDuration = KTV_DUET_VIDEO_ANIMATION_DURATION;
    NSMutableArray *instructions = [NSMutableArray array];
    
    BOOL hasOneSegmentOnly = [self.segments count] == 1;
    if (hasOneSegmentOnly) {
        KTVDuetVideoAnimationSegment *segment = [self.segments firstObject];
        CMTimeRange timeRange = CMTimeRangeMake(CMTimeMake(segment.start, 1000), CMTimeMake(segment.end - segment.start, 1000));
        AVMutableVideoCompositionInstruction *instruction = [self instructionForTimeRange:timeRange startState:segment.state endState:segment.state];
        [instructions addObject:instruction];
        return instructions;
    }
    
    [self.segments enumerateObjectsUsingBlock:^(KTVDuetVideoAnimationSegment *segment, NSUInteger idx, BOOL *stop) {
        NSParameterAssert(segment.end - segment.start > animationDuration);
        BOOL isLastSegment = (idx >= [self.segments count] - 1);
        
        {
            // Still instruction
            BOOL isFirstSegment = (idx == 0);
            KTVDuetVideoState startState = segment.state;
            KTVDuetVideoState endState = segment.state;
            CMTime start = isFirstSegment ? CMTimeMake(segment.start, 1000) : CMTimeMake(segment.start + animationDuration / 2, 1000);
            CMTime duration = isFirstSegment || isLastSegment ? CMTimeMake(segment.end - segment.start - animationDuration / 2, 1000) : CMTimeMake(segment.end - segment.start - animationDuration, 1000);
            CMTimeRange timeRange = CMTimeRangeMake(start, duration);
            AVMutableVideoCompositionInstruction *instruction = [self instructionForTimeRange:timeRange startState:startState endState:endState];
            [instructions addObject:instruction];
        }
        
        // Animation instruction
        if (!isLastSegment) {
            KTVDuetVideoAnimationSegment *next = self.segments[idx + 1];
            CMTimeRange timeRange = CMTimeRangeMake(CMTimeMake(segment.end - animationDuration / 2, 1000), CMTimeMake(animationDuration, 1000));
            KTVDuetVideoState startState = segment.state;
            KTVDuetVideoState endState = next.state;
            AVMutableVideoCompositionInstruction *instruction = [self instructionForTimeRange:timeRange startState:startState endState:endState];
            [instructions addObject:instruction];
        }
    }];
    
    return instructions;
}

- (AVMutableVideoCompositionInstruction *)instructionForTimeRange:(CMTimeRange)timeRange startState:(KTVDuetVideoState)startState endState:(KTVDuetVideoState)endState {
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = timeRange;
    AVMutableVideoCompositionLayerInstruction *layerInstruction1 = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:self.track1];
    AVMutableVideoCompositionLayerInstruction *layerInstruction2 = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:self.track2];
    [layerInstruction1 setCropRectangleRampFromStartCropRectangle:[self leftRectForState:startState] toEndCropRectangle:[self leftRectForState:endState] timeRange:timeRange];
    [layerInstruction2 setCropRectangleRampFromStartCropRectangle:[self rightRectForState:startState] toEndCropRectangle:[self rightRectForState:endState] timeRange:timeRange];
    [layerInstruction1 setTransformRampFromStartTransform:[self leftTransformForState:startState] toEndTransform:[self leftTransformForState:endState] timeRange:timeRange];
    [layerInstruction2 setTransformRampFromStartTransform:[self rightTransformForState:startState] toEndTransform:[self rightTransformForState:endState] timeRange:timeRange];
    instruction.layerInstructions = @[layerInstruction1, layerInstruction2];
    return instruction;
}

- (CGRect)leftRectForState:(KTVDuetVideoState)state {
    CGRect rect = CGRectZero;
    switch (state) {
        case KTVDuetVideoStateLeft:
            rect = CGRectMake(0, 0, 480, 480);
            break;
        case KTVDuetVideoStateSplit:
            rect = CGRectMake(120, 0, 240, 480);
            break;
        case KTVDuetVideoStateRight:
            rect = CGRectMake(0, 0, 480, 480);
            break;
        case KTVDuetVideoStateTransitioning:
            NSParameterAssert(nil);
            break;
        default:
            break;
    }
    return rect;
}

- (CGRect)rightRectForState:(KTVDuetVideoState)state {
    CGRect rect = CGRectZero;
    switch (state) {
        case KTVDuetVideoStateLeft:
            rect = CGRectMake(0, 0, 480, 480);
            break;
        case KTVDuetVideoStateSplit:
            rect = CGRectMake(120, 0, 240, 480);
            break;
        case KTVDuetVideoStateRight:
            rect = CGRectMake(0, 0, 480, 480);
            break;
        case KTVDuetVideoStateTransitioning:
            NSParameterAssert(nil);
            break;
        default:
            break;
    }
    return rect;
}

- (CGAffineTransform)leftTransformForState:(KTVDuetVideoState)state {
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (state) {
        case KTVDuetVideoStateLeft:
            transform = CGAffineTransformIdentity;
            break;
        case KTVDuetVideoStateSplit:
            transform = CGAffineTransformTranslate(transform, -120, 0);
            break;
        case KTVDuetVideoStateRight:
            transform = CGAffineTransformTranslate(transform, -480, 0);
            break;
        case KTVDuetVideoStateTransitioning:
            NSParameterAssert(nil);
            break;
        default:
            break;
    }
    return transform;
}

- (CGAffineTransform)rightTransformForState:(KTVDuetVideoState)state {
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (state) {
        case KTVDuetVideoStateLeft:
            transform = CGAffineTransformTranslate(transform, 480, 0);
            break;
        case KTVDuetVideoStateSplit:
            transform = CGAffineTransformTranslate(transform, 120, 0);
            break;
        case KTVDuetVideoStateRight:
            transform = CGAffineTransformIdentity;
            break;
        case KTVDuetVideoStateTransitioning:
            NSParameterAssert(nil);
            break;
        default:
            break;
    }
    return transform;
}

@end

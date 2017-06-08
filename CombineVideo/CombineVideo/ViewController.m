//
//  ViewController.m
//  CombineVideo
//
//  Created by xiaozuoren on 2017/5/31.
//  Copyright © 2017年 xiaozuoren. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "PlayerViewController.h"

@interface ViewController ()

//@property (nonatomic, strong) AVPlayerViewController *playerViewController;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *item;
@property (nonatomic, strong) NSURL *fileURL;

@property (nonatomic) PlayerViewController *playerViewController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addButtonDidClick:(id)sender {
    [self combVideos];
}

- (void)combVideos {
    NSString *firstVideoString = @"/Users/xiaozr/Desktop/output1.mp4";
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    NSString *filePath1 = [[NSBundle mainBundle] pathForResource:@"output1.mp4" ofType:nil inDirectory:@"coco"];
    
    NSURL *url = [NSURL fileURLWithPath:filePath1];
    
    AVAsset *firstAsset = [[AVURLAsset alloc] initWithURL:url options:optDict];
    
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    
    NSArray *tracks = [firstAsset tracksWithMediaType:AVMediaTypeVideo];
    
    if (tracks.count == 0) {
        return;
    }
    
    AVAssetTrack *firstVideoAssetTrack = [[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration) ofTrack:firstVideoAssetTrack atTime:kCMTimeZero error:nil];
   
    
    
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [cachePath stringByAppendingPathComponent:@"1233.mp4"];
    AVAssetExportSession *exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    exporterSession.outputFileType = AVFileTypeMPEG4;
    exporterSession.outputURL = [NSURL fileURLWithPath:filePath]; //如果文件已存在，将造成导出失败
    exporterSession.shouldOptimizeForNetworkUse = NO; //用于互联网传输
    [exporterSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exporterSession.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"exporter Unknow");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"exporter Canceled");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"exporter Failed");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"exporter Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"exporter Exporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporter Completed");
                break;
        }
    }];
    
    NSLog(@"filePath = %@", filePath);
}

#pragma mark - 播放视频

- (IBAction)perBack1:(id)sender {
    NSString *firstFile = [[NSBundle mainBundle] pathForResource:@"output1.mp4" ofType:nil inDirectory:@"coco"];
    NSString *secondFile = [[NSBundle mainBundle] pathForResource:@"output3.mp4" ofType:nil inDirectory:@"coco"];
   NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    AVAsset *firstAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:firstFile] options:optDict];
    AVAsset *secondAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:secondFile] options:optDict];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *firstVideoAssetTrack = [[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetTrack *firstAudioAssetTrack = [[firstAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration) ofTrack:firstVideoAssetTrack atTime:kCMTimeZero error:nil];
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAudioAssetTrack.timeRange.duration) ofTrack:firstAudioAssetTrack atTime:kCMTimeZero error:nil];
    
    AVAssetTrack *secondVideoAssetTrack = [[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetTrack *secondAudioAssetTrack = [[secondAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoAssetTrack.timeRange.duration) ofTrack:secondVideoAssetTrack atTime:firstVideoAssetTrack.timeRange.duration error:nil];
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAudioAssetTrack.timeRange.duration) ofTrack:secondAudioAssetTrack atTime:firstAudioAssetTrack.timeRange.duration error:nil];
    
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"preBack1-%d.mp4", arc4random() % 100]];
    
    AVAssetExportSession *exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    exporterSession.outputFileType = AVFileTypeMPEG4;
    exporterSession.outputURL = [NSURL fileURLWithPath:filePath]; //如果文件已存在，将造成导出失败
    exporterSession.shouldOptimizeForNetworkUse = NO; //用于互联网传输
    [exporterSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exporterSession.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"exporter Unknow");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"exporter Canceled");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"exporter Failed");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"exporter Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"exporter Exporting");
                break;
            case AVAssetExportSessionStatusCompleted: {
                NSLog(@"exporter Completed");
                self.fileURL = [NSURL fileURLWithPath:filePath];
                break;
            }
                
        }
    }];
    NSLog(@"%@", filePath);
}


- (IBAction)preBack2:(id)sender {
    
}

- (IBAction)leftRight1:(id)sender {
    self.playerViewController = [[PlayerViewController alloc] init];
    self.playerViewController.leftFile =  [[NSBundle mainBundle] URLForResource:@"output5" withExtension:@"mp4"];
    self.playerViewController.rightFile = [[NSBundle mainBundle] URLForResource:@"output2" withExtension:@"mp4"];
    self.playerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height / 3.0);
    [self.view addSubview:self.playerViewController.view];
    [self addChildViewController:self.playerViewController];
}

- (IBAction)leftRight2:(id)sender {
    
}


- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@"end");
}

#pragma mark - 播放视频
- (void)playMoviewWithFileURL:(NSURL *)url {
    AVAsset *asset = [AVAsset assetWithURL:url];
    self.item = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [AVPlayer playerWithPlayerItem:self.item];
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    layer.contentsScale = [UIScreen mainScreen].scale;
    layer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height / 2.0);
    [self.view.layer addSublayer:layer];
    
    //监听status属性，注意监听的是AVPlayerItem
    [self.item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    //监听loadedTimeRanges属性
    [self.item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
}

//AVPlayerItem监听的回调函数
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        
    }else if ([keyPath isEqualToString:@"status"]){
        if (playerItem.status == AVPlayerItemStatusReadyToPlay){
            NSLog(@"playerItem is ready");
            
            //如果视频准备好 就开始播放
            [self.player play];
            
        } else if(playerItem.status==AVPlayerStatusUnknown){
            NSLog(@"playerItem Unknown错误");
        }
        else if (playerItem.status==AVPlayerStatusFailed){
            NSLog(@"playerItem 失败");
        }
    }
}

- (IBAction)play:(UIButton *)sender {
   [self playMoviewWithFileURL:self.fileURL];
    
}


- (IBAction)play3:(id)sender {
    [self.playerViewController play];
}

@end

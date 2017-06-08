//
//  PlayerViewController.m
//  CombineVideo
//
//  Created by xiaozuoren on 2017/6/1.
//  Copyright © 2017年 xiaozuoren. All rights reserved.
//

#import "PlayerViewController.h"
#import "PlayerView.h"

@interface PlayerViewController ()

@property (weak, nonatomic) IBOutlet PlayerView *leftView;
@property (weak, nonatomic) IBOutlet PlayerView *rightView;

@property (nonatomic) AVPlayer *leftPlayer;
@property (nonatomic) AVPlayer *rightPlayer;
@property (nonatomic) AVPlayerItem *leftPlayerItem;
@property (nonatomic) AVPlayerItem *rightPlayerItem;

@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadAssetFromLeftFileURL];
    [self loadAssetFromRighttFileURL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadAssetFromLeftFileURL {
    static const NSString *leftItemStatusContext;
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:self.leftFile options:nil];
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [asset statusOfValueForKey:@"tracks" error:&error];
            
            if (status == AVKeyValueStatusLoaded) {
                self.leftPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
                [self.leftPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:&leftItemStatusContext];
                self.leftPlayer = [AVPlayer playerWithPlayerItem:self.leftPlayerItem];
                [self.leftView setPlayer:self.leftPlayer];
            } else {
                NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
            }
        });
    }];
}

- (void)loadAssetFromRighttFileURL {
    static const NSString *leftItemStatusContext;
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:self.rightFile options:nil];
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [asset statusOfValueForKey:@"tracks" error:&error];
            
            if (status == AVKeyValueStatusLoaded) {
                self.rightPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
                [self.rightPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:&leftItemStatusContext];
                self.rightPlayer = [AVPlayer playerWithPlayerItem:self.rightPlayerItem];
                [self.rightView setPlayer:self.rightPlayer];
            } else {
                NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
            }
        });
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        if (playerItem.status == AVPlayerItemStatusReadyToPlay){
            NSLog(@"playerItem is ready");
            //如果视频准备好 就开始播放
        } else if(playerItem.status==AVPlayerStatusUnknown){
            NSLog(@"playerItem Unknown错误");
        }
        else if (playerItem.status==AVPlayerStatusFailed){
            NSLog(@"playerItem 失败");
        }
    }
}

- (void)play {
    [self.leftPlayer play];
    [self.rightPlayer play];
}

@end

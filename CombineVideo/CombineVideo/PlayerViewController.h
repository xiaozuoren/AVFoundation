//
//  PlayerViewController.h
//  CombineVideo
//
//  Created by xiaozuoren on 2017/6/1.
//  Copyright © 2017年 xiaozuoren. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayerViewController : UIViewController

@property (nonatomic, copy) NSURL *leftFile;
@property (nonatomic, copy) NSURL *rightFile;

- (void)play;

@end

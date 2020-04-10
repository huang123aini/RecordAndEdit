//
//  HAVPlayer.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@class HAVPlayer;

@protocol HAVPlayerPlayBackDelegate <NSObject>

@required

- (void) loopPlayStart:(HAVPlayer *) player;

@end


@interface HAVPlayer : AVPlayer

@property (nonatomic, assign) id<HAVPlayerPlayBackDelegate> delegate;

@property (nonatomic, assign) BOOL enableRepeat;

@property (nonatomic, assign) BOOL finished;

- (instancetype) initWithPlayerItem:(AVPlayerItem *)item withAudioURL:(NSURL *) audioURLs;

- (CGFloat) getAudioVolume;

- (CGFloat) getVideoVolume;

- (void) setAudioVolume:(CGFloat) volume;

- (void) setVideoVolume:(CGFloat) volume;

- (void) setAudioURL:(NSURL *) audioUrl;

- (void) audioPlay;

- (void) audioPause;

- (void) restart;

- (void) seekToTime2:(CMTime)time;

- (void) seekToTime2:(CMTime)time completionHandler:(void (^)(BOOL finished)) handler;

- (void) seekToTime:(CMTime)time;

- (void) seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished)) handler;

- (void) syncAudio2Video;

@end

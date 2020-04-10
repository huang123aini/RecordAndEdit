//
//  HAVPlayer.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVPlayer.h"

@interface HAVPlayer ()

@property (nonatomic, strong) AVAudioPlayer *backgroundAudioPlayer;
@property (nonatomic, assign) BOOL isNotification ;

@end

@implementation HAVPlayer

- (instancetype) init{
    self = [super init];
    if(self){
        _finished = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlayBackEndNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currentItem];
        self.isNotification = YES;
    }
    return self;
}

- (instancetype) initWithPlayerItem:(AVPlayerItem *)item withAudioURL:(NSURL *) audioURL{
    self = [super initWithPlayerItem:item];
    if(self){
        if(audioURL != nil){
            NSError *error;
            NSData *data = [NSData dataWithContentsOfURL:audioURL];
            if(data != nil){
                self.backgroundAudioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
                [self.backgroundAudioPlayer prepareToPlay];
            }
        }
    }
    return self;
}

- (void) setAudioURL:(NSURL *) audioUrl{
    if(audioUrl != nil){
        NSError *error;
        [self.backgroundAudioPlayer stop];
        self.backgroundAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioUrl error:&error];
        [self.backgroundAudioPlayer prepareToPlay];
    }else{
        [self.backgroundAudioPlayer stop];
        self.backgroundAudioPlayer = nil;
    }
}

- (void) restart{
    [self pause];
    [self seekToTime:kCMTimeZero];
    [super play];
}

- (void) audioPlay{
    if(!self.backgroundAudioPlayer.isPlaying){
        [self.backgroundAudioPlayer play];
    }
}

- (void) audioPause{
    if(self.backgroundAudioPlayer.isPlaying){
        [self.backgroundAudioPlayer pause];
    }
}

- (void) play{
    if(!self.isNotification){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlayBackEndNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currentItem];
        self.isNotification = YES;
    }
    if(!self.backgroundAudioPlayer.isPlaying){
        [self.backgroundAudioPlayer play];
    }
    [super play];
}

- (void) pause{
    [super pause];
    [self.backgroundAudioPlayer pause];
    if(self.isNotification ){
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        self.isNotification = NO;
    }
}

- (void) setMuted:(BOOL)muted{
    [super setMuted:muted];
}

- (void) setAudioVolume:(CGFloat) volume{
    [self.backgroundAudioPlayer setVolume:volume];
}

- (CGFloat) getAudioVolume{
    return self.backgroundAudioPlayer.volume;
}

- (CGFloat) getVideoVolume{
    return super.volume;
}

- (void) setVideoVolume:(CGFloat) volume{
    [super setVolume:volume];
}

- (void) playerPlayBackEndNotification:(NSNotification *) notification{
    if(self.enableRepeat){
        if(self.delegate != nil){
            [self.delegate loopPlayStart:self];
        }
        [super pause];
        [self seekToTime:kCMTimeZero];
        [super play];
        self.backgroundAudioPlayer.currentTime = 0.0f;
        [self.backgroundAudioPlayer play];
        _finished = NO;
    }else{
        _finished = YES;
    }
}

- (void) syncAudio2Video{
    if(self.backgroundAudioPlayer.isPlaying){
        [self.backgroundAudioPlayer pause];
    }
    self.backgroundAudioPlayer.currentTime = CMTimeGetSeconds(self.currentTime);
    if(self.rate > 0.0f){
        [self.backgroundAudioPlayer play];
    }
}

- (void) seekToTime:(CMTime)time{
    _finished = NO;
    [super seekToTime:time];
    _backgroundAudioPlayer.currentTime = CMTimeGetSeconds(time);
}

- (void) seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler{
    [super seekToTime:time completionHandler:^(BOOL finished) {
        _backgroundAudioPlayer.currentTime = CMTimeGetSeconds(time);
        _finished = NO;
        completionHandler(finished);
    }];
}

- (void) seekToTime2:(CMTime)time{
    _finished = NO;
    [super seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    _backgroundAudioPlayer.currentTime = CMTimeGetSeconds(time);
}

- (void) seekToTime2:(CMTime)time completionHandler:(void (^)(BOOL finished))handler{
    _finished = NO;
    [super seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:handler];
    _backgroundAudioPlayer.currentTime = CMTimeGetSeconds(time);
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

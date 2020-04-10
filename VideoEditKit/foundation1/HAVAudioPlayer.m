//
//  HAVAudioPlayer.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface HAVAudioPlayer()

@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation HAVAudioPlayer

- (instancetype) initWithUrl:(NSURL *) url
{
    self = [super init];
    if(self != nil)
    {
        if(url != nil)
        {
            NSError *error ;
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
            [self.player prepareToPlay];
        }
    }
    return self;
}

- (instancetype) initWithLocalPath:(NSString *) localPath
{
    if(localPath != nil)
    {
        NSURL *url = [NSURL fileURLWithPath: localPath];
        if(url != nil)
        {
            self = [self initWithUrl:url];
        }else
        {
            self = [super init];
        }
    }else
    {
        self = [super init];
    }
    return self;
}

- (void) setUrl:(NSURL *) url
{
    [self stop];
    NSError *error ;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    [self.player prepareToPlay];
    
}

- (BOOL) play
{
    if(self.player != nil)
    {
        return [self.player play];
    }
    return NO;
}

- (void) pause{
    if(self.player != nil){
        [self.player pause];
    }
}

- (void) reset{
    [self pause];
    self.player.currentTime = 0;
}

- (void) replay{
    [self pause];
    self.player.currentTime = 0;
    [self play];
}

- (void) seek:(NSTimeInterval) time{
    if(time < self.player.duration){
        [self pause];
        self.player.currentTime = time;
        [self play];
    }
}

- (void) stop{
    if(self.player != nil){
        [self.player stop];
    }
}

@end

//
//  HAVMutiTracksPlayerItem.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVMutiTracksPlayerItem.h"
#import "HAVAudioTrack.h"
#import "HAVMutiTracksPlayerItem.h"
#import "HAVVideoTrack.h"

@interface HAVMutiTracksPlayerItem()

@property(nonatomic, strong) HAVVideoTrack *videoTrack;
@property(nonatomic, strong) NSMutableArray *audioTracks;

@end

@implementation HAVMutiTracksPlayerItem

- (instancetype) initWithVideoURL:(NSArray *)videoURLs WithAudioURL:(NSArray *) audioURLs{
    
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    NSMutableArray *audioMixParams = [[NSMutableArray alloc] init];
    
    if (videoURLs.count > 0)
    {
        _videoTrack = [[HAVVideoTrack alloc] init];
        for (NSURL *url in videoURLs)
        {
            [_videoTrack addVideoAsset:url];
        }
        /** 给多个 video 添加到同一轨道**/
        if(_videoTrack != nil)
        {
            [_videoTrack addToComposition:composition];
            NSArray *array = [_videoTrack getAudioMixInputParameters];
            if(array.count > 0)
            {
                [audioMixParams addObjectsFromArray:array];
            }
        }
    }
    CMTime offset = kCMTimeZero;
    /** 给每一个audio 添加到一个轨道**/
    if(audioURLs.count > 0)
    {
        _audioTracks = [[NSMutableArray alloc] init];
        for (NSURL *url in audioURLs)
        {
            if(url != nil)
            {
                HAVAudioTrack *audioTrack = [[HAVAudioTrack alloc] init];
                [audioTrack setAudioAssetUrl:url];
                AVMutableAudioMixInputParameters *inputParameters = [audioTrack createAudioMixInputParameters:composition atOffsetTime:offset];
                if(inputParameters != nil)
                {
                    [audioMixParams addObject:inputParameters];
                }
                offset = CMTimeAdd(offset, [audioTrack duration]);
            }
        }
    }
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
    
    self = [super initWithAsset:composition];
    if(self != nil)
    {
        self.audioMix = audioMix;
    }
    return self;
}

- (void) setAudioVolume:(CGFloat) volume atIndex:(NSInteger) index
{
    if(_audioTracks.count > index)
    {
        HAVAudioTrack *audioTrack = [_audioTracks objectAtIndex:index];
        [audioTrack setVolume:volume];
    }
}

- (void) setVideoVolume:(CGFloat) volume atIndex:(NSInteger) index
{
    if(_videoTrack != nil)
    {
        [_videoTrack setVolume:volume atIndex:index];
    }
    
}
@end

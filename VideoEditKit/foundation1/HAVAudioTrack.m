//
//  HAVAudioTrack.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVAudioTrack.h"

@interface HAVAudioTrack()
@property (nonatomic, strong) AVURLAsset *audioAsset;
@property (nonatomic, strong) AVMutableAudioMixInputParameters *audioMixInputParameters;
@end

@implementation HAVAudioTrack

-(instancetype) init{
    self = [super init];
    if(self){
        _volume = 1.0f;
    }
    return self;
}

-(void) setAudioLocalPath:(NSString *)path{
    if(path != nil){
        NSURL *audioAsset = [NSURL fileURLWithPath:path];
        if(audioAsset != nil){
            [self setAudioAssetUrl:audioAsset];
        }
    }
}
-(void) setAudioAssetUrl:(NSURL *) audioAssetUrl{
    if(audioAssetUrl != nil){
        _audioAsset = [AVURLAsset assetWithURL:audioAssetUrl];
    }
    
}

- (void) setAudioUrlAsset:(AVURLAsset *) audioUrlAsset{
    if(audioUrlAsset != nil){
        _audioAsset = audioUrlAsset;
    }
}

-(CMTime) duration{
    return [_audioAsset duration];
}


- (void) setVolume:(CGFloat)volume{
    _volume = volume;
    if(_audioMixInputParameters != nil){
        [_audioMixInputParameters setVolume:_volume atTime:kCMTimeZero];
    }
}

+ (AVMutableAudioMixInputParameters *) createAudioMixInputParameters:(AVMutableComposition *)composition audioAsset:(AVURLAsset *) audioAsset volume :(CGFloat) volume atOffsetTime:(CMTime) offset {
    AVAssetTrack *sourceAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if(sourceAudioTrack != nil){
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        CMTime startTime = kCMTimeZero;
        CMTime trackDuration = [audioAsset duration];
        CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
        AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
        [trackMix setVolume:volume atTime:startTime];
        NSError * error;
        BOOL ret =  [audioTrack insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:offset error:&error];
        if(ret){
            return trackMix;
        }
    }
    return nil;
}




- (AVMutableAudioMixInputParameters *) createAudioMixInputParameters:(AVMutableComposition *)composition{
    AVAssetTrack *sourceAudioTrack = [[_audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if(sourceAudioTrack != nil){
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        CMTime offset = kCMTimeZero;
        CMTime videoTimeDuration = [composition duration];
        AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
        [trackMix setVolume:self.volume atTime:kCMTimeZero];
        while(CMTimeCompare(offset, videoTimeDuration) < 0){
            NSError *error;
            CMTimeRange tRange = CMTimeRangeMake(kCMTimeZero, [_audioAsset duration]);
            [audioTrack insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:offset error:&error];
            offset = CMTimeAdd(offset,  [_audioAsset duration]);
        }
        return trackMix;
    }
    return nil;
}

- (AVMutableAudioMixInputParameters *) createAudioMixInputParameters:(AVMutableComposition *)composition atOffsetTime:(CMTime) offset {
    if(_audioAsset != nil){
        _audioMixInputParameters = [HAVAudioTrack createAudioMixInputParameters:composition audioAsset:_audioAsset volume:self.volume atOffsetTime:offset];
        return _audioMixInputParameters;
    }
    return nil;
    
}

@end

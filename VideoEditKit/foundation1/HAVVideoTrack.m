//
//  HAVVideoTrack.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVVideoTrack.h"
#import "HAVAudioTrack.h"
#import "AVURLAsset+MetalData.h"

@interface HAVVideoTrack()

@property (nonatomic, strong) NSMutableArray *videoAssets;
@property (nonatomic, strong) NSMutableArray *audioMixInputParameters;

@end

@implementation HAVVideoTrack

- (instancetype) init{
    self = [super init];
    if(self){
        _videoAssets = [[NSMutableArray alloc] init];
        _audioMixInputParameters = [[NSMutableArray alloc] init];
        _volume = 1.0f;
    }
    return self;
}


- (NSArray *) getAudioMixInputParameters{
    
    return _audioMixInputParameters;
    
}

- (CGSize) naturalSize{
    
    if(_videoAssets.count > 0){
        AVURLAsset *videoUrlAsset =  [_videoAssets firstObject];
        return [videoUrlAsset videoNaturalSize];
    }
    return CGSizeZero;
}

- (NSString *) videoSizePreset{
    CGSize videoSize = [self naturalSize];
    if(CGSizeEqualToSize(videoSize, CGSizeMake(640, 480))
       || CGSizeEqualToSize(videoSize, CGSizeMake(480, 640))){
        return AVAssetExportPreset640x480;
    }
    if(CGSizeEqualToSize(videoSize, CGSizeMake(960, 540))
       || CGSizeEqualToSize(videoSize, CGSizeMake(540, 960))){
        return AVAssetExportPreset960x540;
    }
    if(CGSizeEqualToSize(videoSize, CGSizeMake(1280, 720))
       || CGSizeEqualToSize(videoSize, CGSizeMake(720, 1280))){
        return AVAssetExportPreset1280x720;
    }
    if(CGSizeEqualToSize(videoSize, CGSizeMake(1920, 1080))
       || CGSizeEqualToSize(videoSize, CGSizeMake(1080, 1920))){
        return AVAssetExportPreset1920x1080;
    }
    if(CGSizeEqualToSize(videoSize, CGSizeMake(3840, 2160))
       || CGSizeEqualToSize(videoSize, CGSizeMake(2160, 3840))){
        return AVAssetExportPreset3840x2160;
    }
    return AVAssetExportPreset960x540;
}



- (NSString *) videoSizeToPreset:(HAVVideoSize) videoSize{
    switch (videoSize) {
        case HAVVideoSize480p:{
            return AVAssetExportPreset640x480;
        }
            break;
        case HAVVideoSize540p:{
            return AVAssetExportPreset960x540;
        }
            break;
        case  HAVVideoSize720p:{
            return AVAssetExportPreset1280x720;
        }
            break;
        case  HAVVideoSize1080p:{
            return AVAssetExportPreset1920x1080;
        }
            break;
        case  HAVVideoSize4K:{
            return AVAssetExportPreset3840x2160;
        }
            break;
        default:{
            return [self videoSizePreset];
        }
            break;
    }
}

- (CMTime) duration{
    CMTime totalDuration = kCMTimeZero;
    for (AVURLAsset *videoAsset in _videoAssets){
        CMTime duration = [videoAsset duration];
        totalDuration = CMTimeAdd(totalDuration, duration);
    }
    return totalDuration;
}

- (void) addVideoUrlAsset:(AVURLAsset *) assetUrl{
    if(assetUrl != nil){
        [_videoAssets addObject:assetUrl];
    }
}

- (void) addVideoAsset:(NSURL *) assetUrl{
    if(assetUrl != nil){
        AVURLAsset *asset = [AVURLAsset assetWithURL:assetUrl];
        [self addVideoUrlAsset:asset];
    }
}

- (void) addVideoLocalPath:(NSString *) videoPath{
    if(videoPath != nil){
        NSURL *assetUrl = [NSURL fileURLWithPath:videoPath];
        if(assetUrl != nil){
            [self addVideoAsset:assetUrl];
        }
    }
}

- (void) addToComposition:(AVMutableComposition *)composition {
    if(_videoAssets != nil){
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        CMTime offset = kCMTimeZero;
        for (AVURLAsset *videoAsset in _videoAssets){
            AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
            NSError *error = nil;
            BOOL ok = NO;
            CMTime startTime = kCMTimeZero;
            CMTime trackDuration = [videoAsset duration];
            CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
            videoTrack.preferredTransform = sourceVideoTrack.preferredTransform;
            ok = [videoTrack insertTimeRange:tRange ofTrack:sourceVideoTrack atTime:offset error:&error];
            AVMutableAudioMixInputParameters *inputParameters = [HAVAudioTrack createAudioMixInputParameters:composition audioAsset:videoAsset volume:self.volume atOffsetTime:offset];
            if(inputParameters != nil){
                [_audioMixInputParameters addObject:inputParameters];
            }
            offset = CMTimeAdd(offset, trackDuration);
        }
    }
}

- (void) setVolume:(CGFloat)volume atIndex:(NSInteger) index{
    if(_audioMixInputParameters.count > index){
        AVMutableAudioMixInputParameters *inputParameters =[_audioMixInputParameters objectAtIndex:index];
        [inputParameters setVolume:volume atTime:kCMTimeZero];
    }
}

@end

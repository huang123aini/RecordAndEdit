//
//  HAVPlayerItem.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVPlayerItem.h"
#import "HAVVideoItem.h"
#import "HAVPlayerItem.h"
#import "HAVVideoTrack.h"

@interface HAVPlayerItem()

@property (nonatomic, strong) NSArray *allVideoURLs;
@property (nonatomic, strong) HAVVideoTrack *videoTrack;
@property (nonatomic, strong) AVMutableComposition *composition;

@end

@implementation HAVPlayerItem

- (instancetype) initWithVideoURL:(NSArray *)videoURLs {
    
    self.composition = [AVMutableComposition composition];
    
    if (videoURLs.count > 0){
        _videoTrack = [[HAVVideoTrack alloc] init];
        for (NSURL *url in videoURLs){
            [_videoTrack addVideoAsset:url];
        }
        [_videoTrack addToComposition:self.composition];
    }
    return [super initWithAsset:self.composition];
}

- (instancetype) initWithAsset:(AVAsset *)asset{
    self = [super initWithAsset: asset];
    if([asset isKindOfClass:[AVMutableComposition class]]){
        self.composition = (AVMutableComposition*)asset;
    }
    return self;
}

- (instancetype) initWithVideoItem:(NSArray *)videoItems audioUrl:(NSURL *) audioUrl{
    self.composition = [AVMutableComposition composition];
    if(videoItems.count > 0){
        AVMutableCompositionTrack *videoTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *audioTrack = nil;
        AVMutableCompositionTrack *audioTrack2 = nil;
        AVAssetTrack *songAudioTrack = nil;
        CMTime audioDuration = kCMTimeZero;
        if(audioUrl != nil){
            AVAsset *audioAsset = [AVAsset assetWithURL:audioUrl];
            audioDuration = [audioAsset duration];
            songAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            if(songAudioTrack != nil){
                audioTrack2 = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            }
        }
        
        CMTime offset = kCMTimeZero;
        CMTime audioOffset = kCMTimeZero;
        for (HAVVideoItem *videoItem in videoItems){
            AVAsset *videoAsset = [videoItem getVideoAsset];
            AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
            AVAssetTrack *sourceAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            AVAsset *audioAsset = [AVAsset assetWithURL:audioUrl];
            AVAssetTrack *songAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            NSError *error = nil;
            BOOL ok = NO;
            CMTime startTime = CMTimeMultiply([sourceVideoTrack minFrameDuration], 3);
            CMTime trackDuration = [sourceVideoTrack timeRange].duration;
            trackDuration = CMTimeSubtract(trackDuration, startTime);
            CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
            ok = [videoTrack insertTimeRange:tRange ofTrack:sourceVideoTrack atTime:offset error:&error];
            if(sourceAudioTrack != nil){
                if(audioTrack == nil){
                    audioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                }
                AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
                [trackMix setVolume:1.0f atTime:startTime];
                ok = [audioTrack insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:offset error:&error];
            }
            
            if(songAudioTrack != nil){
                CMTime totalDuration = CMTimeAdd(audioOffset, trackDuration);
                if(CMTimeCompare(totalDuration, audioDuration) < 0){
                    CMTimeRange tRange2 = CMTimeRangeMake(audioOffset, trackDuration);
                    ok = [audioTrack2 insertTimeRange:tRange2 ofTrack:songAudioTrack atTime:offset error:&error];
                    
                }else{
                    CMTime secondSegmentDuratuon = CMTimeSubtract(totalDuration, audioDuration);
                    CMTime firstSegmentDuratuon = CMTimeSubtract(trackDuration, secondSegmentDuratuon);
                    
                    CMTimeRange tRange2 = CMTimeRangeMake(audioOffset, firstSegmentDuratuon);
                    ok = [audioTrack2 insertTimeRange:tRange2 ofTrack:songAudioTrack atTime:offset error:&error];
                    
                    audioOffset = kCMTimeZero;
                    tRange2 = CMTimeRangeMake(audioOffset, secondSegmentDuratuon);
                    ok = [audioTrack2 insertTimeRange:tRange2 ofTrack:songAudioTrack atTime:offset error:&error];
                    audioTrack2.preferredVolume = 0.1f;
                }
            }
            if((videoItem.rate != 1.0f) && (videoItem.rate != 0.0f)){
                CMTime newDuration = CMTimeMultiplyByFloat64(trackDuration, 1.0f/videoItem.rate);
                CMTime startTime = CMTimeSubtract(self.composition.duration, trackDuration);
                tRange = CMTimeRangeMake(startTime,trackDuration);
                [videoTrack scaleTimeRange:tRange toDuration:newDuration];
                if(audioTrack != nil){
                    [audioTrack scaleTimeRange:tRange toDuration:newDuration];
                }
                if(audioTrack2 != nil){
                    [audioTrack2 scaleTimeRange:tRange toDuration:newDuration];
                }
                offset = CMTimeAdd(offset, newDuration);
                audioOffset = CMTimeAdd(audioOffset, newDuration);
            }else{
                offset = CMTimeAdd(offset, trackDuration);
                audioOffset = CMTimeAdd(audioOffset, trackDuration);
            }
        }
    }
    return self;
}

- (AVAsset *) getAsset{
    return self.composition;
}

@end

//
//  HAVAssetItem.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVAssetItem.h"
@interface HAVAssetItem()

@property (nonatomic, strong) AVURLAsset *asset;

@end

@implementation HAVAssetItem

- (instancetype) initWithPath:(NSString*) path
{
    if(path != nil)
    {
        NSURL *url = [NSURL fileURLWithPath:path];
        return [self initWithURL:url];
    }
    return [self init];
}

- (instancetype) initWithURL:(NSURL *) videoUrl
{
    self = [super init];
    if((self != nil) && (videoUrl != nil))
    {
        self.asset = [AVURLAsset assetWithURL:videoUrl];
        self.volume = 1.0f;
        _rate = 1.0f;
        _scaledDuration = self.asset.duration;
        _timeRange = CMTimeRangeMake(kCMTimeZero, _scaledDuration);
    }
    return self;
}

- (AVAsset*) getAsset
{
    return self.asset;
}

- (void)setRate:(CGFloat) rate
{
    _rate = rate;
    _scaledDuration = CMTimeMultiplyByFloat64([self.asset duration], 1.0f/self.rate);
    //    _timeRange = CMTimeRangeMake(kCMTimeZero, _scaledDuration);
}

- (AVAsset*) getCurrentAsset
{
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *audioTrack = nil;
    AVMutableCompositionTrack *videoTrack = nil;
    
    BOOL hasVideo = ([[self.asset tracksWithMediaType:AVMediaTypeVideo] count] > 0);
    if(hasVideo){
        videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    }
    
    BOOL hasAudio = ([[self.asset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
    if(hasAudio){
        audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    }
    AVAssetTrack *firstVideoTrack = [[self.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if(firstVideoTrack != nil){
        videoTrack.preferredTransform = firstVideoTrack.preferredTransform;
    }
    
    BOOL ok = NO;
    NSError *error = nil;
    CMTime offset = kCMTimeZero;
    CMTime trackDuration = [self.asset duration];
    CMTimeRange tRange = CMTimeRangeMake(kCMTimeZero, trackDuration);
    if(hasVideo){
        AVAssetTrack *sourceVideoTrack = [[self.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        if(CMTimeCompare(self.timeRange.start, tRange.duration) < 0){
            CMTime duration = CMTimeAdd(self.timeRange.duration, self.timeRange.start);
            if(CMTimeCompare(duration, tRange.duration) > 0){
                duration = CMTimeSubtract(trackDuration, self.timeRange.start);
            }else{
                duration = self.timeRange.duration;
            }
            tRange = CMTimeRangeMake(self.timeRange.start, duration);
        }
        ok = [videoTrack insertTimeRange:tRange ofTrack:sourceVideoTrack atTime:offset error:&error];
        if(ok){
            [videoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, tRange.duration) toDuration:_scaledDuration];
        }
    }
    if(hasAudio){
        AVAssetTrack *sourceAudioTrack = [[self.asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        if(CMTimeCompare(self.timeRange.start, tRange.duration) < 0){
            CMTime duration = CMTimeAdd(self.timeRange.duration, self.timeRange.start);
            if(CMTimeCompare(duration, tRange.duration) > 0){
                duration = CMTimeSubtract(trackDuration, self.timeRange.start);
            }else{
                duration = self.timeRange.duration;
            }
            tRange = CMTimeRangeMake(self.timeRange.start, duration);
        }
        ok = [audioTrack insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:offset error:&error];
        if(ok)
        {
            if(hasVideo)
            {
                [audioTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, tRange.duration) toDuration:_scaledDuration];
            }
        }
    }
    offset = CMTimeAdd(offset, trackDuration);
    
    return composition;
}

- (void) setDuration:(NSTimeInterval) timeInterval
{
    if((timeInterval < 61) && (timeInterval > 0))
    {
        CGFloat duration = CMTimeGetSeconds([self.asset duration]);
        _scaledDuration = CMTimeMake(timeInterval*1000, 1000);
        //        _timeRange = CMTimeRangeMake(kCMTimeZero, _scaledDuration);
        _rate = (duration / timeInterval);
    }
}
@end

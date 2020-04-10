//
//  HAVAsset.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVAsset.h"

@interface HAVAsset()

@property (nonatomic, assign) CGFloat rate;
@property (nonatomic, assign) CMTimeRange timeRange;
@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) NSArray<HAVAssetItem *> * assetItems;
@property (nonatomic, strong) HAVAssetItem *audioAssetItem;

@end

@implementation HAVAsset

- (AVAsset *) currentAsset{
    
    CGFloat scaleRate = 1.0f;
    if(_rate > 0.0f){
        scaleRate = _rate;
    }
    BOOL ok = NO;
    NSError *error = nil;
    
    CGFloat ratio = 1.0f / self.rate;
    
    AVMutableComposition *scaleComposition = [AVMutableComposition composition];
    
    [scaleComposition insertTimeRange:CMTimeRangeMake(kCMTimeZero, self.composition.duration) ofAsset:self.composition atTime:kCMTimeZero error:&error];
    
    CMTime toDuration = CMTimeMultiplyByFloat64(self.composition.duration, ratio);
    [scaleComposition scaleTimeRange:CMTimeRangeMake(kCMTimeZero, self.composition.duration) toDuration:toDuration];
    
    AVMutableComposition *currentComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *audioTrack = nil;
    AVMutableCompositionTrack *videoTrack = [currentComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    BOOL hasAudio = ([[scaleComposition tracksWithMediaType:AVMediaTypeAudio] count] > 0);
    if(hasAudio){
        audioTrack = [currentComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    }
    
    AVAssetTrack *firstVideoTrack = [[self.composition tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if(firstVideoTrack != nil){
        videoTrack.preferredTransform = firstVideoTrack.preferredTransform;
    }
    
    AVAssetTrack *sourceVideoTrack = [[scaleComposition tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    CMTimeRange tRange = self.timeRange;
    CMTime duration = scaleComposition.duration;
    CMTime rangeDuration = CMTimeAdd(self.timeRange.duration, self.timeRange.start);
    if(CMTimeCompare(rangeDuration, duration) > 0){
        if(CMTimeCompare(self.timeRange.start, duration) > 0){
            tRange = CMTimeRangeMake(kCMTimeZero, duration);
        }else{
            duration = CMTimeSubtract(duration, self.timeRange.start);
            tRange = CMTimeRangeMake(self.timeRange.start, duration);
        }
    }
    
    ok = [videoTrack insertTimeRange:tRange ofTrack:sourceVideoTrack atTime:kCMTimeZero error:&error];
    
    if(hasAudio){
        AVAssetTrack *sourceAudioTrack = [[scaleComposition tracksWithMediaType:AVMediaTypeAudio] firstObject];
        ok = [audioTrack insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:kCMTimeZero error:&error];
    }
    return currentComposition;
}

-(AVAsset*)coverAsset
{
    CGFloat scaleRate = 1.0f;
    if(_rate > 0.0f){
        scaleRate = _rate;
    }
    NSError *error = nil;
    
    CGFloat ratio = 1.0f / self.rate;
    
    AVMutableComposition *scaleComposition = [AVMutableComposition composition];
    
    [scaleComposition insertTimeRange:CMTimeRangeMake(kCMTimeZero, self.composition.duration) ofAsset:self.composition atTime:kCMTimeZero error:&error];
    
    CMTime toDuration = CMTimeMultiplyByFloat64(self.composition.duration, ratio);
    [scaleComposition scaleTimeRange:CMTimeRangeMake(kCMTimeZero, self.composition.duration) toDuration:toDuration];
    return scaleComposition;
}

- (AVAsset *) asset{
    return self.composition;
}

- (instancetype) initWithAssetItem:(HAVAssetItem *) item audioAssetItem:(HAVAssetItem *) audioAssetItem{
    
    self = [self initWithAssetItems:@[item] audioAssetItem:audioAssetItem];
    if(self != nil){
        
    }
    return self;
}

- (instancetype) initWithAssetItems:(NSArray<HAVAssetItem *> *) items audioAssetItem:(HAVAssetItem *) audioAssetItem{
    self = [super init];
    if(self){
        self.audioAssetItem = audioAssetItem;
        self.assetItems = items;
        self.composition = [AVMutableComposition composition];
        AVMutableCompositionTrack *audioTrack = nil;
        AVMutableCompositionTrack *videoTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        HAVAssetItem *assetItem = [items firstObject];
        AVAsset *avasset = [assetItem getAsset];
        BOOL hasAudio = ([[avasset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
        AVAsset *externalAudioAsset =  nil;
        if(self.audioAssetItem != nil)
        {
            externalAudioAsset = [self.audioAssetItem getCurrentAsset];
        }
        if(hasAudio || (externalAudioAsset != nil))
        {
            audioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        }
        AVAssetTrack *firstVideoTrack = [[avasset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        if(firstVideoTrack != nil)
        {
            videoTrack.preferredTransform = firstVideoTrack.preferredTransform;
        }
        
        CMTime offset = kCMTimeZero;
        for (HAVAssetItem *item in items)
        {
            BOOL ok = NO;
            NSError *error = nil;
            AVAsset *asset = [item getCurrentAsset];
            AVAssetTrack *sourceVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
            
            //CMTime trackDuration = [asset duration];
            /*最后一帧截取*/
            CMTime trackDuration =  CMTimeSubtract([asset duration], CMTimeMake(0.006 * 600, 600));
            
            CMTimeRange tRange = CMTimeRangeMake(kCMTimeZero, trackDuration);
            ok = [videoTrack insertTimeRange:tRange ofTrack:sourceVideoTrack atTime:offset error:&error];
            
            if((externalAudioAsset == nil) && hasAudio)
            {
                AVAssetTrack *sourceAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
                ok = [audioTrack insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:offset error:&error];
            }
            offset = CMTimeAdd(offset, trackDuration);
        }
        
        if(externalAudioAsset != nil)
        {
            NSError *error = nil;
            AVAssetTrack *sourceAudioTrack = [[externalAudioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            
            if(CMTimeCompare(offset, sourceAudioTrack.timeRange.duration) > 0){
                offset = sourceAudioTrack.timeRange.duration;
            }
            CMTimeRange tRange = CMTimeRangeMake(kCMTimeZero, offset);
            [audioTrack insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:kCMTimeZero error:&error];
        }
        [self reset];
    }
    return self;
}

- (void) reset
{
    self.rate = 1.0f;
    self.timeRange = CMTimeRangeMake(kCMTimeZero, [self.composition duration]);
}

- (void) setRate:(CGFloat) rate
{
    if(rate > 0.0f)
    {
        _rate = rate;
        CMTime duration = CMTimeMultiplyByFloat64([self.composition duration], 1.0f/self.rate);
        self.timeRange = CMTimeRangeMake(kCMTimeZero, duration);
    }
}

- (void) setTimeRange:(CMTimeRange) timeRange
{
    _timeRange = timeRange;
}
@end

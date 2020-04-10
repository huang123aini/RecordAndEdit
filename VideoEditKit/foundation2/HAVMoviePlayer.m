//
//  HAVMoviePlayer.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVMoviePlayer.h"
#import "HAVPlayer.h"
#import "HAVMoviePlayer.h"
#import "HAVAsset.h"
#import "AVAsset+MetalData.h"

@interface HAVMoviePlayer()<HAVPlayerPlayBackDelegate>
{
    GPUImageRotationMode outputRotation;
    CMTimeRange _timeRange;
}

@property (nonatomic, assign) CMTime chaseTime;
@property (nonatomic, assign) BOOL isSeekInProgress;
@property (nonatomic, strong) HAVPlayer *player;
@property (nonatomic, strong) HAVAsset *internalAsset;
@property (nonatomic, strong) AVAssetExportSession *exportSession;

/**
 启用新的配置进行设置
 **/
- (void) startWithNewSettings;

- (void) initOutputRotation;

@end

@implementation HAVMoviePlayer

- (instancetype) initWithURL:(NSURL *) videoUrl audioAssetItem:(HAVAssetItem *) audioAssetItem{
    HAVAssetItem *assetItem = [[HAVAssetItem alloc] initWithURL:videoUrl];
    self = [self initWithAssetItem:assetItem audioAssetItem:audioAssetItem];
    if(self){
        
    }
    return self;
}

- (instancetype) initWithFilePath:(NSString *) path audioAssetItem:(HAVAssetItem *) audioAssetItem{
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    
    self = [self initWithURL:fileUrl audioAssetItem:audioAssetItem];
    if(self){
        
    }
    return self;
}

- (instancetype) initWitHAVAsset:(HAVAsset *) asset {
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:[asset asset]];
    if(playerItem != nil){
        self = [super initWithPlayerItem:playerItem];
        if(self){
            self.internalAsset = asset;
            self.player = [[HAVPlayer alloc] initWithPlayerItem:playerItem];
            [self initOutputRotation];
            [self exportAudioToFile:[asset asset]];
            [self.player setMuted:YES];
            [self startProcessing];
        }
    }
    return self;
}

- (instancetype) initWithAssetItem:(HAVAssetItem *) item audioAssetItem:(HAVAssetItem *) audioAssetItem
{
    HAVAsset *asset = [[HAVAsset alloc] initWithAssetItem:item audioAssetItem:audioAssetItem];
    if(asset != nil)
    {
        return [self initWitHAVAsset:asset ];
    }
    return nil;
}

- (instancetype) initWithAssetItems:(NSArray<HAVAssetItem *> *) items audioAssetItem:(HAVAssetItem *) audioAssetItem
{
    HAVAsset *asset = [[HAVAsset alloc] initWithAssetItems:items audioAssetItem:audioAssetItem];
    if(asset != nil)
    {
        return [self initWitHAVAsset:asset];
    }
    return nil;
}


- (void) initOutputRotation
{
    outputRotation = kGPUImageNoRotation;
    NSArray *tracks = [[self getAsset] tracksWithMediaType:AVMediaTypeVideo];
    
    if([tracks count] > 0)
    {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;//这里的矩阵有旋转角度，转换一下即可
        //      NSUInteger degress = 0;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
        {
            // Portrait
            // degress = 90;
            outputRotation = kGPUImageRotateRight;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)
        {
            // PortraitUpsideDown
            outputRotation = kGPUImageRotateLeft;
            //degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
        {
            // LandscapeRight
            outputRotation = kGPUImageNoRotation;
            // degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
        {
            // LandscapeLeft
            outputRotation = kGPUImageRotate180;
            // degress = 180;
        }
    }
}

- (AVAsset *) getAsset
{
    return [self.internalAsset asset];
}

- (AVAsset *) getCurrentAsset
{
    return [self.internalAsset currentAsset];
}
-(AVAsset*)getCoverAsset
{
    return [self.internalAsset coverAsset];
}

- (void) setAudioURL:(NSURL *) audioUrl
{
    [self.player setAudioURL:audioUrl];
}

- (void) setAudioFilePath:(NSString *) filePath
{
    if(filePath.length > 0)
    {
        NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
        [self.player setAudioURL:fileUrl];
    }
}

- (void) setAudioVolume:(CGFloat) volume{
    [self.player setAudioVolume:volume];
}

- (void) setVideoVolume:(CGFloat) volume
{
    [self.player setVideoVolume:volume];
}

- (void) audioPlay
{
    [self.player audioPlay];
}

- (void) audioPause
{
    [self.player audioPause];
}

- (void) stop
{
    [self endProcessing];
    [self.player pause];
   
}

- (void) pause
{
    [self.player pause];
}

- (void) restart
{
    [self.player restart];
}

- (void) play
{
    [self.player play];
}

- (CGSize) getVideoSize
{
    CGSize size =  [[self getAsset] videoNaturalSize];
    if((outputRotation ==kGPUImageRotateLeft) || (outputRotation ==kGPUImageRotateRight)){
        size = CGSizeMake(size.height, size.width);
    }
    return size;
}

- (CMTime) frameDuration{
    NSArray *tracks = [[self getAsset] tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        return [videoTrack minFrameDuration];
    }
    return kCMTimeInvalid;
}

- (void) muted:(BOOL) mute{
    [self.player setMuted:mute];
}

- (void) backgroundMuted:(BOOL) mute{
    if(mute){
        [self.player setAudioVolume:0.0f];
    }else{
        [self.player setAudioVolume:1.0f];
    }
}

- (CMTime) currentTime{
    return self.player.currentTime;
}

- (CGFloat) currentTimeSeconds{
    return CMTimeGetSeconds(self.player.currentTime);
}

- (CGFloat) currentPlayTime{
    return CMTimeGetSeconds([self currentTimeStamp]);
}

- (CGFloat) duration{
    return CMTimeGetSeconds(self.player.currentItem.duration);
}

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation
{
    [super addTarget:newTarget atTextureLocation:textureLocation];
    [newTarget setInputRotation:outputRotation atIndex:textureLocation];
}

- (void) setVideoRotation:(HAVVideoRotation) rotation{
    switch (rotation) {
        case HAVRotationDegress0:
            outputRotation = kGPUImageNoRotation;
            break;
        case HAVRotationDegress90:
            outputRotation = kGPUImageRotateRight;
            break;
        case HAVRotationDegress180:
            outputRotation = kGPUImageRotate180;
            break;
        case HAVRotationDegress270:
            outputRotation = kGPUImageRotateLeft;
            break;
        default:
            break;
    }
    for (id <GPUImageInput> target in self.targets){
        [target setInputRotation:outputRotation atIndex:0];
    }
}

- (HAVVideoRotation) videoRotation
{
    HAVVideoRotation rotation = HAVRotationDegress0;
    switch (outputRotation) {
        case kGPUImageNoRotation:
            rotation = HAVRotationDegress0;
            break;
        case kGPUImageRotateRight:
            rotation = HAVRotationDegress90;
            break;
        case kGPUImageRotate180:
            rotation = HAVRotationDegress180;
            break;
        case kGPUImageRotateLeft:
            rotation = HAVRotationDegress270;
            break;
        default:
            break;
    }
    return rotation;
}

- (void) setPlayRate:(CGFloat) rate
{
    [self.internalAsset setRate:rate];
    [self startWithNewSettings];
}

- (void) setPlayTimeRange:(CMTimeRange) timeRange
{
    _timeRange = timeRange;
    [self.internalAsset setTimeRange:timeRange];
    [self startWithNewSettings];
}

- (void) seekTo:(NSTimeInterval) time completionHandler:(void (^)(BOOL finished))completionHandler
{
    CMTime seekTime = CMTimeMake(time*1000000000, 1000000000);
    if (completionHandler)
    {
        [self.player seekToTime:seekTime completionHandler:completionHandler];
    }
    else
    {
        [self.player seekToTime:seekTime];
    }
}

- (void) seekToWithAccuracy:(NSTimeInterval) time completionHandler:(void (^)(BOOL finished))completionHandler
{
    CMTime seekTime = CMTimeMake(time*1000000000, 1000000000);
    if (completionHandler)
    {
        [self.player seekToTime2:seekTime completionHandler:completionHandler];
    }
    else
    {
        [self.player seekToTime2:seekTime];
    }
}

- (void) exportAudioToFile:(AVAsset *) asset
{
    [self.exportSession cancelExport];
    self.exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    NSString *myPathDocs =  [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.m4a"];
    [[NSFileManager defaultManager] removeItemAtPath:myPathDocs error:nil];
    self.exportSession.outputURL = [NSURL fileURLWithPath:myPathDocs];
    self.exportSession.outputFileType = AVFileTypeAppleM4A;
    self.exportSession.shouldOptimizeForNetworkUse = YES;
    __weak __typeof(self) weakSelf = self;
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
        [weakSelf.player setAudioURL:weakSelf.exportSession.outputURL];
        [weakSelf.player syncAudio2Video];
    }];
}

- (void) startWithNewSettings
{
    [self.player pause];
    [self resetCurrentProcessing];
    AVAsset *currentAsset = [self.internalAsset currentAsset];
    //    NSLog(@"new duration:%f", CMTimeGetSeconds(currentAsset.duration));
    if(currentAsset != nil)
    {
        //        [self exportAudioToFile:currentAsset];
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:currentAsset];
        self.player = [[HAVPlayer alloc] initWithPlayerItem:item];
        self.player.enableRepeat = self.enableRepeat;
        self.player.delegate = self;
        [self.player setMuted:YES];
        self.playerItem = item;
    }
    [self.player play];
    [self startProcessing];
}

- (void) setEnableRepeat:(BOOL)enableRepeat
{
    _enableRepeat = enableRepeat;
    self.player.enableRepeat = enableRepeat;
}

- (BOOL) isFinished
{
    return self.player.finished;
}


- (void)seekSmoothlyToTime:(CMTime)newChaseTime
{
    [self.player pause];
    if (CMTIME_COMPARE_INLINE(newChaseTime, !=, self.chaseTime))
    {
        self.chaseTime = newChaseTime;
        if (!self.isSeekInProgress)
        {
            [self trySeekToChaseTime];
        }
    }
}

- (void)trySeekToChaseTime
{
    if ([[self.player currentItem] status] == AVPlayerItemStatusReadyToPlay){
        [self actuallySeekToTime];
    }
}

- (void)actuallySeekToTime
{
    self.isSeekInProgress = YES;
    CMTime seekTimeInProgress = self.chaseTime;
    [self.player seekToTime:seekTimeInProgress toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero completionHandler:
     ^(BOOL isFinished)
     {
         if (CMTIME_COMPARE_INLINE(seekTimeInProgress, ==, self.chaseTime))
             self.isSeekInProgress = NO;
         else
             [self trySeekToChaseTime];
     }];
}

@end

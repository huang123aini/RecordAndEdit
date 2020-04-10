//
//  HAVMovieFileReader.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVMovieFileReader.h"

#import "HAVAssetReaderOutput.h"
@interface HAVMovieFileReader ()
{
    CVPixelBufferRef videoPixelBuffer;
    CMTime currentFrameTime;
    CGFloat accuPTS;
    BOOL initialized;
    BOOL use3XMode;
    BOOL isPaused;
    CMTime itemCurrentTime;
    BOOL isPlaying;
    CMTime preTime;
}
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVAsset *assset;
@property (nonatomic, strong) AVPlayerItemVideoOutput *playerItemOutput;

@property (nonatomic, strong) AVAssetTrack *videoTrack;
@property (nonatomic,strong)  AVAssetTrack *audioTrack;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVAssetReader *videoReader;
@property (nonatomic, strong) HAVAssetReaderOutput* videoReaderOutput;

@property(nonatomic, assign) float rat;
@property(nonatomic, assign) float rate;
@property(nonatomic, assign) BOOL isWriteFile;
@property(nonatomic, assign) BOOL isFirstChange;
@property(nonatomic, assign) BOOL isFisished;
@property(nonatomic, assign) BOOL hasExported;


@property (nonatomic) CMSampleBufferRef sampleBuffer;

@end

@implementation HAVMovieFileReader

- (void) pause{
    [self.player pause];
    isPlaying = NO;
    if (use3XMode) {
        [self.videoReader cancelReading];
        isPaused = YES;
    }
}

- (void)replay{
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
    isPlaying = YES;
}

- (void)replayWithAudio:(BOOL)flag{
    isPlaying = YES;
    [self.player play];
    [self.player seekToTime:kCMTimeZero];
    if (!flag) {
        self.isWriteFile = YES;
        self.player.muted = YES;
    }
}

- (void) setWriteFile:(BOOL) writeFile {
    _isWriteFile = writeFile;
}

- (void) start{
    isPlaying = YES;
    [self.player play];
    
}

- (void) playMute
{
    self.player.muted = YES;
    isPlaying = YES;
    [self.player play];
}

- (void) startWithAudio:(BOOL)flag{
    isPlaying = YES;
    [self.player play];
    if (!flag) {
        self.player.muted = YES;
    }
    
}

-(void)setHasExport:(BOOL)hasExport
{
    self.hasExported = hasExport;
}

-(void)startWithAudio:(BOOL)flag  duration:(CMTime)duration{
    [self resetDuration:duration];
    isPlaying = YES;
    [self.player play];
    if (!flag)
    {
        self.player.muted = YES;
    }
}

- (void) playWithRate:(CGFloat) rate{
    self.rate = rate;
    isPlaying = YES;
    if (rate > 2.0) {
        isPaused = NO;
        use3XMode = YES;
        [self seekIn3XSpeed:CMTimeGetSeconds(self.player.currentItem.currentTime)];
        if (self.sampleBuffer) {
            CFRelease(self.sampleBuffer);
            self.sampleBuffer = nil;
        }
    }
    else {
        use3XMode = NO;
    }
    [self.player setRate:rate];
}

- (CGAffineTransform) transform{
    NSArray *tracks = [self.assset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        self.videoTrack = [tracks firstObject];
        return self.videoTrack.preferredTransform;
    }
    return CGAffineTransformIdentity;
}

- (instancetype) initWithUrl:(NSURL *) url
{
    if(url != nil){
        self.isInPreview = NO;
        self.isInCountDown = NO;
        AVAsset *asset = [AVAsset assetWithURL:url];
        return [self initWithAsset:asset];
    }
    return nil;
}

- (instancetype) initWithPath:(NSString *) path{
    if(path != nil){
        NSURL *url = [NSURL fileURLWithPath:path];
        return [self initWithUrl:url];
    }
    return nil;
}

- (GPUImageRotationMode) rotation
{
    GPUImageRotationMode outputRotation = kGPUImageNoRotation;
    CGAffineTransform t = [self transform];
    //这里的矩阵有旋转角度，转换一下即可
    // NSUInteger degress = 0;
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
        // Portrait
        // degress = 90;
        outputRotation = kGPUImageRotateRight;
    }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
        // PortraitUpsideDown
        outputRotation = kGPUImageRotateLeft;
        
        //degress = 270;
    }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
        // LandscapeRight
        outputRotation = kGPUImageNoRotation;
        //            degress = 0;
    }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
        // LandscapeLeft
        outputRotation = kGPUImageRotate180;
        //degress = 180;
    }
    return outputRotation;
}

-(float)getRatio
{
    
    //    CGRect rect = [UIScreen mainScreen].bounds;
    //    CGSize size = rect.size;
    //    CGFloat scale = [UIScreen mainScreen].scale;
    //    CGFloat pixelWidth = size.width*scale;
    //    CGFloat pixelHeight = size.height*scale;
    //
    //    float pixelRatio = pixelWidth / pixelHeight;
    //    //视频原始比例 * 像素尺寸比例
    return  self.rat;
}

-(void)resetDuration:(CMTime)duration
{
    
    //self.loopEnable = NO;
    self.isFisished = NO;
    isPlaying = NO;
    
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    if(self.assset)
    {
        
        NSArray *videoTracks = [self.assset tracksWithMediaType:AVMediaTypeVideo];
        NSArray *audioTracks = [self.assset tracksWithMediaType:AVMediaTypeAudio];
        
        self.videoTrack = [videoTracks objectAtIndex:0];
        self.audioTrack = [audioTracks objectAtIndex:0];
        
        
        
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        
        NSError *error = nil;
        BOOL ok = NO;
        CMTime startTime = kCMTimeZero;
        CMTime trackDuration = duration;/*[self.videoTrack timeRange].duration;*/
        trackDuration = CMTimeSubtract(trackDuration, startTime);
        CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
        
        ok = [videoTrack insertTimeRange:tRange ofTrack:self.videoTrack atTime:kCMTimeZero error:&error];
        
        ok = [audioTrack insertTimeRange:tRange ofTrack:self.audioTrack atTime:kCMTimeZero error:&error];
        
    }
    
    self.isFirstChange = YES;
    self.playerItem = [AVPlayerItem playerItemWithAsset:composition];
    self.playerItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
    
    //移除通知
    if (self.player && self.player.currentItem)
    {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    }
    
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    
    NSMutableDictionary *pixBuffAttributes = [NSMutableDictionary dictionary];
    [pixBuffAttributes setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    self.playerItemOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
    [self.playerItem addOutput:self.playerItemOutput];
    //添加通知
    [self addNotification];
    
}

- (instancetype) initWithAsset:(AVAsset *)asset
{
    if(asset != nil)
    {
        preTime = kCMTimeZero;
        self.loopEnable = NO;
        self.assset = asset;
        self.isFisished = NO;
        isPlaying = NO;
        itemCurrentTime = kCMTimeZero;
        NSUInteger degress = 0;
        self.rate = 1.0f;
        NSArray *tracks = [self.assset tracksWithMediaType:AVMediaTypeVideo];
        if([tracks count] > 0)
        {
            self.videoTrack = [tracks objectAtIndex:0];
            CGAffineTransform t = self.videoTrack.preferredTransform;
            
            if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
                // Portrait
                degress = 90;
            }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
                // PortraitUpsideDown
                degress = 270;
            }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
                // LandscapeRight
                degress = 0;
            }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
                // LandscapeLeft
                degress = 180;
            }
        }
        
        float ratio = 0.f;
        if (degress == 0 || degress == 180)
        {
            ratio =  (float)self.videoTrack.naturalSize.height / (float)self.videoTrack.naturalSize.width;//高宽比
            
            self.rat = ratio;
        }
        
        
        self.isFirstChange = YES;
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        self.playerItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
        self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
        
        NSMutableDictionary *pixBuffAttributes = [NSMutableDictionary dictionary];
        [pixBuffAttributes setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        self.playerItemOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
        [self.playerItem addOutput:self.playerItemOutput];
        [self addNotification];
        
        
        return self;
    }
    return nil;
}

//- (BOOL) isFinished
//{
//    CMTime duration = [[self.player currentItem] duration];
//    if((CMTimeCompare(_player.currentItem.currentTime, duration) == 0)
//       && (CMTimeCompare(_player.currentItem.currentTime, kCMTimeZero) != 0))
//    {
//        return YES;
//    }
//    return NO;
//}


#pragma mark  ---------------

-(void)addNotification
{
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
}

-(void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)playbackFinished:(NSNotification *)notification
{
    self.isFisished = YES;
    
    if(self.isFisished)
    {
        self.isFisished = NO;
        
        if(self.loopEnable)
        {
            isPlaying = YES;
            itemCurrentTime = kCMTimeZero;
            [self.player seekToTime:kCMTimeZero];
            [self.player play];
            
        }else if([self.delegate respondsToSelector:@selector(HAVMoviePlayFinish)])
        {
            [self.delegate HAVMoviePlayFinish];
        }
    }
}

- (void) seekToTime:(NSTimeInterval) time
{
    CMTime duration = [[self.player currentItem] duration];
    CMTime seekTime  = CMTimeMake(time*duration.timescale, duration.timescale);
    if (CMTimeCompare(kCMTimeInvalid, seekTime) == 0) {
        seekTime = kCMTimeZero;
    }
    itemCurrentTime = seekTime;
    [self.player seekToTime:seekTime];
    if (use3XMode) {
        [self seekIn3XSpeed:time];
    }
}


- (void) seekToTime:(NSTimeInterval) time withBlock:(void(^)(NSTimeInterval time)) block{
    CMTime duration = [[self.player currentItem] duration];
    CMTime seekTime  = CMTimeMake(time*duration.timescale, duration.timescale);
    itemCurrentTime = seekTime;
    [self.player seekToTime:seekTime completionHandler:^(BOOL finished) {
        if(block){
            block(CMTimeGetSeconds(self.player.currentItem.currentTime));
        }
        self.isFirstChange = YES;
    }];
    if (use3XMode) {
        [self seekIn3XSpeed:time];
    }
    
}
- (void) seekIn3XSpeed:(CGFloat) time{
    
    [self.videoReader cancelReading];
    [self initReader:self.player.currentItem.asset];
    CMTime start = CMTimeMake(time*1000000, 1000000);
    CMTime duration = CMTimeSubtract(self.player.currentItem.asset.duration, start);
    self.videoReader.timeRange = CMTimeRangeMake(start, duration);
    if (self.sampleBuffer) {
        CFRelease(self.sampleBuffer);
        self.sampleBuffer = nil;
    }
    [self.videoReader startReading];
    
    
    accuPTS = CMTimeGetSeconds(start);
    
}

- (CVPixelBufferRef) copyFrameAt3XSpeed:(CMTime)itemTime
{
    
    if(self.videoReaderOutput == nil)
    {
        [self initReader:self.player.currentItem.asset];
        [self.videoReader startReading];
    }
    if (isPaused && self.sampleBuffer)
    {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(self.sampleBuffer);
        CFRetain(pixelBuffer);
        return pixelBuffer;
    }
    //    CGFloat step = 1.0 / self.videoTrack.nominalFrameRate * 3;
    CGFloat step = 1.0 / 30.0 * 3.0;
    while ([self.videoReader status] == AVAssetReaderStatusReading)
    {
        CMSampleBufferRef videoBuffer = [self.videoReaderOutput copyNextSampleBuffer];
        if (videoBuffer)
        {
            
            CGFloat cur = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(videoBuffer));
            if (cur >= accuPTS || !initialized)
            {
                initialized = YES;
                accuPTS += step;
                CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(videoBuffer);
                CFRetain(pixelBuffer);
                if (isPaused)
                {
                    self.sampleBuffer = videoBuffer;
                }
                else
                {
                    CFRelease(videoBuffer);
                }
                return pixelBuffer;
            }
            else
            {
                CFRelease(videoBuffer);
                continue;
            }
        }
    }
    
    return nil;
}


- (CVPixelBufferRef) copyFrameAtTimeRealTimeInFile:(CMTime)itemTime
{
    if (![self.playerItemOutput hasNewPixelBufferForItemTime:itemTime] && self.isFirstChange)
    {
        
        
        self.isFirstChange = NO;
        NSMutableDictionary *pixBuffAttributes = [NSMutableDictionary dictionary];
        [pixBuffAttributes setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        //        self.playerItemOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
        [self.playerItem removeOutput:self.playerItemOutput];
        [self.playerItem addOutput:self.playerItemOutput];
        
        
    }else
    {
        
        CMTime outItemTimeForDisplay;
        CVPixelBufferRef pixelBuffer = [self.playerItemOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:&outItemTimeForDisplay];
        if(CMTimeGetSeconds(outItemTimeForDisplay) >= CMTimeGetSeconds(itemCurrentTime))
        {
            itemCurrentTime = outItemTimeForDisplay;
        }else
        {
            itemCurrentTime = itemTime;
        }
        
        if (CMTIME_IS_VALID(outItemTimeForDisplay))
        {
            return pixelBuffer;
        }else{
            return nil;
        }
        
    }
    return nil;
}

- (void) initReader:(AVAsset *) asset
{
    if(asset != nil)
    {
        NSError *error = nil;
        self.videoReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        self.videoTrack =[videoTracks firstObject];
        //视频播放设置
        int pixelFormatType = kCVPixelFormatType_32BGRA;
        // 其他用途，如视频压缩
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:@(pixelFormatType) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        self.videoReaderOutput = [[HAVAssetReaderOutput alloc] initWithTrack:self.videoTrack outputSettings:options];
        [self.videoReader addOutput:self.videoReaderOutput];
    }
}

- (CVPixelBufferRef) copyFrameAtTimeInFile:(CMTime)time
{
    //    NSLog(@"2xxxxxxxxxself.loopEnable:%d", self.loopEnable);
    if(self.videoReaderOutput == nil)
    {
        [self initReader:self.player.currentItem.asset];
        [self.videoReader startReading]; //1.开始读取
    }
    
    if (self.hasExported)
    {
        self.hasExported = NO;
        [self initReader:self.player.currentItem.asset];
        [self.videoReader startReading]; //1.开始读取
    }
    
    if (!CMTimeCompare(preTime, kCMTimeZero))
    {
        preTime = time;
    }
    
    if (CMTimeCompare(time, preTime) < 0) {
        
        [self initReader:self.player.currentItem.asset];
        [self.videoReader startReading]; //1.开始读取
    }
    preTime = time;
    CVPixelBufferRef buffer =  [self.videoReaderOutput copyPixelBufferForItemTime:time];
    //    NSLog(@"file copy:%f %p", CMTimeGetSeconds(time), buffer);
    if(buffer == NULL){
        //        NSLog(@"1xxxxxxxxxself.loopEnable:%d", self.loopEnable);
        if([self.videoReader status] == AVAssetReaderStatusCompleted){
            [self.videoReader cancelReading];
            self.videoReader = nil;
            if(videoPixelBuffer != NULL){
                CFRelease(videoPixelBuffer);
                videoPixelBuffer = NULL;
            }
        }
    }
    return buffer;
    //    float diff = 1.0 / (self.videoTrack.nominalFrameRate);
    //
    //    if(self.videoReaderOutput == nil){
    //        [self initReader:self.player.currentItem.asset];
    //        [self.videoReader startReading]; //1.开始读取
    //    }
    //
    //    if(videoPixelBuffer != NULL){
    //
    //        ///如果帧的时间戳有效
    //        CMTime  frameTime      = currentFrameTime;
    //        Float64 floattime      = CMTimeGetSeconds(time);
    //        Float64 floatframetime = CMTimeGetSeconds(frameTime);
    //        if(fabs(floattime - floatframetime) < diff){
    //            if(floattime < floatframetime){
    //                CFRetain(videoPixelBuffer);
    //                return videoPixelBuffer;
    //            }
    //        }else if(floattime > floatframetime){
    //            CVPixelBufferRef buffer = videoPixelBuffer;
    //            videoPixelBuffer = NULL;
    //            return buffer;
    //        }
    //        ///丢弃这帧
    //        CFRelease(videoPixelBuffer);
    //        videoPixelBuffer = NULL;
    //    }
    //
    //    //2.读取状态并且正在播放
    //    while ([self.videoReader status] == AVAssetReaderStatusReading && self.videoTrack.nominalFrameRate > 0)
    //    {
    //        //2.1.获取下一个Buffer
    //        CMSampleBufferRef videoBuffer = [self.videoReaderOutput copyNextSampleBuffer];
    //        if(videoBuffer != NULL){
    //            //2.2 PTS主要用于度量解码后的视频帧什么时候被显示出来
    //            CMTime frameTime = CMSampleBufferGetOutputPresentationTimeStamp(videoBuffer);
    //
    //            Float64 floattime = CMTimeGetSeconds(time);
    //            Float64 floatframetime = CMTimeGetSeconds(frameTime);
    //            //nominalFrameRate -------FPS帧频--------
    //            //2.3左边播的快右边没有跟上
    //            if(floattime - floatframetime > diff){
    //                //等
    //                CFRelease(videoBuffer);
    //                continue;
    //            }
    //
    //            if(floatframetime < diff){
    //                CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(videoBuffer);
    //                videoPixelBuffer = pixelBuffer;
    //                currentFrameTime = frameTime;
    //                CFRetain(videoPixelBuffer);
    //                CFRelease(videoBuffer);
    //                CFRetain(videoPixelBuffer);
    //                return pixelBuffer;
    //            }
    //
    //            if(fabs(floattime - floatframetime) < diff ){
    //                CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(videoBuffer);
    //                videoPixelBuffer = pixelBuffer;
    //                currentFrameTime = frameTime;
    //                CFRetain(videoPixelBuffer);
    //                CFRelease(videoBuffer);
    //                if(floattime >= floatframetime ){
    //                    CFRetain(videoPixelBuffer);
    //                    return pixelBuffer;
    //                }else if(floatframetime - floattime < diff){
    //                    CFRetain(videoPixelBuffer);
    //                    return pixelBuffer;
    //
    //                }else {
    //                    break;
    //                }
    //            }
    //        }
    //    }
    //
    //    if([self.videoReader status] == AVAssetReaderStatusCompleted){
    //        [self.videoReader cancelReading];
    //        self.videoReader = nil;
    //        if(videoPixelBuffer != NULL){
    //            CFRelease(videoPixelBuffer);
    //            videoPixelBuffer = NULL;
    //        }
    //    }
    //    return nil;
}

- (CVPixelBufferRef) copyFrameAtTimeInFile2:(CMTime)time
{
    if(self.videoReaderOutput == nil){
        [self initReader:self.player.currentItem.asset];
        [self.videoReader startReading];
    }
    float diff =  0.0f;
    if(self.videoTrack.nominalFrameRate > 0.0f)
    {
        diff = (1.0f /self.videoTrack.nominalFrameRate);
    }else
    {
        diff = (1.0f/30.0f);
    }
    
    if(videoPixelBuffer != NULL){ ///如果帧的时间戳有效
        CMTime frameTime = currentFrameTime;
        Float64 floattime = CMTimeGetSeconds(time);
        Float64 floatframetime = CMTimeGetSeconds(frameTime);
        if(fabs(floattime - floatframetime) < diff){
            if(floattime < floatframetime){
                CFRetain(videoPixelBuffer);
                return videoPixelBuffer;
            }
        }
        ///丢弃这帧书记
        CFRelease(videoPixelBuffer);
        videoPixelBuffer = NULL;
    }
    while ([self.videoReader status] == AVAssetReaderStatusReading && self.videoTrack.nominalFrameRate > 0)
    {
        
        CMSampleBufferRef videoBuffer = [self.videoReaderOutput copyNextSampleBuffer];
        if(videoBuffer != NULL){
            CMTime frameTime = CMSampleBufferGetOutputPresentationTimeStamp(videoBuffer);
            Float64 floattime = CMTimeGetSeconds(time);
            Float64 floatframetime = CMTimeGetSeconds(frameTime);
            if(floattime - floatframetime > diff){
                CFRelease(videoBuffer);
                continue;
            }
            if(floatframetime < diff){
                CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(videoBuffer);
                videoPixelBuffer = pixelBuffer;
                currentFrameTime = frameTime;
                CFRetain(videoPixelBuffer);
                CFRelease(videoBuffer);
                CFRetain(videoPixelBuffer);
                return pixelBuffer;
            }
            if(fabs(floattime - floatframetime) < diff)
            {
                CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(videoBuffer);
                videoPixelBuffer = pixelBuffer;
                currentFrameTime = frameTime;
                CFRetain(videoPixelBuffer);
                CFRelease(videoBuffer);
                if(floattime > floatframetime ){
                    CFRetain(videoPixelBuffer);
                    return pixelBuffer;
                }else{
                    break;
                }
            }
        }
    }
    
    if([self.videoReader status] == AVAssetReaderStatusCompleted)
    {
        [self.videoReader cancelReading];
        self.videoReader = nil;
        if(videoPixelBuffer != NULL){
            CFRelease(videoPixelBuffer);
            videoPixelBuffer = NULL;
        }
    }
    return NULL;
}

-(NSTimeInterval) duration{
    return CMTimeGetSeconds([[self.player currentItem] duration]);
}

- (CVPixelBufferRef) copyFrameAtTime:(CMTime) time
{
    
    if (!use3XMode)
    {
        // CMTime minFrameDuratuon = CMTimeMultiplyByFloat64(self.videoTrack.minFrameDuration, 1/3);
        CMTime realFrameDuration = CMTimeMultiplyByFloat64(self.videoTrack.minFrameDuration, self.rate);///self.rate
        CMTime copyCurrentTime = CMTimeAdd(itemCurrentTime, realFrameDuration);
        
        if((CMTimeGetSeconds(copyCurrentTime) < CMTimeGetSeconds(self.player.currentItem.currentTime)) || !isPlaying)
        {
            copyCurrentTime = self.player.currentItem.currentTime;
        }
        
        //        return self.isWriteFile?[self copyFrameAtTimeInFile:time]:[self copyFrameAtTimeRealTimeInFile : copyCurrentTime];
        
        
        if (self.isInCountDown)
        {
            //Battle页面倒计时时的预览
            return  [self copyFrameAtTimeInFile:copyCurrentTime];
        }
        if (self.isInPreview)
        {
            return self.isWriteFile?[self copyFrameAtTimeInFile:time]:[self copyFrameAtTimeInFile:time];
        }else
        {
            return self.isWriteFile?[self copyFrameAtTimeInFile:time]:[self copyFrameAtTimeRealTimeInFile : copyCurrentTime];
        }
        
        
    }
    else
    {
        return [self copyFrameAt3XSpeed:time];
    }
}

- (NSTimeInterval) currentTime
{
    return CMTimeGetSeconds(itemCurrentTime);
}

- (void)dealloc{
    if(videoPixelBuffer != NULL){
        CFRelease(videoPixelBuffer);
        videoPixelBuffer = NULL;
    }
    [self removeNotification];
}

@end

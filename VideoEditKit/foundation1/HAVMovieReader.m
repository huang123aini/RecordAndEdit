//
//  HAVMovieReader.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVMovieReader.h"
#import "HAVMovieReader.h"
#import "HAVVideoTrack.h"
#import "HAVAudioTrack.h"
#import "AVAsset+MetalData.h"
#import "HAVFileManager.h"
#import "HAVGPUImageMovie.h"
#import "HAVPlayer.h"
#import "HAVPlayerItem.h"
#import <AVFoundation/AVFoundation.h>
#import "HAVLutImageFilter.h"
#import "HAVGPUImageLutFilter.h"
#import "HAVGPULightLutFilter.h"
#import <GPUKit/GPUKit.h>

@interface HAVMovieReader () <HAVPlayerPlayBackDelegate>
{
    CMTime chaseTime;
    BOOL isExportAbort;
    BOOL isSeekInProgress;
    GPUImageRotationMode outputRotation;
    AVPlayerItemStatus playerCurrentItemStatus;
}

@property (nonatomic, strong) HAVPlayer *player;
@property (nonatomic, strong) NSURL * audioUrl;
@property (nonatomic, strong) NSArray *videoUrls;
@property (nonatomic, strong) HAVGPUImageMovie *gpuMovie;
@property (nonatomic, strong) GPUImageMovieWriter *exportMovieWriter;
@property (nonatomic, strong) GPUImageFilterPipeline *exportPipeline;
@property (nonatomic, assign) BOOL showCurrentFrame;
@property (nonatomic, strong) HAVVideoExport *movieExporter;
@property (nonatomic, strong) AVPlayer *player2;
@property (nonatomic, strong) GPUImageMovie *gpuMovie2;
@property (nonatomic, strong) dispatch_queue_t encodingQueue;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) HAVPlayerItem *player1Item;
@property (nonatomic, strong) AVPlayerItem *player2Item;
@property (nonatomic, strong) AVAssetExportSession *exportSession;
@property (nonatomic, weak) id<GPUImageInput> firstFilter;

@end

@implementation HAVMovieReader

- (instancetype) initWithVideURLs:(NSArray *)videoUrls withAudioURL:(NSURL *) audioUrl{
    HAVPlayerItem *playerItem = [[HAVPlayerItem alloc] initWithVideoURL:videoUrls];
    _player = [[HAVPlayer alloc] initWithPlayerItem:playerItem withAudioURL:audioUrl];
    AVAsset *asset = [self getAsset];
    if([asset isKindOfClass:[AVMutableComposition class]]){
        _outComposition = (AVMutableComposition*)asset;
    }
    
    isExportAbort = NO;
    self = [super initWithPlayerItem:playerItem];
    if(self != nil){
        _audioUrl = audioUrl;
        _videoUrls = videoUrls;
        [self initOutputRotation];
    }
    return self;
}

- (instancetype) initWithVideoItems:(NSArray *) videoItems withAudioUrl:(HAVAudioItem *) audioItem{
    AVMutableComposition *composition = [AVMutableComposition composition];
    if(videoItems.count > 0){
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *audioTrack = nil;
        AVMutableCompositionTrack *audioTrack2 = nil;
        AVAssetTrack *songAudioTrack = nil;
        if(audioItem != nil){
            AVAsset *audioAsset = [audioItem getVideoAsset];
            songAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            if(songAudioTrack != nil){
                audioTrack2 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            }
        }
        CMTime offset = kCMTimeZero;
        CMTime audioOffset = kCMTimeZero;
        CGFloat volume = [(HAVVideoItem*)[videoItems firstObject] volume];
        for (HAVVideoItem *videoItem in videoItems)
        {
            volume = videoItem.volume;
            AVAsset *videoAsset = [videoItem getVideoAsset];
            AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
            AVAssetTrack *sourceAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            NSError *error = nil;
            BOOL ok = NO;
            CMTime startTime = kCMTimeZero;
            CMTime trackDuration = [sourceVideoTrack timeRange].duration;
            trackDuration = CMTimeSubtract(trackDuration, startTime);
            CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
            ok = [videoTrack insertTimeRange:tRange ofTrack:sourceVideoTrack atTime:offset error:&error];
            if(sourceAudioTrack != nil)
            {
                if(audioTrack == nil)
                {
                    audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                }
                ok = [audioTrack insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:offset error:&error];
            }
            if((videoItem.rate != 1.0f) && (videoItem.rate != 0.0f)){
                CMTime newDuration = CMTimeMultiplyByFloat64(trackDuration, 1.0f/videoItem.rate);
                CMTime startTime = CMTimeSubtract(composition.duration, trackDuration);
                tRange = CMTimeRangeMake(startTime,trackDuration);
                [videoTrack scaleTimeRange:tRange toDuration:newDuration];
                if(audioTrack != nil){
                    [audioTrack scaleTimeRange:tRange toDuration:newDuration];
                }
                offset = CMTimeAdd(offset, newDuration);
                audioOffset = CMTimeAdd(audioOffset, newDuration);
            }else{
                offset = CMTimeAdd(offset, trackDuration);
                audioOffset = CMTimeAdd(audioOffset, trackDuration);
            }
        }
        AVAsset *audioAsset = [audioItem getVideoAsset];
        songAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        if(songAudioTrack != nil){
            CMTime audioDuration = [audioAsset duration];
            CMTime audioOffset = kCMTimeZero;
            
            while(CMTimeCompare(audioOffset, offset) < 0){
                NSError *error;
                CMTimeRange tRange2 = kCMTimeRangeZero;
                audioOffset = CMTimeAdd(audioOffset, audioDuration);
                if(CMTimeCompare(audioOffset, offset) > 0){
                    CMTime time = CMTimeSubtract(audioOffset, offset);
                    tRange2 = CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(audioDuration, time));
                }else{
                    tRange2 = CMTimeRangeMake(kCMTimeZero, audioDuration);
                }
                [audioTrack2 insertTimeRange:tRange2 ofTrack:songAudioTrack atTime:audioOffset error:&error];
            }
        }
    }
    HAVPlayerItem *playerItem = [[HAVPlayerItem alloc] initWithAsset:composition];
    self = [super initWithPlayerItem:playerItem];
    if(self != nil){
        [self initOutputRotation];
    }
    return self;
}

- (instancetype) initWithVideoItems:(NSArray <HAVVideoItem *> *)videoItems withAudioUrl:(HAVAudioItem *)audioItem timeRange:(CMTimeRange)range{
    
    //确保时间范围有效
    CMTime offset = CMTimeAdd(range.start, range.duration);
    if (CMTimeCompare(offset, kCMTimeZero) == 0 || CMTimeGetSeconds(range.duration) == 0.0) {
        //        NSLog(@"Time range can't be zero!");
        NSAssert(false, @"Time range can't be zero!");
    }
    if (audioItem) {
        AVAsset *asset = [audioItem getVideoAsset];
        if (CMTimeCompare(offset, asset.duration) > 0) {
            //            NSLog(@"Audio time range beyond expectation!");
            NSAssert(false, @"Audio time range beyond expectation!");
        }
    }
#if 0
    {
        CMTime tmp = kCMTimeZero;
        for (HAVVideoItem *videoItem in videoItems){
            
            tmp = CMTimeAdd(tmp, videoItem.scaledDuration);
            
            //==
            AVAsset *asset = [videoItem getVideoAsset];
            AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
            NSLog(@"track.naturalTimeScale:%d track:%@", track.naturalTimeScale, track);
            //==
            NSLog(@"scaled:%f", CMTimeGetSeconds(videoItem.scaledDuration));
        }
        if (CMTimeCompare(offset, tmp) > 0) {
            NSLog(@"Video time range err! src:%f dst:%f", CMTimeGetSeconds(tmp), CMTimeGetSeconds(offset));
            NSAssert(false, @"Video time range err!");
        }
    }
#endif
    BOOL hasExternAudio = false;
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *aCompositionTrack = nil;
    if (audioItem) {
        
        AVAsset *asset = [audioItem getVideoAsset];
        AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        if (track) {
            if (!aCompositionTrack) {
                aCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            }
            [aCompositionTrack insertTimeRange:range ofTrack:track atTime:kCMTimeZero error:nil];
            NSLog(@"aCompositionTrack:%@ range duration:%f", aCompositionTrack, CMTimeGetSeconds(range.duration));
            hasExternAudio = true;
        }
    }
    
    CMTime tmpCu = kCMTimeZero;
    AVMutableCompositionTrack *vCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    for (HAVVideoItem *videoItem in videoItems){
        AVAsset *asset = [videoItem getVideoAsset];
        AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        
        
        [vCompositionTrack insertTimeRange:videoTrack.timeRange ofTrack:videoTrack atTime:tmpCu error:nil];
        if (videoItem.rate != 1.0 && videoItem.rate != 0.0) {
            CMTimeRange r = CMTimeRangeMake(tmpCu, videoTrack.timeRange.duration);
            NSLog(@"video scale:%f", CMTimeGetSeconds(videoItem.scaledDuration));
            [vCompositionTrack scaleTimeRange:r toDuration:videoItem.scaledDuration];
        }
        
        if (!hasExternAudio && audioTrack) {
            if (!aCompositionTrack) {
                aCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            }
            [aCompositionTrack insertTimeRange:audioTrack.timeRange ofTrack:audioTrack atTime:tmpCu error:nil];
            if (videoItem.rate != 1.0 && videoItem.rate != 0.0) {
                CMTimeRange r = CMTimeRangeMake(tmpCu, audioTrack.timeRange.duration);
                [aCompositionTrack scaleTimeRange:r toDuration:videoItem.scaledDuration];
            }
            
        }
        
        tmpCu = CMTimeAdd(tmpCu, videoItem.scaledDuration);
        
    }
    [vCompositionTrack removeTimeRange:CMTimeRangeMake(kCMTimeZero, range.start)];
    if (aCompositionTrack) {
        [aCompositionTrack removeTimeRange:CMTimeRangeMake(kCMTimeZero, range.start)];
    }
    
    CMTime off = CMTimeAdd(range.start, range.duration);
    CMTimeRange r = CMTimeRangeMake(off, CMTimeSubtract(tmpCu, off));
    [vCompositionTrack removeTimeRange:r];
    if (aCompositionTrack) {
        [aCompositionTrack removeTimeRange:r];
    }
    
    NSLog(@"durationxx:%f", CMTimeGetSeconds(composition.duration));
#if 0
    {
        
        AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPreset640x480];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:@"xx.mov"];
        [[NSFileManager defaultManager] removeItemAtPath:myPathDocs error:nil];
        session.outputURL = [NSURL fileURLWithPath:myPathDocs];
        session.outputFileType = AVFileTypeQuickTimeMovie;
        [session exportAsynchronouslyWithCompletionHandler:^{
            int exportStatus = session.status;
            switch (exportStatus) {
                case AVAssetExportSessionStatusCompleted:{
                    NSLog(@"finished.");
                }
                    break;
                case AVAssetExportSessionStatusFailed:
                case AVAssetExportSessionStatusUnknown:
                case AVAssetExportSessionStatusExporting:
                case AVAssetExportSessionStatusCancelled:
                case AVAssetExportSessionStatusWaiting:
                default:  {
                    NSLog(@"error:%@", session.error.localizedDescription);
                }
                    break;
            }
        }];
    }
#endif
    
    HAVPlayerItem *playerItem = [[HAVPlayerItem alloc] initWithAsset:composition];
    _outComposition = composition;
    _player = [[HAVPlayer alloc] initWithPlayerItem:playerItem];
    playerItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
    self = [super initWithPlayerItem:playerItem];
    if(self != nil){
        [self initOutputRotation];
    }
    return self;
}

- (void) setPlayLoopDelegate:(id<HAVPlayerPlayBackDelegate>) delegate{
    self.player.delegate = delegate;
}

- (instancetype) initWithExport:(HAVVideoExport *) avexport{
    HAVPlayerItem *playerItem = [[HAVPlayerItem alloc] initWithAsset:avexport.asset];
    self = [super initWithPlayerItem:playerItem];
    if(self != nil){
        [self initOutputRotation];
        self.movieExporter = avexport;
    }
    return self;
}

- (instancetype) initWithVideItem:(NSArray *)videoItems WithAudioUrl:(NSURL *) audioUrl;{
    HAVPlayerItem *playerItem = [[HAVPlayerItem alloc] initWithVideoItem:videoItems audioUrl:audioUrl];
    _player = [[HAVPlayer alloc] initWithPlayerItem:playerItem withAudioURL:nil];
    self = [super initWithPlayerItem:playerItem];
    if(self != nil){
        _audioUrl = audioUrl;
        _videoUrls = videoItems;
        [self initOutputRotation];
    }
    return self;
}

- (void) setShowFirstFrame:(BOOL)showFirstFrame{
    _showFirstFrame = showFirstFrame;
    if(showFirstFrame){
        [self startProcessing];
    }
}

- (AVAsset *) getAsset{
    AVAsset *asset;
    AVPlayerItem *playerItem = [self.player currentItem];
    if((playerItem != nil) && ([playerItem isKindOfClass:HAVPlayerItem.class])){
        HAVPlayerItem *qPlayerItem = (HAVPlayerItem*)playerItem;
        asset = [qPlayerItem asset];
    }else{
        asset = [self getReaderAsset];
    }
    return asset;
}

- (void) initOutputRotation{
    self.firstFilter = nil;
    outputRotation = kGPUImageNoRotation;
    NSArray *tracks = [[self getAsset] tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;//这里的矩阵有旋转角度，转换一下即可
        //      NSUInteger degress = 0;
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
            // degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            outputRotation = kGPUImageRotate180;
            // degress = 180;
        }
    }
}

- (NSURL *) getVideoUrl{
    return [self.videoUrls firstObject];
}

- (CGSize) getFixedVideoSize{
    if(self.movieExporter != nil){
        return [self.movieExporter getVideoSize];
    }
    return [self getVideoSize];
}

- (void) seekPause:(NSTimeInterval) time{
    [self seek:time];
    [self pause];
}

- (CGSize) getVideoSize{
    CGSize size =  [[self getAsset] videoNaturalSize];
    if((outputRotation ==kGPUImageRotateLeft) || (outputRotation ==kGPUImageRotateRight)){
        size = CGSizeMake(size.height, size.width);
    }
    return size;
}


- (AVAsset *) getReaderAsset{
    AVMutableComposition *composition = [AVMutableComposition composition];
    NSMutableArray *audioMixParams = [[NSMutableArray alloc] init];
    
    if (self.videoUrls.count > 0){
        HAVVideoTrack * _videoTrack = [[HAVVideoTrack alloc] init];
        for (NSURL *url in self.videoUrls){
            [_videoTrack addVideoAsset:url];
        }
        /** 给多个 video 添加到同一轨道**/
        if(_videoTrack != nil){
            [_videoTrack addToComposition:composition];
            NSArray *array = [_videoTrack getAudioMixInputParameters];
            if(array.count > 0){
                [audioMixParams addObjectsFromArray:array];
            }
        }
    }
    CMTime offset = kCMTimeZero;
    /** 给每一个audio 添加到一个轨道**/
    if(self.audioUrl != nil){
        HAVAudioTrack *audioTrack = [[HAVAudioTrack alloc] init];
        [audioTrack setAudioAssetUrl:self.audioUrl];
        AVMutableAudioMixInputParameters *inputParameters = [audioTrack createAudioMixInputParameters:composition atOffsetTime:offset];
        if(inputParameters != nil){
            [audioMixParams addObject:inputParameters];
        }
    }
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
    return composition;
}

- (void) exportVideo:(NSString *)outpath videoSize:(HAVVideoSize) avVideoSize withVideoUrls:(NSArray *) urls withAudioUrl:(NSURL *) url withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler{
    if(outpath != nil){
        AVMutableComposition *composition = [AVMutableComposition composition];
        NSMutableArray *audioMixParams = [[NSMutableArray alloc] init];
        HAVVideoTrack * _videoTrack = [[HAVVideoTrack alloc] init];
        if (urls.count > 0){
            _videoTrack.volume = [self.player getVideoVolume];
            for (NSURL *url in urls){
                [_videoTrack addVideoAsset:url];
            }
            /** 给多个 video 添加到同一轨道**/
            if(_videoTrack != nil){
                [_videoTrack addToComposition:composition];
                NSArray *array = [_videoTrack getAudioMixInputParameters];
                if(array.count > 0){
                    [audioMixParams addObjectsFromArray:array];
                }
            }
        }
        //CMTime offset = kCMTimeZero;
        /** 给每一个audio 添加到一个轨道**/
        if(url != nil){
            HAVAudioTrack *audioTrack = [[HAVAudioTrack alloc] init];
            audioTrack.volume = [self.player getAudioVolume];
            [audioTrack setAudioAssetUrl:url];
            AVMutableAudioMixInputParameters *inputParameters = [audioTrack createAudioMixInputParameters:composition];
            if(inputParameters != nil){
                [audioMixParams addObject:inputParameters];
            }
            
        }
        
        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                          initWithAsset: composition
                                          presetName: [_videoTrack videoSizeToPreset:avVideoSize]];
        exporter.audioMix = audioMix;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        
        /** 导出的文件存在即删除**/
        if ([[NSFileManager defaultManager] fileExistsAtPath:outpath]) {
            [[NSFileManager defaultManager] removeItemAtPath:outpath error:nil];
        }
        NSURL *exportURL = [NSURL fileURLWithPath:outpath];
        exporter.outputURL = exportURL;
        if( _videoTrack != nil && CMTimeCompare([ _videoTrack duration] , kCMTimeZero ) > 0){
            exporter.timeRange = CMTimeRangeMake(kCMTimeZero, [_videoTrack duration]);
        }
        exporter.shouldOptimizeForNetworkUse = YES;
        
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            int exportStatus = exporter.status;
            switch (exportStatus) {
                case AVAssetExportSessionStatusCompleted:{
                    handler(YES, outpath, exporter.error);
                }
                    break;
                case AVAssetExportSessionStatusFailed:
                case AVAssetExportSessionStatusUnknown:
                case AVAssetExportSessionStatusExporting:
                case AVAssetExportSessionStatusCancelled:
                case AVAssetExportSessionStatusWaiting:
                default:{
                    handler(NO, outpath, exporter.error);
                }
                    break;
            }
        }];
    }else{
        NSDictionary *dic = [NSDictionary dictionaryWithObject:@"export file path is empty" forKey:@"error"];
        NSError *error = [NSError errorWithDomain:@"export file path is empty" code:-1 userInfo:dic];
        handler(NO, outpath, error);
    }
    
}

- (CGSize) translateVideoSize:(CGSize) size{
    if((outputRotation == kGPUImageRotateLeft) || (outputRotation == kGPUImageRotateRight)){
        size = CGSizeMake(size.height, size.width);
    }
    return size;
}

- (void) saveVideoToPath:(NSString *) path withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler{
    [self exportVideo:path videoSize: HAVVideoSizeNature withVideoUrls:self.videoUrls withAudioUrl:self.audioUrl withHandler:handler];
}

- (void) saveVideoToPath:(NSString *) path videoSize:(HAVVideoSize) videoSize withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler{
    [self exportVideo:path videoSize: videoSize withVideoUrls:self.videoUrls withAudioUrl:self.audioUrl withHandler:handler];
}

- (void) releasePipeLineFilters:(GPUImageFilterPipeline *) pipeLine{
    for (GPUImageFilter * filter in pipeLine.filters){
        if([filter isKindOfClass:[HAVLutImageFilter class]]){
            HAVLutImageFilter *auxFilter = (HAVLutImageFilter*) filter;
            [auxFilter releaseFilter];
        }
    }
}

- (void) exportVideo:(NSString *) outPath videoSize:(HAVVideoSize) avVideoSize bitRate:(NSInteger) bitRate withFilters:(NSArray *) filters asset:(AVAsset *)inputAsset withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler{
    
    BOOL hasAudio = ([[inputAsset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
    BOOL forceFps = ([[[inputAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] nominalFrameRate] > 50);
    if(outPath != nil){
        [HAVFileManager removeTmpFile:outPath];
        NSURL *url  = [NSURL fileURLWithPath:outPath];
        CGSize videoSize = [inputAsset videoSize:avVideoSize];
        videoSize = [self translateVideoSize:videoSize];
        if(url != nil){
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,@(videoSize.width),AVVideoWidthKey,@(videoSize.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                           @(bitRate),AVVideoAverageBitRateKey,
                                                           @(30),AVVideoMaxKeyFrameIntervalKey,
                                                           AVVideoProfileLevelH264High40,AVVideoProfileLevelKey, nil];
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            
            self.exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            self.exportMovieWriter.forceFps = forceFps;
            if(inputAsset != nil){
                self.gpuMovie = [[HAVGPUImageMovie alloc] initWithAsset:inputAsset];
                self.gpuMovie.playAtActualSpeed = NO;
                
                self.gpuMovie.audioEncodingTarget = hasAudio?self.exportMovieWriter:nil;
                self.exportMovieWriter.hasAudioTrack = hasAudio;
                self.exportMovieWriter.encodingLiveVideo = YES;
                [self.gpuMovie enableSynchronizedEncodingUsingMovieWriter:self.exportMovieWriter];
                self.exportPipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:filters input:self.gpuMovie output:self.exportMovieWriter];
                __block GPUImageFilterPipeline *pipeLine = self.exportPipeline;
                __block GPUImageMovieWriter *movieWritter = self.exportMovieWriter;
                __block GPUImageMovie *movieFile = self.gpuMovie;
                [self.exportMovieWriter setCompletionBlock:^{
                    for (GPUImageFilter * filter in pipeLine.filters){
                        if([filter isKindOfClass:[HAVLutImageFilter class]]){
                            HAVLutImageFilter *auxFilter = (HAVLutImageFilter*) filter;
                            [auxFilter releaseFilter];
                        }
                    }
                    [pipeLine removeAllFilters];
                    [movieFile endProcessing];
                    [movieWritter finishRecordingWithCompletionHandler:^{
                        [movieWritter setFailureBlock:nil];
                        [movieWritter setCompletionBlock:nil];
                        if(handler != nil){
                            handler(YES, outPath, nil);
                        }
                    }];
                }];
                [self.exportMovieWriter setFailureBlock:^(NSError *err){
                    NSLog(@"setFailureBlock failed!");
                    handler(NO, outPath, err);
                    [movieWritter setCompletionBlock:nil];
                    [movieWritter setFailureBlock:nil];
                }];
                [self.exportMovieWriter startRecording];
                [self.gpuMovie startProcessing];
            }else{
                NSError *error = [NSError errorWithDomain:@"asset error" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"asset error" forKey:@"error"]];
                handler(NO , outPath, error);
            }
        }else{
            NSError *error = [NSError errorWithDomain:@"tmp path url error" code:-2 userInfo:[NSDictionary dictionaryWithObject:@"tmp path url error" forKey:@"error"]];
            handler(NO , outPath, error);
        }
    }else{
        NSError *error = [NSError errorWithDomain:@"tmp path error" code:-3 userInfo:[NSDictionary dictionaryWithObject:@"tmp path error" forKey:@"error"]];
        handler(NO , outPath, error);
    }
}

- (void) exportVideo2:(NSString *) outPath videoSize:(HAVVideoSize) avVideoSize bitRate:(NSInteger) bitRate withFilters:(NSArray *) exportFilters asset:(AVAsset *)inputAsset iFrameFlag:(BOOL)iFrameFlag withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler{
    
    BOOL hasAudio = ([[inputAsset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
    BOOL forceFps = ([[[inputAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] nominalFrameRate] > 50);
    if(outPath != nil){
        [HAVFileManager removeTmpFile:outPath];
        NSURL *url  = [NSURL fileURLWithPath:outPath];
        CGSize videoSize = [inputAsset videoSize:avVideoSize];
        videoSize = [self translateVideoSize:videoSize];
        if(url != nil){
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,@(videoSize.width),AVVideoWidthKey,@(videoSize.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary *compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                          @(bitRate),AVVideoAverageBitRateKey,AVVideoProfileLevelH264High40,AVVideoProfileLevelKey, nil];
            if (iFrameFlag) {
                [compressionProperties setObject:@(1) forKey:AVVideoMaxKeyFrameIntervalKey];
            }
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            
            self.exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            self.exportMovieWriter.forceFps = forceFps;
            if(forceFps){
                self.exportMovieWriter.fps = 31;
            }
            if(inputAsset != nil){
                self.gpuMovie = [[HAVGPUImageMovie alloc] initWithAsset:inputAsset];
                [self.gpuMovie setOutputRotation:outputRotation];
                self.gpuMovie.playAtActualSpeed = NO;
                
                self.gpuMovie.audioEncodingTarget = hasAudio?self.exportMovieWriter:nil;
                self.exportMovieWriter.hasAudioTrack = hasAudio;
                self.exportMovieWriter.encodingLiveVideo = YES;
                [self.gpuMovie enableSynchronizedEncodingUsingMovieWriter:self.exportMovieWriter];
                NSMutableArray *filters = [NSMutableArray array];
                
                if(exportFilters != nil){
                    [filters addObjectsFromArray:exportFilters];
                }
                self.exportPipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:filters input:self.gpuMovie output:self.exportMovieWriter];
                __block GPUImageFilterPipeline *pipeLine = self.exportPipeline;
                __block GPUImageMovieWriter *movieWritter = self.exportMovieWriter;
                self.gpuMovie.shouldRepeat = NO;
                __block GPUImageMovie *movieFile = self.gpuMovie;
                [self.exportMovieWriter setCompletionBlock:^{
                    for (GPUImageFilter * filter in pipeLine.filters){
                        if([filter isKindOfClass:[HAVLutImageFilter class]]){
                            HAVLutImageFilter *auxFilter = (HAVLutImageFilter*) filter;
                            [auxFilter releaseFilter];
                        }
                        else if([filter isKindOfClass:[HAVGPUImageLutFilter class]]){
                            HAVGPUImageLutFilter *auxFilter = (HAVGPUImageLutFilter*) filter;
                            [auxFilter releaseFilter];
                        }
                        else if([filter isKindOfClass:[HAVGPULightLutFilter class]]){
                            HAVGPULightLutFilter *auxFilter = (HAVGPULightLutFilter*) filter;
                            [auxFilter releaseFilter];
                        }
                    }
                    [pipeLine removeAllFilters];
                    [movieFile cancelProcessing];
                    [movieWritter finishRecordingWithCompletionHandler:^{
                        [movieWritter setFailureBlock:nil];
                        [movieWritter setCompletionBlock:nil];
                        if(handler != nil){
                            handler(YES, outPath, nil);
                        }
                    }];
                    
                }];
                [self.exportMovieWriter setFailureBlock:^(NSError *err){
                    NSLog(@"setFailureBlock failed!");
                    handler(NO, outPath, err);
                    [movieWritter setCompletionBlock:nil];
                    [movieWritter setFailureBlock:nil];
                }];
                [self.exportMovieWriter startRecording];
                [self.gpuMovie startProcessing];
            }else{
                NSError *error = [NSError errorWithDomain:@"asset error" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"asset error" forKey:@"error"]];
                handler(NO , outPath, error);
            }
        }else{
            NSError *error = [NSError errorWithDomain:@"tmp path url error" code:-2 userInfo:[NSDictionary dictionaryWithObject:@"tmp path url error" forKey:@"error"]];
            handler(NO , outPath, error);
        }
    }else{
        NSError *error = [NSError errorWithDomain:@"tmp path error" code:-3 userInfo:[NSDictionary dictionaryWithObject:@"tmp path error" forKey:@"error"]];
        handler(NO , outPath, error);
    }
}

- (void) saveVideoToPath:(NSString *) outPath bitRate:(NSInteger) bitRate videoSize:(HAVVideoSize) videoSize withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler{
    [self exportVideo2:outPath videoSize:videoSize bitRate:bitRate withFilters:filters asset:[self getAsset] iFrameFlag:NO withHandler:handler];
}

- (void) saveVideoToPath:(NSString *) outPath bitRate:(NSInteger) bitRate withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler{
    [self exportVideo2:outPath videoSize:HAVVideoSize540p bitRate:bitRate withFilters:filters asset:[self getAsset] iFrameFlag:NO withHandler:handler];
}

- (void) saveVideoToPathWithIFrame:(NSString *) outPath bitRate:(NSInteger) bitRate videoSize:(HAVVideoSize) videoSize withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler{
    [self exportVideo2:outPath videoSize:videoSize bitRate:bitRate withFilters:filters asset:[self getAsset] iFrameFlag:YES withHandler:handler];
}


- (void) saveVideoToPathWithIFrame:(NSString *) outPath bitRate:(NSInteger) bitRate withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler{
    [self exportVideo2:outPath videoSize:HAVVideoSizeNature bitRate:bitRate withFilters:filters asset:[self getAsset] iFrameFlag:YES withHandler:handler];
}

- (void) saveVideoToPathWithIFrame:(NSString *) outPath withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler{
    AVAsset *asset = [self getAsset];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    float bitRate = [videoTrack estimatedDataRate];
    [self exportVideo2:outPath videoSize:HAVVideoSizeNature bitRate:bitRate withFilters:filters asset:asset iFrameFlag:YES withHandler:handler];
}


- (void) saveVideoWithTimeEffect:(NSString *) outPath bitRate:(NSInteger) bitRate withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler{
    [self exportVideo2:outPath videoSize:HAVVideoSizeNature bitRate:bitRate withFilters:filters asset:_outComposition iFrameFlag:NO withHandler:handler];
}

- (void) setAudioURL:(NSURL *) audioUrl{
    _audioUrl = audioUrl;
    [self.player setAudioURL:audioUrl];
}

- (void) restart{
    [self.player restart];
}

- (void) stop{
    [self.player pause];
}

- (void) pause{
    [self.player pause];
}

- (CMTime) frameDuration{
    NSArray *tracks = [[self getAsset] tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        return [videoTrack minFrameDuration];
    }
    return kCMTimeInvalid;
}

- (void) seek:(NSTimeInterval) time{
    CMTime seekTime = CMTimeMake(time*1000000000, 1000000000);
    [self.player seekToTime:seekTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    if (self.player2) {
        [self.player2 seekToTime:seekTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

- (void) seek:(NSTimeInterval) time completionHandler:(void (^)(BOOL finished))completionHandler{
    CMTime seekTime = CMTimeMake(time*1000000000, 1000000000);
    [self.player seekToTime:seekTime completionHandler:^(BOOL finished) {
        if(finished){
            if (self.player2) {
                [self.player2 seekToTime:seekTime completionHandler:completionHandler];
            }
        }
    }];
}

- (void) seekToTime:(NSTimeInterval) time{
    CMTime seekTime = CMTimeMake(time*1000000000, 1000000000);
    [self.player seekToTime2:seekTime];
    if (self.player2) {
        [self.player2 seekToTime:seekTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

- (void)seekSmoothlyToTime:(CMTime)newChaseTime
{
    [self.player pause];
    if (self.player2) {
        [self.player2 pause];
    }
    
    if (CMTIME_COMPARE_INLINE(newChaseTime, !=, self->chaseTime))
    {
        self->chaseTime = newChaseTime;
        
        if (!self->isSeekInProgress)
            [self trySeekToChaseTime];
    }
}

- (void)trySeekToChaseTime
{
    if (playerCurrentItemStatus == AVPlayerItemStatusUnknown)
    {
        // wait until item becomes ready (KVO player.currentItem.status)
    }
    else if (playerCurrentItemStatus == AVPlayerItemStatusReadyToPlay)
    {
        [self actuallySeekToTime];
    }
}

- (void)actuallySeekToTime
{
    self->isSeekInProgress = YES;
    CMTime seekTimeInProgress = self->chaseTime;
    [self.player seekToTime:seekTimeInProgress toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero completionHandler:
     ^(BOOL isFinished)
     {
         if (CMTIME_COMPARE_INLINE(seekTimeInProgress, ==, self->chaseTime))
             self->isSeekInProgress = NO;
         else
             [self trySeekToChaseTime];
     }];
}

- (CMTime) currentTime{
    return [self.player currentTime];
}

- (void) setAudioFilePath:(NSString *) filePath{
    if(filePath.length > 0){
        NSURL *audioUrl = [NSURL fileURLWithPath:filePath];
        [self setAudioURL:audioUrl];
    }
}

- (void) setLoopEnable:(BOOL) loop{
    //    [self.player setLoopEnable:loop];
    self.player.enableRepeat = loop;
}

- (void) setAudioVolume:(CGFloat) volume{
    [self.player setAudioVolume:volume];
}

- (void) setVideoVolume:(CGFloat) volume{
    [self.player setVideoVolume:volume];
}

- (void) audioPlay{
    [self.player audioPlay];
}

- (void) audioPause{
    [self.player audioPause];
}

- (void) muted:(BOOL) mute{
    [self.player setMuted:mute];
    if (self.player2) {
        [self.player2 setMuted:YES];
    }
}

- (void) startProcessing{
    
    self.player.rate = 1.f;
    
    [self.player play];
    if (self.player2) {
        [self.player2 play];
    }
    [super startProcessing];
}

- (void)endProcessing{
    [self.exportSession cancelExport];
    
    [self.player pause];
    if (self.player2) {
        [self.player2 pause];
    }
    [super endProcessing];
}

- (void)cancelProcessing{
    [self.player pause];
    [super cancelProcessing];
}

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    self.firstFilter = newTarget;
    [super addTarget:newTarget atTextureLocation:textureLocation];
    [newTarget setInputRotation:outputRotation atIndex:textureLocation];
}

- (VideoRotation) videoRotation{
    VideoRotation rotation = Rotation0;
    switch (outputRotation) {
        case kGPUImageNoRotation:
            rotation = Rotation0;
            break;
        case kGPUImageRotateRight:
            rotation = Rotation90;
            break;
        case kGPUImageRotate180:
            rotation = Rotation180;
            break;
        case kGPUImageRotateLeft:
            rotation = Rotation270;
            break;
        default:
            break;
    }
    return rotation;
}

- (void) setVideoRotation:(VideoRotation) rotation{
    switch (rotation) {
        case Rotation0:
            outputRotation = kGPUImageNoRotation;
            break;
        case Rotation90:
            outputRotation = kGPUImageRotateRight;
            break;
        case Rotation180:
            outputRotation = kGPUImageRotate180;
            break;
        case Rotation270:
            outputRotation = kGPUImageRotateLeft;
            break;
        default:
            break;
    }
    [self.firstFilter setInputRotation:outputRotation atIndex:0];
}

- (instancetype) initWithTimeRangeSlow:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl timeRange:(CMTimeRange)range slowRatio:(NSInteger)slowRatio{
    
    AVAsset *assetAudio = audioUrl ? [AVAsset assetWithURL:audioUrl] : nil;
    AVAsset *assetVideo = [AVAsset assetWithURL:videoUrl];
    
    AVAssetTrack *assetTrackAudio = assetAudio ? [[assetAudio tracksWithMediaType:AVMediaTypeAudio] lastObject] : nil;
    AVAssetTrack *assetTrackVideo = [[assetVideo tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    _outComposition = [[AVMutableComposition alloc] init];
    
    AVMutableCompositionTrack *vTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    vTrack.preferredTransform = assetTrackVideo.preferredTransform;
    [vTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetVideo.duration) ofTrack:assetTrackVideo atTime:kCMTimeZero error:nil];
    
    CMTime last = slowRatio > 0 ? CMTimeMultiply(range.duration, (int32_t)slowRatio) : CMTimeMake(3, 1);
    [vTrack scaleTimeRange:range toDuration:last];
    
    if (assetAudio) {
        AVMutableCompositionTrack *aTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        int64_t aDur = CMTimeGetSeconds(assetVideo.duration) + (CMTimeGetSeconds(last) - CMTimeGetSeconds(range.duration));
        [aTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(aDur, 1)) ofTrack:assetTrackAudio atTime:kCMTimeZero error:nil];
    }
    
    HAVPlayerItem *playerItem = [[HAVPlayerItem alloc] initWithAsset:_outComposition];
    _player = [[HAVPlayer alloc] initWithPlayerItem:playerItem];
    
    self = [super initWithPlayerItem:playerItem];
    if(self != nil){
        [self initOutputRotation];
    }
    return self;
}

- (instancetype) initWithTimeRangeRepeat:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl timeRange:(CMTimeRange)range repeatTimes:(NSInteger)times{
    
    AVAsset *assetAudio = audioUrl ? [AVAsset assetWithURL:audioUrl] : nil;
    AVAsset *assetVideo = [AVAsset assetWithURL:videoUrl];
    
    AVAssetTrack *assetTrackAudio = assetAudio ? [[assetAudio tracksWithMediaType:AVMediaTypeAudio] lastObject] : nil;
    AVAssetTrack *assetTrackVideo = [[assetVideo tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    _outComposition = [[AVMutableComposition alloc] init];
    
    AVMutableCompositionTrack *vTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    vTrack.preferredTransform = assetTrackVideo.preferredTransform;
    CMTime offset = range.start;
    [vTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, range.start) ofTrack:assetTrackVideo atTime:kCMTimeZero error:nil];
    
    for (int i = 0; i < times; i++) {
        [vTrack insertTimeRange:range ofTrack:assetTrackVideo atTime:offset error:nil];
        offset = CMTimeAdd(offset, range.duration);
    }
    int64_t ext = times > 1 ? (times - 1) * CMTimeGetSeconds(range.duration) : 0;
    
    [vTrack insertTimeRange:CMTimeRangeMake(CMTimeAdd(range.start, range.duration), CMTimeSubtract(assetVideo.duration, CMTimeAdd(range.start, range.duration))) ofTrack:assetTrackVideo atTime:offset error:nil];
    
    if (assetAudio) {
        AVMutableCompositionTrack *aTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [aTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(assetVideo.duration, CMTimeMake(ext, 1))) ofTrack:assetTrackAudio atTime:kCMTimeZero error:nil];
    }
    
    HAVPlayerItem *playerItem = [[HAVPlayerItem alloc] initWithAsset:_outComposition];
    _player = [[HAVPlayer alloc] initWithPlayerItem:playerItem];
    self = [super initWithPlayerItem:playerItem];
    if(self != nil){
        [self initOutputRotation];
    }
    return self;
}

- (instancetype) initWithFileTimeRange:(NSURL *)url audioUrl:(NSURL *)audioUrl withAudioTimeRange:(CMTimeRange)range{
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    self.audioUrl = url;
    AVAsset *assetAudio = [AVAsset assetWithURL:audioUrl];
    AVAssetTrack *assetTrackAudioExternal = [[assetAudio tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    AVAssetTrack *assetTrackAudio = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    AVAssetTrack *assetTrackVideo = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    CMTime duration = asset.duration;
    
    _outComposition = [[AVMutableComposition alloc] init];
    
    CMTime dur = CMTimeCompare(range.duration, duration) > 0 ? duration : range.duration;
    CMTimeRange r = CMTimeRangeMake(range.start, dur);
    
    if (assetTrackVideo) {
        AVMutableCompositionTrack *vTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        vTrack.preferredTransform = assetTrackVideo.preferredTransform;
        
        [vTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration) ofTrack:assetTrackVideo atTime:kCMTimeZero error:nil];
    }
    
    if (audioUrl) {
        AVMutableCompositionTrack *aTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [aTrack insertTimeRange:r ofTrack:assetTrackAudioExternal atTime:kCMTimeZero error:nil];
    }else if (assetTrackAudio != nil){
        AVMutableCompositionTrack *aTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [aTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration) ofTrack:assetTrackAudio atTime:kCMTimeZero error:nil];
    }
    
    HAVPlayerItem *playerItem = [[HAVPlayerItem alloc] initWithAsset:_outComposition];
    
    _player = [[HAVPlayer alloc] initWithPlayerItem:playerItem];
    self = [super initWithPlayerItem:playerItem];
    if(self != nil){
        [self initOutputRotation];
    }
    return self;
}

- (instancetype) initWithPlaySpeed:(NSURL *)url speed:(CGFloat)speed{
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetTrack *assetTrackAudio = [[asset tracksWithMediaType:AVMediaTypeAudio] lastObject];
    AVAssetTrack *assetTrackVideo = [[asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    //    CGFloat tmp = CMTimeGetSeconds(asset.duration) * speed;
    //    CMTime dur = CMTimeMake((int64_t)(tmp*1000), 1000);
    
    CMTime dur = CMTimeMultiplyByFloat64(asset.duration, speed);
    
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, asset.duration);
    _outComposition = [[AVMutableComposition alloc] init];
    
    
    if (assetTrackAudio) {
        AVMutableCompositionTrack *aTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [aTrack insertTimeRange:range ofTrack:assetTrackAudio atTime:kCMTimeZero error:nil];
        [aTrack scaleTimeRange:range toDuration:dur];
        
        [self playWithAsset:_outComposition];
    }
    
    if (assetTrackVideo) {
        AVMutableCompositionTrack *vTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        vTrack.preferredTransform = assetTrackVideo.preferredTransform;
        [vTrack insertTimeRange:range ofTrack:assetTrackVideo atTime:kCMTimeZero error:nil];
        [vTrack scaleTimeRange:range toDuration:dur];
    }
    [self initPlayer];
    self = [super initWithPlayerItem:self.player1Item];
    if(self != nil){
        [self initOutputRotation];
    }
    
    return self;
}
- (instancetype) initAfterSpeedWithRange:(CMTimeRange)range instance:(id)instance handler:(void (^)(void)) handler{
    if (!instance) {
        NSLog(@"======================= instance is null");
        return nil;
    }
    
    HAVMovieReader *avc = instance;
    AVAsset *asset = avc.outComposition;
    if (!asset) {
        NSLog(@"======================= asset is null");
        return nil;
    }
    AVAssetTrack *assetTrackAudio = [[asset tracksWithMediaType:AVMediaTypeAudio] lastObject];
    AVAssetTrack *assetTrackVideo = [[asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    _outComposition = [[AVMutableComposition alloc] init];
    
    CMTime start = CMTimeMake(CMTimeGetSeconds(range.start)*1000, 1000);
    CMTime duration = CMTimeMake(CMTimeGetSeconds(range.duration)*1000, 1000);
    CMTime endt = CMTimeAdd(start, duration);
    //    CMTime endt = CMTimeAdd(range.start, range.duration);
    if (CMTimeCompare(endt, asset.duration) > 0) {
        NSLog(@"======================= unsupported range(%f:%f)", CMTimeGetSeconds(endt), CMTimeGetSeconds(asset.duration));
        return nil;
    }
    
    if (assetTrackAudio) {
        AVMutableCompositionTrack *aTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [aTrack insertTimeRange:range ofTrack:assetTrackAudio atTime:kCMTimeZero error:nil];
        [self playWithAsset:_outComposition block:handler];
    }
    if (assetTrackVideo) {
        AVMutableCompositionTrack *vTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        vTrack.preferredTransform = assetTrackVideo.preferredTransform;
        [vTrack insertTimeRange:range ofTrack:assetTrackVideo atTime:kCMTimeZero error:nil];
    }
    
    [self initPlayer];
    self = [super initWithPlayerItem:self.player1Item];
    if(self != nil){
        [self initOutputRotation];
    }
    return self;
}
- (instancetype) initAfterSpeedWithRange:(CMTimeRange)range instance:(id)instance{
    
    if (!instance) {
        NSLog(@"======================= instance is null");
        return nil;
    }
    
    HAVMovieReader *avc = instance;
    AVAsset *asset = avc.outComposition;
    if (!asset) {
        NSLog(@"======================= asset is null");
        return nil;
    }
    AVAssetTrack *assetTrackAudio = [[asset tracksWithMediaType:AVMediaTypeAudio] lastObject];
    AVAssetTrack *assetTrackVideo = [[asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    _outComposition = [[AVMutableComposition alloc] init];
    
    CMTime start = CMTimeMake(CMTimeGetSeconds(range.start)*1000, 1000);
    CMTime duration = CMTimeMake(CMTimeGetSeconds(range.duration)*1000, 1000);
    CMTime endt = CMTimeAdd(start, duration);
    //    CMTime endt = CMTimeAdd(range.start, range.duration);
    if (CMTimeCompare(endt, asset.duration) > 0) {
        NSLog(@"======================= unsupported range(%f:%f)", CMTimeGetSeconds(endt), CMTimeGetSeconds(asset.duration));
        return nil;
    }
    
    if (assetTrackAudio) {
        AVMutableCompositionTrack *aTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [aTrack insertTimeRange:range ofTrack:assetTrackAudio atTime:kCMTimeZero error:nil];
        [self playWithAsset:_outComposition];
    }
    if (assetTrackVideo) {
        AVMutableCompositionTrack *vTrack = [_outComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        vTrack.preferredTransform = assetTrackVideo.preferredTransform;
        [vTrack insertTimeRange:range ofTrack:assetTrackVideo atTime:kCMTimeZero error:nil];
    }
    
    [self initPlayer];
    self = [super initWithPlayerItem:self.player1Item];
    if(self != nil){
        [self initOutputRotation];
    }
    return self;
}

- (instancetype) initWithRateControlAsset:(NSURL *)url{
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    self.player1Item = [[HAVPlayerItem alloc] initWithAsset:asset];
    [_player1Item addObserver:self
                   forKeyPath:@"status"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    
    _player = [[HAVPlayer alloc] initWithPlayerItem:self.player1Item];
    _player.delegate = self;
    self = [super initWithPlayerItem:self.player1Item];
    if(self != nil){
        [self initOutputRotation];
    }
    
    return self;
}

- (void)setRate:(CGFloat)rate{
    
    if (rate >= 2.0) {
        rate = 2.0;
    }
    else if (rate >= 1.5){
        rate = 1.5;
    }
    else if (rate >= 1.0){
        rate = 1.0;
    }
    else if (rate >= 0.75){
        rate = 0.75;
    }
    else {
        rate = 0.5;
    }
    [_player setRate:rate];
}

- (void)initPlayer{
    self.player1Item = [[HAVPlayerItem alloc] initWithAsset:_outComposition];
    [_player1Item addObserver:self
                   forKeyPath:@"status"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    [self enableAudioTracks:NO inPlayerItem:self.player1Item];
    _player = [[HAVPlayer alloc] initWithPlayerItem:self.player1Item];
    _player.delegate = self;
}

- (void)enableAudioTracks:(BOOL)enable inPlayerItem:(AVPlayerItem*)playerItem
{
    for (AVPlayerItemTrack *track in playerItem.tracks)
    {
        if ([track.assetTrack.mediaType isEqual:AVMediaTypeAudio])
        {
            track.enabled = enable;
        }
    }
}

- (void)playWithAsset:(AVComposition *)composition{
    
    self.exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    
    NSString *myPathDocs =  [NSTemporaryDirectory() stringByAppendingPathComponent:@"xx.m4a"];
    [[NSFileManager defaultManager] removeItemAtPath:myPathDocs error:nil];
    self.exportSession.outputURL = [NSURL fileURLWithPath:myPathDocs];
    self.exportSession.outputFileType = AVFileTypeAppleM4A;
    self.exportSession.shouldOptimizeForNetworkUse = YES;
    __weak HAVMovieReader *weakself = self;
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
        //        NSLog(@"合并完成----status:%@, %@", weakself.exportSession.error.localizedDescription,myPathDocs);
        
        AVAsset *asset = [AVAsset assetWithURL:weakself.exportSession.outputURL];
        _player2Item = [AVPlayerItem playerItemWithAsset:asset];
        [_player2Item addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
        if (_player2) {
            [_player2 pause];
        }
        _player2 = [AVPlayer playerWithPlayerItem:_player2Item];
    }];
}

- (void)playWithAsset:(AVComposition *)composition block:(void (^)(void)) block{
    
    self.exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    
    NSString *myPathDocs =  [NSTemporaryDirectory() stringByAppendingPathComponent:@"xx.m4a"];
    [[NSFileManager defaultManager] removeItemAtPath:myPathDocs error:nil];
    self.exportSession.outputURL = [NSURL fileURLWithPath:myPathDocs];
    self.exportSession.outputFileType = AVFileTypeAppleM4A;
    self.exportSession.shouldOptimizeForNetworkUse = YES;
    __weak HAVMovieReader *weakself = self;
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
        //        NSLog(@"合并完成----status:%@, %@", weakself.exportSession.error.localizedDescription,myPathDocs);
        
        AVAsset *asset = [AVAsset assetWithURL:weakself.exportSession.outputURL];
        _player2Item = [AVPlayerItem playerItemWithAsset:asset];
        [_player2Item addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
        if (_player2) {
            [_player2 pause];
        }
        _player2 = [AVPlayer playerWithPlayerItem:_player2Item];
        if(block != nil){
            block();
        }
    }];
    
    
}

- (void) loopPlayStart:(HAVPlayer *) player{
    if (_player2) {
        [_player2 pause];
        [_player2 seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [_player2 play];
        }];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if (playerItem == _player1Item) {
        playerCurrentItemStatus = [playerItem status];
        if ([keyPath isEqualToString:@"status"]) {
            if ([playerItem status] == AVPlayerStatusReadyToPlay) {
                NSLog(@"_player1Item AVPlayerStatusReadyToPlay:%@", object);
            }
        }
        
    }
    else {
        if ([keyPath isEqualToString:@"status"]) {
            if ([playerItem status] == AVPlayerStatusReadyToPlay) {
                NSLog(@"AVPlayerStatusReadyToPlay2:%@", object);
            } else if ([playerItem status] == AVPlayerStatusFailed || [playerItem status] == AVPlayerStatusUnknown) {
                
            }
            
        }
    }
}

- (void)saveFileAfterTimeEffect:(NSURL *)savePath withVideoSize:(HAVVideoSize)vsize completion:(void (^)(NSError *err))completion{
    
    [[NSFileManager defaultManager] removeItemAtPath:[savePath relativePath] error:nil];
    
    HAVVideoTrack *videoTrack = [HAVVideoTrack new];
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:_outComposition
                                                                      presetName:[videoTrack videoSizeToPreset:vsize]];
    exporter.outputURL = savePath;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (exporter.status)
            {
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"Export OK");
                    
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog (@"AVAssetExportSessionStatusFailed: %@",exporter.error.localizedDescription);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export Cancelled");
                    break;
                default:
                    break;
            }
            if (completion) {
                completion(exporter.error);
            }
        });
    }];
}

- (void) saveFileAfterTimeEffect:(NSURL *)savePath withVideoSize:(HAVVideoSize)vsize bitRate:(NSUInteger)bitRate metaData:(NSString*) metaData forceFramerate:(BOOL)flag completion:(void (^)(NSError *err))completion{
    AVAssetTrack *videoTrack = [[_outComposition tracksWithMediaType:AVMediaTypeVideo] firstObject];
    float realBitRate = [videoTrack estimatedDataRate];
    NSInteger comBitRate = realBitRate > bitRate? bitRate : realBitRate;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self reencodeComposition:_outComposition toMP4File:savePath videoSize:vsize bitRate:comBitRate
                         metaData:metaData forceFramerate:flag withCompletionHandler:completion];
    });
}


- (void)reencodeComposition:(AVComposition *)composition toMP4File:(NSURL *)mp4FileURL videoSize:(HAVVideoSize)vsize bitRate:(NSUInteger)bitRate metaData:(NSString *) metaData forceFramerate:(BOOL)flag withCompletionHandler:(void (^)(NSError *error))handler{
    
    NSAssert(composition != nil, @"AVComposition * can't be nil");
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[mp4FileURL relativePath] error:nil];
    
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:mp4FileURL fileType:AVFileTypeQuickTimeMovie error:&error];
    self.assetWriter.shouldOptimizeForNetworkUse = YES;
    if(metaData.length > 0){
        AVMutableMetadataItem *descriptionMetadata = [AVMutableMetadataItem metadataItem];
        
        descriptionMetadata.key = AVMetadataCommonKeyDescription;
        descriptionMetadata.keySpace = AVMetadataKeySpaceCommon;
        descriptionMetadata.locale = [NSLocale currentLocale];
        descriptionMetadata.value = metaData;
        
        self.assetWriter.metadata = @[descriptionMetadata];
    }
    if(self.assetWriter)
    {
        AVAssetTrack *videoAssetTrack = [composition tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVAssetTrack *audioAssetTrack = [composition tracksWithMediaType:AVMediaTypeAudio].firstObject;
        
        CGFloat width = videoAssetTrack.naturalSize.width;
        CGFloat height = videoAssetTrack.naturalSize.height;
        //        if (vsize) {
        //            if (vsize == HAVVideoSizeCustom540) {
        //
        //                int sw, sh;
        //                if (width < height) {
        //                    sw = 540;
        //                    sh = sw * height / width;
        //                    sh = FFALIGN(sh, 2);
        //                }
        //                else {
        //                    sh = 540;
        //                    sw = width * sh / height;
        //                }
        //                width = sw;
        //                height = sh;
        //
        //            }
        //            else {
        //                CGSize videoSize = [composition videoSize:vsize];
        //                width = videoSize.width;
        //                height = videoSize.height;
        //            }
        //        }
        CGSize videoSize = [composition videoSize:vsize];
        width = videoSize.width;
        height = videoSize.height;
        //配置reader
        AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:composition error:&error];
        
        AVAssetReaderTrackOutput *videoAssetTrackOutput = nil;
        if (videoAssetTrack) {
            NSDictionary *videoOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
            
            videoAssetTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoAssetTrack outputSettings:videoOptions];
            videoAssetTrackOutput.alwaysCopiesSampleData = NO;
            if([assetReader canAddOutput:videoAssetTrackOutput]){
                [assetReader addOutput:videoAssetTrackOutput];
            }
        }
        
        AVAssetReaderTrackOutput *audioAssetTrackOutput = nil;
        if (audioAssetTrack) {
            NSDictionary *audioOptions = @{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM] };
            audioAssetTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioAssetTrack outputSettings:audioOptions];
            audioAssetTrackOutput.alwaysCopiesSampleData = NO;
            
            if([assetReader canAddOutput:audioAssetTrackOutput]){
                [assetReader addOutput:audioAssetTrackOutput];
            }
        }
        
        [assetReader startReading];
        NSDictionary *videoSettings = nil;
        //配置writer
        if(bitRate > 0){
            videoSettings = @{AVVideoCodecKey:AVVideoCodecH264,
                              AVVideoWidthKey:[NSNumber numberWithInt:width],
                              AVVideoHeightKey:[NSNumber numberWithInt:height],
                              AVVideoCompressionPropertiesKey: @{
                                      AVVideoAverageBitRateKey: @(bitRate),
                                      AVVideoMaxKeyFrameIntervalKey: @(30),
                                      AVVideoProfileLevelKey:AVVideoProfileLevelH264High40
                                      }
                              };
        }else{
            videoSettings = @{AVVideoCodecKey:AVVideoCodecH264,
                              AVVideoWidthKey:[NSNumber numberWithInt:width],
                              AVVideoHeightKey:[NSNumber numberWithInt:height],
                              AVVideoCompressionPropertiesKey: @{AVVideoMaxKeyFrameIntervalKey: @(30),AVVideoProfileLevelKey:AVVideoProfileLevelH264High40
                                                                 }
                              };
        }
        
        AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        videoWriterInput.expectsMediaDataInRealTime = YES;
        videoWriterInput.transform = videoAssetTrack.preferredTransform;
        
        //        AVAssetWriterInput* audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:nil sourceFormatHint:((__bridge CMAudioFormatDescriptionRef)audioAssetTrack.formatDescriptions.firstObject)];
        NSDictionary *audioSettings = @{
                                        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                        AVNumberOfChannelsKey: @(2),
                                        AVSampleRateKey: @(44100),
                                        AVEncoderBitRateKey: @(128000),
                                        };
        AVAssetWriterInput* audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
        audioWriterInput.expectsMediaDataInRealTime = YES;
        
        if(videoAssetTrack && [self.assetWriter canAddInput:videoWriterInput]){
            [self.assetWriter addInput:videoWriterInput];
        }
        
        if(audioAssetTrack && [self.assetWriter canAddInput:audioWriterInput]){
            [self.assetWriter addInput:audioWriterInput];
        }
        
        [self.assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
        
        //编码
        dispatch_group_t encodingGroup = dispatch_group_create();
        
        if (audioAssetTrack) {
            dispatch_group_enter(encodingGroup);
            [audioWriterInput requestMediaDataWhenReadyOnQueue:self.encodingQueue usingBlock:^{
                while ([audioWriterInput isReadyForMoreMediaData] && !isExportAbort)
                {
                    CMSampleBufferRef nextSampleBuffer = [audioAssetTrackOutput copyNextSampleBuffer];
                    if (nextSampleBuffer)
                    {
                        [audioWriterInput appendSampleBuffer:nextSampleBuffer];
                        CFRelease(nextSampleBuffer);
                    }
                    else{
                        [audioWriterInput markAsFinished];
                        dispatch_group_leave(encodingGroup);
                        break;
                    }
                }
            }];
        }
        
        if (videoAssetTrack) {
            dispatch_group_enter(encodingGroup);
            __block CGFloat a1 = 0.0, a2 = 0.0;
            __block BOOL firstFrame = true;
            [videoWriterInput requestMediaDataWhenReadyOnQueue:self.encodingQueue usingBlock:^{
                while ([videoWriterInput isReadyForMoreMediaData] && !isExportAbort)
                {
                    CMSampleBufferRef nextSampleBuffer = [videoAssetTrackOutput copyNextSampleBuffer];
                    a2 = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(nextSampleBuffer));
                    
                    if (nextSampleBuffer)
                    {
                        
                        if (!isExportAbort && [UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
                        {
                            
                            isExportAbort = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:ENTERBACKGROUND_EXPORTABORT object:nil];
                            
                            if (videoWriterInput)
                            {
                                [videoWriterInput markAsFinished];
                            }
                            if (audioWriterInput)
                            {
                                [audioWriterInput markAsFinished];
                            }
                            
                            if (self.assetWriter)
                            {
                                self.assetWriter = nil;
                            }
                            
                        }
                        
                        if (flag) {
                            if (firstFrame || ((a2 - a1) >= (1.0 / 30.0))) {
                                firstFrame = false;
                                [videoWriterInput appendSampleBuffer:nextSampleBuffer];
                                a1 = a2;
                            }
                        }
                        else {
                            [videoWriterInput appendSampleBuffer:nextSampleBuffer];
                        }
                        CFRelease(nextSampleBuffer);
#if 0
                        OSStatus err = CMBufferQueueEnqueue(queue, nextSampleBuffer);
                        if (!err)
                        {
                            UIApplicationState state = [UIApplication sharedApplication].applicationState;
                            BOOL result = (state == UIApplicationStateBackground);
                            
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(queue);
                                if (sbuf)
                                {
                                    [self processMovieFrame:sbuf];
                                    //                                    CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer(sbuf);
                                    //                                    self.testLayer.pixelBuffer = imageBufferRef;
                                    NSLog(@"xx sample:%f", a2 = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(nextSampleBuffer)));
                                    CFRelease(sbuf);
                                }
                            });
                        }
#endif
                        
                    }
                    else{
                        [videoWriterInput markAsFinished];
                        dispatch_group_leave(encodingGroup);
                        break;
                    }
                }
            }];
        }
        
        dispatch_group_wait(encodingGroup, DISPATCH_TIME_FOREVER);
        
        __weak HAVMovieReader *weakself = self;
        [self.assetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!isExportAbort)
                {
                    handler(error);
                }
            });
            weakself.assetWriter = nil;
            weakself.encodingQueue = nil;
        }];
    }else{
        handler(error);
    }
}

- (void)reencodeComposition2:(AVComposition *)composition toMP4File:(NSURL *)mp4FileURL videoSize:(HAVVideoSize)vsize bitRate:(NSUInteger)bitRate forceFramerate:(BOOL)flag withCompletionHandler:(void (^)(NSError *error))handler{
    
    NSAssert(composition != nil, @"AVComposition * can't be nil");
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[mp4FileURL relativePath] error:nil];
    
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:mp4FileURL fileType:AVFileTypeQuickTimeMovie error:&error];
    self.assetWriter.shouldOptimizeForNetworkUse = YES;
    if(self.assetWriter)
    {
        AVAssetTrack *videoAssetTrack = [composition tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVAssetTrack *audioAssetTrack = [composition tracksWithMediaType:AVMediaTypeAudio].firstObject;
        
        CGFloat width = videoAssetTrack.naturalSize.width;
        CGFloat height = videoAssetTrack.naturalSize.height;
        //        if (vsize) {
        //            if (vsize == HAVVideoSizeCustom540) {
        //
        //                int sw, sh;
        //                if (width < height) {
        //                    sw = 540;
        //                    sh = sw * height / width;
        //                    sh = FFALIGN(sh, 2);
        //                }
        //                else {
        //                    sh = 540;
        //                    sw = width * sh / height;
        //                }
        //                width = sw;
        //                height = sh;
        //
        //            }
        //            else {
        //                CGSize videoSize = [composition videoSize:vsize];
        //                width = videoSize.width;
        //                height = videoSize.height;
        //            }
        //        }
        CGSize videoSize = [composition videoSize:vsize];
        width = videoSize.width;
        height = videoSize.height;
        //配置reader
        AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:composition error:&error];
        
        AVAssetReaderTrackOutput *videoAssetTrackOutput = nil;
        if (videoAssetTrack) {
            NSDictionary *videoOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
            
            videoAssetTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoAssetTrack outputSettings:videoOptions];
            videoAssetTrackOutput.alwaysCopiesSampleData = NO;
            if([assetReader canAddOutput:videoAssetTrackOutput]){
                [assetReader addOutput:videoAssetTrackOutput];
            }
        }
        
        AVAssetReaderTrackOutput *audioAssetTrackOutput = nil;
        if (audioAssetTrack) {
            NSDictionary *audioOptions = @{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM] };
            audioAssetTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioAssetTrack outputSettings:audioOptions];
            audioAssetTrackOutput.alwaysCopiesSampleData = NO;
            
            if([assetReader canAddOutput:audioAssetTrackOutput]){
                [assetReader addOutput:audioAssetTrackOutput];
            }
        }
        
        [assetReader startReading];
        NSDictionary *videoSettings = nil;
        //配置writer
        if(bitRate > 0){
            videoSettings = @{AVVideoCodecKey:AVVideoCodecH264,
                              AVVideoWidthKey:[NSNumber numberWithInt:width],
                              AVVideoHeightKey:[NSNumber numberWithInt:height],
                              AVVideoCompressionPropertiesKey: @{
                                      AVVideoAverageBitRateKey: @(bitRate),
                                      AVVideoProfileLevelKey:AVVideoProfileLevelH264High40
                                      }
                              };
        }else{
            videoSettings = @{AVVideoCodecKey:AVVideoCodecH264,
                              AVVideoWidthKey:[NSNumber numberWithInt:width],
                              AVVideoHeightKey:[NSNumber numberWithInt:height],
                              AVVideoCompressionPropertiesKey: @{AVVideoMaxKeyFrameIntervalKey: @(30),AVVideoProfileLevelKey:AVVideoProfileLevelH264High40
                                                                 }
                              };
        }
        
        AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        videoWriterInput.expectsMediaDataInRealTime = YES;
        videoWriterInput.transform = videoAssetTrack.preferredTransform;
        
        //        AVAssetWriterInput* audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:nil sourceFormatHint:((__bridge CMAudioFormatDescriptionRef)audioAssetTrack.formatDescriptions.firstObject)];
        NSDictionary *audioSettings = @{
                                        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                        AVNumberOfChannelsKey: @(2),
                                        AVSampleRateKey: @(44100),
                                        AVEncoderBitRateKey: @(128000),
                                        };
        AVAssetWriterInput* audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
        audioWriterInput.expectsMediaDataInRealTime = YES;
        
        if(videoAssetTrack && [self.assetWriter canAddInput:videoWriterInput]){
            [self.assetWriter addInput:videoWriterInput];
        }
        
        if(audioAssetTrack && [self.assetWriter canAddInput:audioWriterInput]){
            [self.assetWriter addInput:audioWriterInput];
        }
        
        [self.assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
        
        //编码
        dispatch_group_t encodingGroup = dispatch_group_create();
        
        if (audioAssetTrack) {
            dispatch_group_enter(encodingGroup);
            [audioWriterInput requestMediaDataWhenReadyOnQueue:self.encodingQueue usingBlock:^{
                while ([audioWriterInput isReadyForMoreMediaData] && !isExportAbort)
                {
                    CMSampleBufferRef nextSampleBuffer = [audioAssetTrackOutput copyNextSampleBuffer];
                    if (nextSampleBuffer)
                    {
                        [audioWriterInput appendSampleBuffer:nextSampleBuffer];
                        CFRelease(nextSampleBuffer);
                    }
                    else{
                        [audioWriterInput markAsFinished];
                        dispatch_group_leave(encodingGroup);
                        break;
                    }
                }
            }];
        }
        
        if (videoAssetTrack) {
            dispatch_group_enter(encodingGroup);
            
            //test
            //            CMBufferQueueRef queue;
            //            CMBufferQueueCreate(kCFAllocatorDefault, 0, CMBufferQueueGetCallbacksForUnsortedSampleBuffers(), &queue);
            __block CGFloat a1 = 0.0, a2 = 0.0;
            __block BOOL firstFrame = true;
            [videoWriterInput requestMediaDataWhenReadyOnQueue:self.encodingQueue usingBlock:^{
                while ([videoWriterInput isReadyForMoreMediaData] && !isExportAbort)
                {
                    CMSampleBufferRef nextSampleBuffer = [videoAssetTrackOutput copyNextSampleBuffer];
                    a2 = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(nextSampleBuffer));
                    
                    if (nextSampleBuffer)
                    {
                        
                        if (!isExportAbort && [UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
                        {
                            
                            isExportAbort = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:ENTERBACKGROUND_EXPORTABORT object:nil];
                            
                            if (videoWriterInput)
                            {
                                [videoWriterInput markAsFinished];
                            }
                            if (audioWriterInput)
                            {
                                [audioWriterInput markAsFinished];
                            }
                            
                            if (self.assetWriter)
                            {
                                self.assetWriter = nil;
                            }
                            
                        }
                        
                        if (flag) {
                            if (firstFrame || ((a2 - a1) >= (1.0 / 30.0))) {
                                firstFrame = false;
                                [videoWriterInput appendSampleBuffer:nextSampleBuffer];
                                a1 = a2;
                            }
                        }
                        else {
                            [videoWriterInput appendSampleBuffer:nextSampleBuffer];
                        }
                        CFRelease(nextSampleBuffer);
#if 0
                        OSStatus err = CMBufferQueueEnqueue(queue, nextSampleBuffer);
                        if (!err)
                        {
                            UIApplicationState state = [UIApplication sharedApplication].applicationState;
                            BOOL result = (state == UIApplicationStateBackground);
                            
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(queue);
                                if (sbuf)
                                {
                                    [self processMovieFrame:sbuf];
                                    //                                    CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer(sbuf);
                                    //                                    self.testLayer.pixelBuffer = imageBufferRef;
                                    NSLog(@"xx sample:%f", a2 = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(nextSampleBuffer)));
                                    CFRelease(sbuf);
                                }
                            });
                        }
#endif
                        
                    }
                    else{
                        [videoWriterInput markAsFinished];
                        dispatch_group_leave(encodingGroup);
                        break;
                    }
                }
            }];
        }
        
        dispatch_group_wait(encodingGroup, DISPATCH_TIME_FOREVER);
        
        __weak HAVMovieReader *weakself = self;
        
        
        [self.assetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (!isExportAbort)
                {
                    handler(error);
                }
                
            });
            
            weakself.assetWriter = nil;
            weakself.encodingQueue = nil;
        }];
        
    }
    else
        handler(error);
}

- (CGFloat)currentTimeSeconds{
    return CMTimeGetSeconds(self.player.currentTime);
}

- (CGFloat)currentPlayTime{
    return CMTimeGetSeconds([self currentTimeStamp]);
}


- (CGFloat) currentTimeWithSecond{
    return CMTimeGetSeconds(self.player.currentTime);
}

- (void)processMovieFrame:(CVPixelBufferRef)movieFrame withSampleTime:(CMTime)currentSampleTime
{
    [super processMovieFrame:movieFrame withSampleTime:currentSampleTime ];
    if(_showFirstFrame){
        _showFirstFrame = NO;
        [self seekToTime:0.0f];
        [self pause];
    }
    
    if(self.showCurrentFrame){
        self.showCurrentFrame = NO;
        [self pause];
    }
}

- (BOOL) finished{
    CMTime time = [self.player currentTime];
    CMTime duration = [[self  getAsset] duration];
    return (CMTimeCompare(time, duration) == 0);
}

- (void) showFrameAtTime:(NSTimeInterval) time
{
    [self seek:time];
    self.showCurrentFrame = YES;
    [self startProcessing];
}

- (void) showFrameAtTime:(NSTimeInterval) time completionHandler:(void (^)(BOOL finished))completionHandler
{
    [self seek:time completionHandler:^(BOOL finished)
     {
         if(finished)
         {
             self.showCurrentFrame = YES;
             [self startProcessing];
         }
         if(completionHandler)
         {
             completionHandler(finished);
         }
     }];
}

- (void)showSampleAtTime:(NSTimeInterval)time{
    CMTime seekTime = CMTimeMake(time*1000000000, 1000000000);
    [self.player seekToTime:seekTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    self.showCurrentFrame = YES;
    [self startProcessing];
}

- (void)seekAudioSampleAtTime:(NSTimeInterval)time
{
    CMTime seekTime = CMTimeMake(time*1000000000, 1000000000);
    if (self.player2)
    {
        [self.player2 seekToTime:seekTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

- (void)dealloc
{
    [self removeAllTargets];
    [self releasePipeLineFilters:self.exportPipeline];
    [self.exportPipeline removeAllFilters];
    self.exportPipeline = nil;
    if (self.player2Item)
    {
        [self.player2Item removeObserver:self forKeyPath:@"status"];
        self.player2Item = nil;
    }
    if (self.player1Item)
    {
        [self.player1Item removeObserver:self forKeyPath:@"status"];
        self.player1Item = nil;
    }
    NSLog(@"dealloc %s, %s",__FILE__ ,__FUNCTION__);
}

#pragma mark - getter and setter
- (dispatch_queue_t)encodingQueue
{
    if(!_encodingQueue)
    {
        _encodingQueue = dispatch_queue_create("com.myProject.encoding", NULL);
    }
    return _encodingQueue;
}

- (CGFloat) duration
{
    return CMTimeGetSeconds(self.player.currentItem.duration);
}

@end

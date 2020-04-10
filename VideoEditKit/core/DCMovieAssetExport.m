//
//  DCMovieAssetExport.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>

#import "DCMovieAssetExport.h"
#import "HAVGPUImageMovie.h"
//#import "HAVMp4Utility.h"
#import "AVAsset+MetalData.h"
#import "HAVLutImageFilter.h"
#import "HAVGPUImageLutFilter.h"
#import "HAVGPULightLutFilter.h"
#import "HAVScrawAndTextFilter.h"
#import "HAVGifFilter.h"

#import "HAVGifFilterController.h"

@interface HAVMovieAssetExport()
{
    NSString *srcUrl;
    float _samplerate;
    int _channels;
}

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) HAVGPUImageMovie *exportMovie;
@property (nonatomic, strong) GPUImageMovie *exportMovie2;
@property (nonatomic, strong) GPUImageMovieWriter *exportMovieWriter;
@property (nonatomic, strong) GPUImageFilterPipeline *exportPipeline;
@property (nonatomic) AudioStreamBasicDescription *audioInfo;
@property (nonatomic,strong)AVAssetExportSession* exportSession;


@property(nonatomic,strong)NSArray* sourcePathArray;
@property(nonatomic,strong)NSURL* audioUrl;
@property(nonatomic,assign)CMTimeRange totalTimeRange;
@property(nonatomic,strong)NSString* storePath;
@property(nonatomic,strong)NSArray* filters;
@property(nonatomic,strong)NSDictionary* stprocessing;
@property(nonatomic,assign)BOOL hasCancel;
@property(nonatomic,assign)BOOL need720P;
@end

@implementation HAVMovieAssetExport

- (instancetype) initWithAsset:(AVAsset*) asset{
    self = [super init];
    if(self){
        self.asset = asset;
        self.videSize = HAVVideoSizeNature;
        self.onlyKeyFrame = NO;
        self.bitRate = 0;
        self.outputPath = nil;
        self.metaData = nil;
        self.exportPipeline = nil;
        self.currentRotation = HAVRotationInvalid;
        self.videSize = HAVVideoSizeNature;
        self.hasCancel = NO;
    }
    return self;
}

- (instancetype) initWitHAVAsset:(HAVAsset*) asset{
    AVAsset *avAsset = [asset currentAsset];
    self = [self initWithAsset:avAsset];
    if(self !=nil){
        
    }
    return self;
}

- (instancetype) initWithAssetItem:(HAVAssetItem *) item audioAssetItem:(HAVAssetItem *) audioAssetItem{
    HAVAsset *asset = [[HAVAsset alloc] initWithAssetItem:item audioAssetItem:audioAssetItem];
    if(asset != nil){
        self = [self initWitHAVAsset:asset];
    }
    return self;
}

- (instancetype) initWithAssetItems:(NSArray<HAVAssetItem *> *) items audioAssetItem:(HAVAssetItem *) audioAssetItem{
    HAVAsset *asset = [[HAVAsset alloc] initWithAssetItems:items audioAssetItem:audioAssetItem];
    if(asset != nil){
        self = [self initWitHAVAsset:asset];
    }
    return self;
}

- (void) cancelExport{
    [self.exportMovieWriter cancelRecording];
    [self.exportMovie cancelProcessing];
    [self.exportMovieWriter setCompletionBlock:nil];
    [self.exportMovieWriter setFailureBlock:nil];
}

- (GPUImageRotationMode) outputRotation
{
    GPUImageRotationMode outputRotation = kGPUImageNoRotation;
    NSArray *tracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
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
    return outputRotation;
}

- (void)exportAsynchronouslyWithFilters:(NSArray *) filters withCompletionHandler:(void (^)(BOOL status, NSString *path ,NSError * error))handler
{
    if(self.outputPath != nil)
    {
        unlink([self.outputPath UTF8String]);
    }
    BOOL hasAudio = ([[self.asset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
    if(self.outputPath != nil)
    {
        
        NSURL *url  = [NSURL fileURLWithPath:self.outputPath];
        CGSize videoSize = [self.asset videoSize:self.videSize];
        if(url != nil)
        {
            GPUImageRotationMode currentRotation =  [self outputRotation];
            if(self.currentRotation != HAVRotationInvalid)
            {
                switch (self.currentRotation)
                {
                    case HAVRotationDegress0:
                        currentRotation = kGPUImageNoRotation;
                        break;
                    case HAVRotationDegress90:
                        currentRotation = kGPUImageRotateRight;
                        break;
                    case HAVRotationDegress180:
                        currentRotation = kGPUImageRotate180;
                        break;
                    case HAVRotationDegress270:
                        currentRotation = kGPUImageRotateLeft;
                        break;
                    default:
                        break;
                }
            }
            
            switch (currentRotation) {
                case kGPUImageRotateLeft:
                case kGPUImageRotateRight:
                    videoSize = CGSizeMake(videoSize.height, videoSize.width);
                    break;
                    
                default:
                    break;
            }
            
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,@(videoSize.width),AVVideoWidthKey,@(videoSize.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                           AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
            if(self.onlyKeyFrame){
                [compressionProperties setObject:@(1) forKey:AVVideoMaxKeyFrameIntervalKey];
            }
            
            if(self.bitRate > 0){
                [compressionProperties setObject:@(self.bitRate) forKey:AVVideoAverageBitRateKey];
            }
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            self.exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            if(self.metaData.length > 0){
                AVMutableMetadataItem *descriptionMetadata = [AVMutableMetadataItem metadataItem];
                
                descriptionMetadata.key = AVMetadataCommonKeyDescription;
                descriptionMetadata.keySpace = AVMetadataKeySpaceCommon;
                descriptionMetadata.locale = [NSLocale currentLocale];
                descriptionMetadata.value = self.metaData;
                [self.exportMovieWriter setMetaData:@[descriptionMetadata]];
            }
            if(self.asset != nil){
                self.exportMovie = [[HAVGPUImageMovie alloc] initWithAsset:self.asset];
                [self.exportMovie setOutputRotation:currentRotation];
                self.exportMovie.playAtActualSpeed = NO;
                self.exportMovie.audioEncodingTarget = hasAudio?self.exportMovieWriter:nil;
                self.exportMovieWriter.hasAudioTrack = hasAudio;
                self.exportMovieWriter.encodingLiveVideo = YES;
                [self.exportMovie enableSynchronizedEncodingUsingMovieWriter:self.exportMovieWriter];
                if(filters.count > 0){
                    self.exportPipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:filters input:self.exportMovie output:self.exportMovieWriter];
                }else{
                    [self.exportMovie addTarget:self.exportMovieWriter];
                }
                __block GPUImageMovie *movieFile = self.exportMovie;
                __block GPUImageFilterPipeline *pipeLine = self.exportPipeline;
                __block GPUImageMovieWriter *movieWritter = self.exportMovieWriter;
                __weak __typeof(self) weakSelf = self;
                [self.exportMovieWriter setCompletionBlock:^{
                    for (GPUImageFilter * filter in pipeLine.filters)
                    {
                        if([filter isKindOfClass:[HAVLutImageFilter class]])
                        {
                            HAVLutImageFilter *auxFilter = (HAVLutImageFilter*) filter;
                            [auxFilter releaseFilter];
                        }
                        else if([filter isKindOfClass:[HAVGPUImageLutFilter class]])
                        {
                            HAVGPUImageLutFilter *auxFilter = (HAVGPUImageLutFilter*) filter;
                            [auxFilter releaseFilter];
                        }
                        else if([filter isKindOfClass:[HAVGPULightLutFilter class]])
                        {
                            HAVGPULightLutFilter *auxFilter = (HAVGPULightLutFilter*) filter;
                            [auxFilter releaseFilter];
                        }
                    }
                    [pipeLine removeAllFilters];
                    [movieFile endProcessing];
                    [movieWritter finishRecordingWithCompletionHandler:^{
                        
#ifdef bEnablePurgeBuffer
                        [[GPUImageContext sharedFramebufferCache] purgeTextureFramebuffers:[movieFile framebufferForOutput]];
#else
                        [[GPUImageContext sharedFramebufferCache] purgeTextureFramebuffers];
#endif
                        
                        [movieWritter setFailureBlock:nil];
                        [movieWritter setCompletionBlock:nil];
                        if(handler != nil){
                            handler(YES, weakSelf.outputPath, nil);
                        }
                    }];
                }];
                [self.exportMovieWriter setFailureBlock:^(NSError *err){
                    handler(NO, weakSelf.outputPath, err);
                    [movieWritter setCompletionBlock:nil];
                    [movieWritter setFailureBlock:nil];
                }];
                [self.exportMovieWriter startRecording];
                [self.exportMovie startProcessing];
                
            }else{
                NSError *error = [NSError errorWithDomain:@"asset error" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"asset error" forKey:@"error"]];
                if(handler != nil){
                    handler(NO , self.outputPath, error);
                }
            }
        }else{
            NSError *error = [NSError errorWithDomain:@"tmp path url error" code:-2 userInfo:[NSDictionary dictionaryWithObject:@"tmp path url error" forKey:@"error"]];
            if(handler != nil){
                handler(NO , self.outputPath, error);
            }
        }
    }else{
        NSError *error = [NSError errorWithDomain:@"tmp path error" code:-3 userInfo:[NSDictionary dictionaryWithObject:@"tmp path error" forKey:@"error"]];
        if(handler != nil){
            handler(NO , self.outputPath, error);
        }
    }
}


- (void)kickOffAny:(AVAsset *)sourceAsset outputURL:(NSString *)outputUrl tracks:(NSMutableArray *)tracks assets:(NSMutableArray *)assets startTimeArray:(NSMutableArray *)startTimeArray videoSize:(HAVVideoSize)videoSize cancel:(BOOL *)cancel progressHandle:(void (^)(CGFloat progress))progressHandle finishHandle:(void (^)(NSError *error))finishHandle{
    
    NSError *error;
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *tmpUrl =  [documentsDirectory stringByAppendingPathComponent:@"tmp.mov"];
    [[NSFileManager defaultManager] removeItemAtPath:tmpUrl error:nil];
    
    NSDictionary *totalReaderOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
    AVAssetReaderOutput *totalReaderOutput = nil;
    
    AVAssetTrack *videoTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (!videoTrack) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Not find video track" forKey:NSLocalizedDescriptionKey];
        NSError *err = [NSError errorWithDomain:@"ExportAnyReversedFile" code:-10086 userInfo:userInfo];
        if (finishHandle){
            finishHandle(err);
        }
        return ;
    }
    CMTime val = kCMTimeZero;
    NSMutableArray *sampleTimes = [NSMutableArray array];
#if 0
    
    
    totalReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:totalReaderOutputSettings];
    
    AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:sourceAsset error:&error];
    if([assetReader canAddOutput:totalReaderOutput]){
        [assetReader addOutput:totalReaderOutput];
    }
    totalReaderOutput.alwaysCopiesSampleData = NO;
    
    [assetReader startReading];
    
    CMSampleBufferRef totalSample;
    
    
    NSLog(@"yy1");
    while((totalSample = [totalReaderOutput copyNextSampleBuffer])) {
        CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(totalSample);
        
        [sampleTimes addObject:[NSValue valueWithCMTime:presentationTime]];
        CFRelease(totalSample);
    }
    NSLog(@"yy2");
#else
    
    
    
    
//    //test=========
//    HAVMp4Utility *uu = [[HAVMp4Utility alloc] init];
//    NSArray *arrx = [uu mp4SampleTimeArray:srcUrl];
//    sampleTimes = [NSMutableArray arrayWithArray:arrx];
//    //end==========
    
#endif
    
    //配置Writer
    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:tmpUrl]
                                                      fileType:AVFileTypeQuickTimeMovie
                                                         error:&error];
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @(videoTrack.estimatedDataRate), AVVideoAverageBitRateKey,
                                           nil];
    CGFloat width = videoTrack.naturalSize.width;
    CGFloat height = videoTrack.naturalSize.height;
    NSDictionary *writerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                          AVVideoCodecH264, AVVideoCodecKey,
                                          [NSNumber numberWithInt:height], AVVideoHeightKey,
                                          [NSNumber numberWithInt:width], AVVideoWidthKey,
                                          videoCompressionProps, AVVideoCompressionPropertiesKey,
                                          nil];
    AVAssetWriterInput *writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                     outputSettings:writerOutputSettings
                                                                   sourceFormatHint:(__bridge CMFormatDescriptionRef)[videoTrack.formatDescriptions lastObject]];
    writerInput.transform = videoTrack.preferredTransform;
    [writerInput setExpectsMediaDataInRealTime:NO];
    
    // Initialize an input adaptor so that we can append PixelBuffer
    AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    
    [writer addInput:writerInput];
    
    [writer startWriting];
    [writer startSessionAtSourceTime:videoTrack.timeRange.start];
    
    NSInteger counter = 0;
    size_t countOfFrames = 0;
    
    NSMutableArray *sampless = [NSMutableArray array];
    
    for (NSInteger i = tracks.count -1; i <= tracks.count; i --) {
        if (*(cancel)) {
            [writer cancelWriting];
            return ;
        }
        AVAssetReader *reader = nil;
        
        countOfFrames = 0;
        AVAssetReaderOutput *readerOutput = nil;
        
        
        readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:tracks[i] outputSettings:totalReaderOutputSettings];
        readerOutput.alwaysCopiesSampleData = NO;
        
        reader = [[AVAssetReader alloc] initWithAsset:assets[i] error:&error];
        if([reader canAddOutput:readerOutput]){
            [reader addOutput:readerOutput];
        } else {
            break;
        }
        [reader startReading];
        
        CMSampleBufferRef sample;
        
        [sampless removeAllObjects];
        
        while((sample = [readerOutput copyNextSampleBuffer])) {
            CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sample);
            
            if (CMTIME_COMPARE_INLINE(presentationTime, >=, [startTimeArray[i] CMTimeValue])) {
                
                countOfFrames++;
                [sampless addObject:(__bridge id _Nonnull)(sample)];
            } else {
                if (sample != NULL) {
                    CFRelease(sample);
                }
            }
        }
        
        [reader cancelReading];
        for(NSInteger j = 0; j < countOfFrames; j++) {
            
            if (counter > sampleTimes.count - 1) {
                break;
            }
            //            CMTime presentationTime = [sampleTimes[counter] CMTimeValue];
            
            int64_t ss = (int64_t)([sampleTimes[counter] floatValue]*1000000LL) * videoTrack.naturalTimeScale;
            CMTime presentationTime = CMTimeMake(ss, videoTrack.naturalTimeScale*1000000);
            //test=========================
            //            CMTime presentationTime = kCMTimeZero;
            
            //            NSLog(@"presentationTime:%f(%f) val:%f", CMTimeGetSeconds(presentationTime), [sampleTimes[counter] floatValue], CMTimeGetSeconds(val));
            //            val = CMTimeAdd(val, videoTrack.minFrameDuration);
            //end==========================
            
            CMSampleBufferRef bufferRef = (__bridge CMSampleBufferRef)sampless[countOfFrames - j - 1];
            CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer(bufferRef);
            
            while (!writerInput.readyForMoreMediaData) {
                //                NSLog(@"waitting...");
                [NSThread sleepForTimeInterval:0.01];
            }
            [pixelBufferAdaptor appendPixelBuffer:imageBufferRef withPresentationTime:presentationTime];
            if (progressHandle) {
                progressHandle(((CGFloat)counter/(CGFloat)sampleTimes.count));
            }
            
            counter++;
            CFRelease(bufferRef);
        }
    }
    
    [writer finishWritingWithCompletionHandler:^{
        NSLog(@"Video finished.");
        //        AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:sourceUrl]];
        AVAssetTrack *audioTrack2 = [[sourceAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        if (!audioTrack2) {
            NSError *error;
            [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:tmpUrl] toURL:[NSURL fileURLWithPath:outputUrl] error:&error];
            if (finishHandle) {
                finishHandle(error);
                [[NSFileManager defaultManager] removeItemAtPath:tmpUrl error:nil];
                NSLog(@"No audio export finished!");
                return ;
            };
        }
        
        AVMutableComposition *composition = [AVMutableComposition composition];
        AVMutableCompositionTrack *compositionTrackVideo = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        NSLog(@"tmpUrl:%@", tmpUrl);
        AVAsset *asset2 = [AVAsset assetWithURL:[NSURL fileURLWithPath:tmpUrl]];
        AVAssetTrack *videoTrack2 = [[asset2 tracksWithMediaType:AVMediaTypeVideo] firstObject];
        [compositionTrackVideo insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:videoTrack2 atTime:kCMTimeZero error:nil];
        
        AVMutableCompositionTrack *compositionTrackAudio = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionTrackAudio insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:audioTrack2 atTime:kCMTimeZero error:nil];
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                          initWithAsset: composition
                                          presetName: [composition presetFromVideoSize:videoSize]];
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        
        /** 导出的文件存在即删除**/
        if ([[NSFileManager defaultManager] fileExistsAtPath:outputUrl]) {
            [[NSFileManager defaultManager] removeItemAtPath:outputUrl error:nil];
        }
        NSURL *exportURL = [NSURL fileURLWithPath:outputUrl];
        exporter.outputURL = exportURL;
        exporter.shouldOptimizeForNetworkUse = YES;
        NSLog(@"开始导出");
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            int exportStatus = exporter.status;
            switch (exportStatus) {
                case AVAssetExportSessionStatusCompleted:{
                    if (finishHandle) {
                        NSLog(@"export finished!");
                        finishHandle(exporter.error);
                        [[NSFileManager defaultManager] removeItemAtPath:tmpUrl error:nil];
                    };
                }
                    break;
                case AVAssetExportSessionStatusFailed:
                case AVAssetExportSessionStatusUnknown:
                case AVAssetExportSessionStatusExporting:
                case AVAssetExportSessionStatusCancelled:
                case AVAssetExportSessionStatusWaiting:
                default:{
                    if (finishHandle) {
                        finishHandle(exporter.error);
                        [[NSFileManager defaultManager] removeItemAtPath:tmpUrl error:nil];
                    };
                }
                    break;
            }
        }];
    }];
}

- (void)kickOffOnlyIFrame:(AVAsset *)sourceAsset outputURL:(NSString *)outputUrl tracks:(NSMutableArray *)tracks assets:(NSMutableArray *)assets startTimeArray:(NSMutableArray *)startTimeArray videoSize:(HAVVideoSize)videoSize cancel:(BOOL *)cancel progressHandle:(void (^)(CGFloat progress))progressHandle finishHandle:(void (^)(NSError *error))finishHandle{
    //    NSError *error;
    AVAssetTrack *videoTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (!videoTrack) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Not find video track" forKey:NSLocalizedDescriptionKey];
        NSError *err = [NSError errorWithDomain:@"ExportIReversedFile" code:-10086 userInfo:userInfo];
        if (finishHandle){
            finishHandle(err);
        }
        return ;
    }
    AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:sourceAsset error:nil];
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:nil];
    assetReaderOutput.alwaysCopiesSampleData = NO;
    
    if([assetReader canAddOutput:assetReaderOutput]){
        [assetReader addOutput:assetReaderOutput];
    }
    
    AVAssetTrack *audioTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    AVAssetReaderOutput *assetAudioReaderOutput = nil;
    if (audioTrack)
    {
        assetAudioReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
        assetAudioReaderOutput.alwaysCopiesSampleData = NO;
        if([assetReader canAddOutput:assetAudioReaderOutput]){
            [assetReader addOutput:assetAudioReaderOutput];
        }
    }
    
    
    __block AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:outputUrl]
                                                                   fileType:AVFileTypeQuickTimeMovie
                                                                      error:nil];
    assetWriter.shouldOptimizeForNetworkUse = YES;
    AVAssetWriterInput *assetWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                          outputSettings:nil
                                                                        sourceFormatHint:(__bridge CMFormatDescriptionRef)[videoTrack.formatDescriptions lastObject]];
    assetWriterInput.transform = videoTrack.preferredTransform;
    assetWriterInput.expectsMediaDataInRealTime = YES;
    [assetWriter addInput:assetWriterInput];
    
    AVAssetWriterInput *assetAudioWriterInput = nil;
    if (audioTrack) {
        assetAudioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil] ;
        assetAudioWriterInput.expectsMediaDataInRealTime = YES;
        [assetWriter addInput:assetAudioWriterInput];
    }
    
    [assetReader startReading];
    
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    
    __block dispatch_queue_t myInputSerialQueue = dispatch_queue_create("myReverseQueue", DISPATCH_QUEUE_SERIAL);
    
    NSLog(@"ready go");
    
    CFArrayCallBacks callbacks = {0, NULL, NULL, CFCopyDescription, CFEqual};
    CFMutableArrayRef sampleBufArray = CFArrayCreateMutable(kCFAllocatorDefault, 0, &callbacks);
    
    
    dispatch_group_t encodingGroup = dispatch_group_create();
    __block NSInteger i = 0;
    __block int k = 0;
    __block int j = (int)tracks.count;
    __block int count = 0;
    __block int total = 0;
    __block CMTime firstCMTime = kCMTimeZero;
    
    //    __block int testaa = 0;
    __block CMTime tmpts = kCMTimeZero;
    if (videoTrack) {
        
        dispatch_group_enter(encodingGroup);
        [assetWriterInput requestMediaDataWhenReadyOnQueue:myInputSerialQueue usingBlock:^{
            while ([assetWriterInput isReadyForMoreMediaData])
            {
                
                NSInteger sbs = CFArrayGetCount(sampleBufArray);
                if (sbs == 0)
                {
                    if (--j < 0)
                    {
                        
                        
                        [assetWriterInput markAsFinished];
                        dispatch_group_leave(encodingGroup);
                        break;
                    }
                    
                    AVAssetReaderOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:tracks[j] outputSettings:nil];
                    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:assets[j] error:nil];
                    
                    output.alwaysCopiesSampleData = NO;
                    if ([reader canAddOutput:output]) {
                        [reader addOutput:output];
                    }
                    else {
                        NSLog(@"Add output failed.");
                    }
                    
                    [reader startReading];
                    
                    CMSampleBufferRef nextSampleBuffer;
                    while ((nextSampleBuffer = [output copyNextSampleBuffer]) != nil)
                    {
                        
                        if (CMTIME_IS_INVALID(CMSampleBufferGetDecodeTimeStamp(nextSampleBuffer)))
                        {
                            CFRelease(nextSampleBuffer);
                            NSLog(@"Release invalid buffer");
                            continue;
                        }
                        
                        if (!CMTimeCompare(kCMTimeZero, firstCMTime))
                        {
                            firstCMTime = CMSampleBufferGetPresentationTimeStamp(nextSampleBuffer);
                        }
                        
                        CFArrayAppendValue(sampleBufArray, nextSampleBuffer);
                    }
                    
                    CFIndex curCount = CFArrayGetCount(sampleBufArray);
                    //                    NSLog(@"curCount=%ld", curCount);
                    if (curCount == 0) {
                        NSLog(@"continue??");
                        continue ;
                    }
                    
                    CMSampleBufferRef tmpBuf = (CMSampleBufferRef)CFArrayGetValueAtIndex(sampleBufArray, curCount - 1);
                    if (!CMTimeCompare(firstCMTime, CMSampleBufferGetPresentationTimeStamp(tmpBuf)) && curCount > 1) {
                        CFArrayRemoveValueAtIndex(sampleBufArray, curCount - 1);
                        //                        NSLog(@"firsttime:%f lasttime:%f", CMTimeGetSeconds(firstCMTime), CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(tmpBuf)));
                        
                        curCount = CFArrayGetCount(sampleBufArray);
                    }
                    firstCMTime = CMSampleBufferGetPresentationTimeStamp((CMSampleBufferRef)CFArrayGetValueAtIndex(sampleBufArray, 0));
                    
                    [reader cancelReading];
                    i = curCount - 1;//test test
                    k = 0;
                    count = (int)curCount;
                    
                    //                    testaa += count;
                    //                    NSLog(@"total count:%d/%d", count, testaa);
                    //                    for (int i = 0; i < count; i++) {
                    //                        CMSampleBufferRef sample = (CMSampleBufferRef)CFArrayGetValueAtIndex(sampleBufArray, i);
                    //                        NSLog(@"CMTimeGetSeconds:%f", CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sample)));
                    //                    }
                }
                
                CMSampleBufferRef sample =  k < count ? (CMSampleBufferRef)CFArrayGetValueAtIndex(sampleBufArray, i) : nil;
                if (sample) {
                    
                    CMSampleTimingInfo info;
                    CMSampleBufferGetSampleTimingInfo(sample, 0, &info);
                    
                    
                    info.presentationTimeStamp = info.decodeTimeStamp = tmpts;
                    tmpts = CMTimeAdd(tmpts, CMSampleBufferGetDuration(sample));
                    
                    info.duration = CMSampleBufferGetDuration(sample);
                    
                    //                    NSLog(@"smaple sample k:%d count:%d pts:%f dts:%f duration:%f", k, count, CMTimeGetSeconds(info.presentationTimeStamp),CMTimeGetSeconds(info.decodeTimeStamp), CMTimeGetSeconds(info.duration));
                    
                    CMSampleBufferRef newSample = nil;
                    
                    CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sample, 1, &info, &newSample);
                    
                    CFRelease(sample);
                    sample = nil;
                    
                    BOOL success = [assetWriterInput appendSampleBuffer:newSample];
                    if (!success && assetWriter.status == AVAssetWriterStatusFailed){
                        NSError *error = assetWriter.error;
                        NSLog(@"video error:%@", error.localizedDescription);
                        [assetWriterInput markAsFinished];
                        dispatch_group_leave(encodingGroup);
                        
                        CFRelease(newSample);
                        newSample = nil;
                        
                        break ;
                    }
                    
                    CFRelease(newSample);
                    newSample = nil;
                    
                    CFArrayRemoveValueAtIndex(sampleBufArray, i);
                    
                }
                else {
                    
                    break;
                }
                i--;
                k++;total++;
            }
        }];
    }
    
    if (audioTrack) {
        dispatch_group_enter(encodingGroup);
        [assetAudioWriterInput requestMediaDataWhenReadyOnQueue:myInputSerialQueue usingBlock:^{
            while ([assetAudioWriterInput isReadyForMoreMediaData]){
                //            CMSampleBufferRef sample = (__bridge CMSampleBufferRef)arr[i];
                CMSampleBufferRef sample =  [assetAudioReaderOutput copyNextSampleBuffer];
                if (sample) {
                    
                    BOOL success = [assetAudioWriterInput appendSampleBuffer:sample];
                    if (!success && assetWriter.status == AVAssetWriterStatusFailed){
                        NSError *error = assetWriter.error;
                        NSLog(@"audio error:%@", error.localizedDescription);
                        [assetAudioWriterInput markAsFinished];
                        dispatch_group_leave(encodingGroup);
                        
                        CFRelease(sample);
                        sample = nil;
                        break;
                        
                    }
                    //                    NSLog(@"write audio");
                    CFRelease(sample);
                    sample = nil;
                    
                }
                else {
                    
                    [assetAudioWriterInput markAsFinished];
                    dispatch_group_leave(encodingGroup);
                    
                    break;
                }
            }
        }];
    }
    dispatch_group_wait(encodingGroup, DISPATCH_TIME_FOREVER);
    
    [assetReader cancelReading];
    CFArrayRemoveAllValues(sampleBufArray);
    
    [assetWriter finishWritingWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (finishHandle) {
                finishHandle(assetWriter.error);
            }
        });
        
        assetWriter = nil;
        myInputSerialQueue = nil;
    }];
}

- (void) reverseVideo:(NSString *)sourceUrl outputURL:(NSString *)outputUrl videoSize:(HAVVideoSize)videoSize sourceKey:(BOOL)sourceKey cancel:(BOOL *)cancel progressHandle:(void (^)(CGFloat progress))progressHandle finishHandle:(void (^)(NSError *error))finishHandle{
    
    if (*(cancel)) {
        return ;
    }
    srcUrl = sourceUrl;
    //    NSError *error;
    //获取视频的总轨道
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:sourceUrl]];
    CMTime duration = asset.duration;
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (!videoTrack) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Not find video track" forKey:NSLocalizedDescriptionKey];
        NSError *err = [NSError errorWithDomain:@"ExportReversedFile" code:-10086 userInfo:userInfo];
        if (finishHandle){
            finishHandle(err);
        }
        return ;
    }
    
    NSMutableArray *timeRangeArray = [NSMutableArray array];
    NSMutableArray *startTimeArray = [NSMutableArray array];
    CMTime startTime = kCMTimeZero;
    for (NSInteger i = 0; i <(CMTimeGetSeconds(duration)); i ++) {
        CMTimeRange timeRange = CMTimeRangeMake(startTime, CMTimeMakeWithSeconds(1, duration.timescale));
        if (CMTimeRangeContainsTimeRange(videoTrack.timeRange, timeRange)) {
            [timeRangeArray addObject:[NSValue valueWithCMTimeRange:timeRange]];
        } else {
            timeRange = CMTimeRangeMake(startTime, CMTimeSubtract(duration, startTime));
            [timeRangeArray addObject:[NSValue valueWithCMTimeRange:timeRange]];
        }
        [startTimeArray addObject:[NSValue valueWithCMTime:startTime]];
        startTime = CMTimeAdd(timeRange.start, timeRange.duration);
    }
    
    NSMutableArray *tracks = [NSMutableArray array];
    NSMutableArray *assets = [NSMutableArray array];
    
    for (NSInteger i = 0; i < timeRangeArray.count; i ++) {
        AVMutableComposition *subAsset = [[AVMutableComposition alloc]init];
        AVMutableCompositionTrack *subTrack =   [subAsset addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [subTrack  insertTimeRange:[timeRangeArray[i] CMTimeRangeValue] ofTrack:videoTrack atTime:[startTimeArray[i] CMTimeValue] error:nil];
        
        AVAsset *assetNew = [subAsset copy];
        AVAssetTrack *assetTrackNew = [[assetNew tracksWithMediaType:AVMediaTypeVideo] lastObject];
        [tracks addObject:assetTrackNew];
        [assets addObject:assetNew];
        
    }
    
    if (sourceKey) {
        [self kickOffOnlyIFrame:asset outputURL:outputUrl tracks:tracks assets:assets startTimeArray:startTimeArray  videoSize:videoSize cancel:cancel progressHandle:progressHandle finishHandle:finishHandle];
    }else {
        [self kickOffAny:asset outputURL:outputUrl tracks:tracks assets:assets startTimeArray:startTimeArray  videoSize:videoSize cancel:cancel progressHandle:progressHandle finishHandle:finishHandle];
        
    }
}

- (CGFloat)exportProgress
{
    return self.exportMovie2.progress;
    //return self.exportSession.progress;
}

- (void)exportAsynVideo:(NSArray <NSURL *> *)sourcePathArray
               audioUrl:(NSURL *)audioUrl totalTimeRange:(CMTimeRange)totalTimeRange storePath:(NSString *)storePath filters:(NSArray *)filters STProcessing:(NSDictionary *)stprocessing bitRate:(int)bitrate need720P:(BOOL)need720P finished:(void (^)(NSError *error))finished
{
    
    return [self exportAsynVideoWithSetting:sourcePathArray audioUrl:audioUrl totalTimeRange:totalTimeRange storePath:storePath filters:filters STProcessing:stprocessing bitRate:bitrate need720P:need720P finished:finished];
}

- (void)exportAsynVideoWithSetting:(NSArray <NSURL *> *)sourcePathArray
                          audioUrl:(NSURL *)audioUrl totalTimeRange:(CMTimeRange)totalTimeRange storePath:(NSString *)storePath filters:(NSArray *)filters STProcessing:(NSDictionary *)stprocessing bitRate:(int)bitRate  need720P:(BOOL)need720P  finished:(void (^)(NSError *error))finished
{
    //store parms
    
    self.hasCancel = YES;
    if (!self.hasCancel)
    {
        self.sourcePathArray = sourcePathArray;
        self.audioUrl = audioUrl;
        self.totalTimeRange = totalTimeRange;
        self.storePath = storePath;
        self.filters = [NSArray arrayWithArray:filters];
        self.stprocessing = stprocessing;
        self.bitRate = bitRate;
        self.need720P = need720P;
    }
    
    if (!sourcePathArray.count)
    {
        if (finished)
        {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"sourcePathArray can not be nil"
                                                                 forKey:NSLocalizedDescriptionKey];
            NSError *aError = [NSError errorWithDomain:@"exportAsynSegmentedVideo" code:10010 userInfo:userInfo];
            finished(aError);
        }
        return ;
    }
    
    if (storePath)
    {
        [[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
    }
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    
    /*
     AVMutableCompositionTrack *audioComposition = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
     AVMutableCompositionTrack *videoComposition = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:0];
     */
    
    bool hasAudio = false;
    
    CGSize sourceSize = CGSizeZero;
    CMTime timeOffset = kCMTimeZero;
    for (NSURL *url in sourcePathArray)
    {
        AVAsset *asset = [AVAsset assetWithURL:url];
        AVAssetTrack *vTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        if (vTrack)
        {
            if (sourceSize.width == 0 || sourceSize.height == 0)
            {
                sourceSize.width = vTrack.naturalSize.width;
                sourceSize.height = vTrack.naturalSize.height;
            }
        }
        
        if ([[asset tracksWithMediaType:AVMediaTypeAudio] firstObject])
        {
            AVAssetTrack *aTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            [self getAudioInfo:aTrack];
            hasAudio = true;
        }
        
        /*
         
         if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 1)
         {
         [audioComposition insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio].lastObject atTime:timeOffset error:nil];
         }else if([asset tracksWithMediaType:AVMediaTypeAudio].count == 1)
         {
         [audioComposition insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio].firstObject atTime:timeOffset error:nil];
         }
         
         [videoComposition insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:timeOffset error:nil];
         */
        
        [mutableComposition insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofAsset:asset atTime:timeOffset error:nil];
        
        timeOffset = CMTimeAdd(timeOffset, asset.duration);
        
    }
    if (audioUrl)
    {
        hasAudio = true;
        NSArray *tracks = [mutableComposition tracksWithMediaType:AVMediaTypeAudio];
        for (AVCompositionTrack *atrack in tracks) {
            [mutableComposition removeTrack:atrack];
        }
        AVAsset *audioAsset = [AVAsset assetWithURL:audioUrl];
        AVAssetTrack *audioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        AVMutableCompositionTrack *t = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        if (CMTimeCompare(audioAsset.duration, timeOffset) > 0) {
            ///截取部分音频
            [t insertTimeRange:CMTimeRangeMake(kCMTimeZero, timeOffset) ofTrack:audioTrack atTime:kCMTimeZero error:nil];
        }
        else {
            ///循环音频
            for (CMTime i = kCMTimeZero; CMTimeCompare(i, timeOffset) < 0; ) {
                [t insertTimeRange:CMTimeRangeMake(kCMTimeZero, timeOffset) ofTrack:audioTrack atTime:i error:nil];
                i = CMTimeAdd(i, timeOffset);
                if (CMTimeCompare(i, timeOffset) > 0) {
                    [t insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(timeOffset, CMTimeSubtract(i, timeOffset))) ofTrack:audioTrack atTime:CMTimeSubtract(i, timeOffset) error:nil];
                }
            }
        }
        [self getAudioInfo:audioTrack];
    }
    
    
    AVMutableComposition* resultComposition = [AVMutableComposition composition];
    if (CMTimeGetSeconds(totalTimeRange.duration) > 0)
    {
        if (CMTimeCompare(CMTimeAdd(totalTimeRange.start, totalTimeRange.duration), timeOffset) > 0) {
            NSAssert(false, @"Too big range request!!!");
        }
        
        AVMutableCompositionTrack *audio = [resultComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
        AVMutableCompositionTrack *video = [resultComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:0];
        
        [audio insertTimeRange:totalTimeRange ofTrack:[mutableComposition tracksWithMediaType:AVMediaTypeAudio].firstObject atTime:kCMTimeZero error:nil];
        
        [video insertTimeRange:totalTimeRange ofTrack:[mutableComposition tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:kCMTimeZero error:nil];
    }
    
    if ( CMTimeGetSeconds(totalTimeRange.duration) > 0.f)
    {
        self.exportMovie2 = [[GPUImageMovie alloc] initWithAsset:resultComposition];
    }else
    {
        self.exportMovie2 = [[GPUImageMovie alloc] initWithAsset:mutableComposition];
    }
    
    self.exportMovie2.disableAudioCodecCopy = stprocessing ? YES : NO;
    self.asset = [AVAsset assetWithURL:sourcePathArray[0]];
    GPUImageRotationMode currentRotation = [self outputRotation];
    sourceSize = [self outputSize:sourceSize currentRotation:currentRotation];
    
    sourceSize = [self adjustOutSize:sourceSize need720p:NO];
    
    
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey, @(sourceSize.width),AVVideoWidthKey,@(sourceSize.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                   AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
    
    if(self.bitRate > 0)
    {
        [compressionProperties setObject:@(self.bitRate) forKey:AVVideoAverageBitRateKey];
    }
    
    [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
    if (settings)
    {
        
        self.exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[NSURL fileURLWithPath:storePath] size:sourceSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
    }
    else
    {
        self.exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[NSURL fileURLWithPath:storePath] size:sourceSize];
    }
    
    self.exportMovieWriter.shouldPassthroughAudio = !self.exportMovie2.disableAudioCodecCopy;
    [self.exportMovieWriter setInputRotation:currentRotation atIndex:0];
    
   
    self.exportMovie.playAtActualSpeed = NO;
    self.exportMovieWriter.encodingLiveVideo = YES;
    
    self.exportMovie2.audioEncodingTarget = hasAudio ? self.exportMovieWriter : nil;
    [self.exportMovie2 enableSynchronizedEncodingUsingMovieWriter:self.exportMovieWriter];
    
    //    __weak typeof(self) weakSelf = self;
    __unsafe_unretained HAVMovieAssetExport *weakSelf = self;
    ///成功
    [self.exportMovieWriter setCompletionBlock:^{
        NSLog(@"%s write finished.", __FUNCTION__);
        [weakSelf.exportMovie2 endProcessing];
        [weakSelf.exportMovieWriter finishRecordingWithCompletionHandler:^{
            
#ifdef bEnablePurgeBuffer
            [[GPUImageContext sharedFramebufferCache] purgeTextureFramebuffers:[weakSelf.exportMovie2 framebufferForOutput]];
#else
            [[GPUImageContext sharedFramebufferCache] purgeTextureFramebuffers];
#endif
            
            
            
            if (finished)
            {
                finished(nil);
            }
        }];
    }];
    ///失败
    [self.exportMovieWriter setFailureBlock:^(NSError *error){
        NSLog(@"%s write error.", __FUNCTION__);
        [weakSelf.exportMovie2 endProcessing];
        if (finished)
        {
            finished(error);
        }
    }];
    if (filters.count > 0)
    {
        for (id f in filters)
        {
            if ([f isKindOfClass:[HAVScrawlAndTextFilter class]])
            {
                ((HAVScrawlAndTextFilter *)f).rotationMode = currentRotation;
            }else if ([f isKindOfClass:[HAVGifFilter class]])
            {
                
                // ((HAVLoadGifFilter *)f).gifRotationMode = currentRotation;
                ((HAVGifFilter *)f).gifRotationMode = currentRotation;
            }
            
            
            
        }
        for (GPUImageFilter* filter in filters)
        {
            [filter removeAllTargets];
            [filter reset];
        }
        
        self.exportPipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:filters input:self.exportMovie2 output:self.exportMovieWriter];
    }
    else {
        [self.exportMovie2 addTarget:self.exportMovieWriter];
    }
    
    [self.exportMovieWriter startRecording];
    [self.exportMovie2 startProcessing];
    self.hasCancel = NO;
    
}


#pragma mark - Private

- (void)getAudioInfo:(AVAssetTrack *)audioTrack{
    CMFormatDescriptionRef cmformat = (__bridge CMFormatDescriptionRef)([audioTrack.formatDescriptions objectAtIndex:0]);
    AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(cmformat);
    _samplerate = (float)asbd->mSampleRate;
    _channels = (int)asbd->mChannelsPerFrame;
    
    NSAssert((_samplerate != 0 && _channels != 0), @"samplerate or channels can not be zero!");
}

- (AudioStreamBasicDescription)getAudioFormat
{
    
    Float64 samplerate = _samplerate;
    UInt32 channels = _channels;
    AudioStreamBasicDescription format;
    format.mSampleRate = samplerate;
    format.mFormatID = kAudioFormatLinearPCM;
    format.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger;
    format.mBitsPerChannel = 16;
    format.mChannelsPerFrame = channels;//self.audioInfo->mChannelsPerFrame;
    format.mBytesPerFrame = format.mBitsPerChannel / 8 * format.mChannelsPerFrame;
    format.mFramesPerPacket = 1;//audioInfo->mFramesPerPacket;
    format.mBytesPerPacket = format.mBytesPerFrame*format.mFramesPerPacket;
    format.mReserved = 0;
    return format;
}

- (CMSampleBufferRef)createAudioSample:(void *)audioData frames:(UInt32)len
{
    Float64 samplerate = _samplerate;
    UInt32 channels = _channels;
    NSLog(@"channels:%d", channels);
    AudioBufferList audioBufferList;
    audioBufferList.mNumberBuffers = 1;
    audioBufferList.mBuffers[0].mNumberChannels=channels;
    audioBufferList.mBuffers[0].mDataByteSize=len;
    audioBufferList.mBuffers[0].mData = audioData;
    AudioStreamBasicDescription asbd = [self getAudioFormat];
    CMSampleBufferRef buff = NULL;
    
    //static CMFormatDescriptionRef format = NULL;
    CMFormatDescriptionRef format = NULL;
    
    CMTime time = CMTimeMake(len/2 , samplerate);
    
    CMSampleTimingInfo timing = {CMTimeMake(1,samplerate), time, kCMTimeInvalid };
    
    OSStatus error = 0;
    if(format == NULL){
        error = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &asbd, 0, NULL, 0, NULL, NULL, &format);
        if (error) {
            NSLog(@"CMAudioFormatDescriptionCreate returned error: %ld", (long)error);
            return NULL;
        }
    }
    
    error = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, len/(2*channels), 1, &timing, 0, NULL, &buff);
    if ( error ) {
        NSLog(@"CMSampleBufferCreate returned error: %ld", (long)error);
        return NULL;
    }
    
    error = CMSampleBufferSetDataBufferFromAudioBufferList(buff, kCFAllocatorDefault, kCFAllocatorDefault, 0, &audioBufferList);
    if( error )
    {
        NSLog(@"CMSampleBufferSetDataBufferFromAudioBufferList returned error: %ld", (long)error);
        return NULL;
    }
    return buff;
}

-(CGSize)adjustOutSize:(CGSize)size need720p:(BOOL)need720p
{
    NSAssert(size.width == 0 || size.height, @"输入尺寸invalid");
    int widthInt = (int)size.width;
    int heightInt = (int)size.height;
    
    float ratio;
    if (heightInt > widthInt)
    {
        ratio = (float) widthInt / heightInt;
    } else
    {
        ratio = (float) heightInt / widthInt;
    }
    int w, h;
    if (need720p)
    {
        w = 1280;
        h = 720;
    } else
    {
        w = CodecConstant_VIDEO_HEIGHT;
        h = CodecConstant_VIDEO_WIDTH;
    }
    if (ratio < 0.6)
    { // 16:9
        if (widthInt < heightInt)
        {
            heightInt = w;
            widthInt = h;
        } else
        {
            widthInt = w;
            heightInt = h;
        }
    } else if (ratio < 0.85)
    { // 4:3
        if (widthInt < heightInt)
        {
            heightInt = h * 4 / 3;
            // 被2整除
            if (heightInt % 2 != 0)
            {
                heightInt = heightInt + 1;
            }
            widthInt = h;
        } else
        {
            widthInt = h * 4 / 3;
            heightInt = h;
            // 被16 整除
            widthInt = ((widthInt + 0xF) & (~0xF));
        }
    } else
    { //1:1
        widthInt = heightInt = h;
    }
    return CGSizeMake(widthInt, heightInt);
    
}

- (CGSize)outputSize:(CGSize)sourceSize currentRotation:(GPUImageRotationMode)currentRotation{
    
    CGSize srcSize = CGSizeZero;
    switch (currentRotation) {
        case kGPUImageRotateLeft:
        case kGPUImageRotateRight:
            srcSize = CGSizeMake(sourceSize.height, sourceSize.width);
            break;
            
        default:
            srcSize = sourceSize;
            break;
    }
    return srcSize;
}

-(void)undoExport2
{
    runSynchronouslyOnVideoProcessingQueue(^{
        glFinish();
    });
    self.hasCancel = YES;
    [self.exportMovieWriter cancelRecording];
    [self.exportMovie2 cancelProcessing];
    [self.exportMovieWriter setCompletionBlock:nil];
    [self.exportMovieWriter setFailureBlock:nil];
    
}

-(void)reStartExport:(void (^)(NSError *error))finished;
{
    [self exportAsynVideo:self.sourcePathArray audioUrl:self.audioUrl totalTimeRange:self.totalTimeRange storePath:self.storePath filters:self.filters STProcessing:self.stprocessing bitRate:self.bitRate need720P:self.need720P finished:^(NSError *error)
    {
        finished(error);
    }];
    
}

@end

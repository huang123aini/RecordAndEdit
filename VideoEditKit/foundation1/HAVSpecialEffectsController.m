//
//  HAVSpecialEffectsController.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVSpecialEffectsController.h"
#import "AVAsset+MetalData.h"
#import "HAVMovieReader.h"
#import "HAVSpliteFilter.h"
#import "HAVQuickSpeedImageMovie.h"
#import <GPUKit/GPUKit.h>

#import "DCVideoCamera.h"
#import "DCSpecialEffectsView.h"

@interface HAVSpecialEffectsController()<AVCaptureVideoDataOutputSampleBufferDelegate
,GPUImageVideoCameraDelegate>
{
    dispatch_block_t cleanupBlock;
    
}

@property (nonatomic, weak) id <HAVGPUImageFilterDataSource> __nullable filterDataSource;
@property (nonatomic, weak) id <HAVStreamPickerFaceTrackDelegate> __nullable faceTrackDelegate;
@property (nonatomic, strong)DCSpecialEffectsView* specialEffectsView;
@property (nonatomic, strong) GPUImageOutput* mPreviewDataSource;
@property (nonatomic, strong) GPUImageMovieWriter* movieWriter;
@property (nonatomic, strong) GPUImageMovieWriter* movieWriter2;
@property (nonatomic, strong) GPUImageFilterPipeline* pipeline;
@property (nonatomic, strong) GPUImageFilter <GPUImageInput>* skinFilter;
@property (nonatomic, strong) GPUImageFilter <GPUImageInput>* snapshotFilter;
@property (nonatomic, strong) GPUImageMovieWriter* exportMovieWriter;
@property (nonatomic, strong) GPUImageFilterPipeline* exportPipeline;
@property (nonatomic, strong) GPUImageMovie* gpuMovie;
@property (nonatomic, assign) int fps;


@property (nonatomic,assign)BOOL isExportAbort;
@property(nonatomic,assign)double currentSectionTime;

@property (nonatomic, strong) NSMutableArray *arrayWriter;

@end

@implementation HAVSpecialEffectsController

- (instancetype) init{
    self = [super init];
    if(self){
        _filterManager = [[HAVGPUImageFilterManager alloc] init];
        self.filterDataSource = self.filterManager;
        self.faceTrackDelegate = self.filterManager;
        self.movieWriter = nil;
        self.fps = 30;
        
    }
    return self;
}

- (void) setSpecialEffectsView:(HAVSpecialEffectsView *)view
{
    _specialEffectsView = view;
    if((self.mPreviewDataSource != nil) && (_specialEffectsView != nil))
    {
        [self changeGPUPipeline];
    }
}


- (void) setPreViewDataSource:(GPUImageOutput*) previewDataSource
{
    if(previewDataSource != nil)
    {
        if(self.mPreviewDataSource != nil)
        {
            [self.mPreviewDataSource removeAllTargets];
        }
        self.mPreviewDataSource = previewDataSource;
        if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
        {
            DCVideoCamera* camera = (DCVideoCamera *)self.mPreviewDataSource;
            [camera addAudioInputsAndOutputs];
            camera.delegate = self;
        }
        
        if((self.mPreviewDataSource != nil) && (self.specialEffectsView != nil)){
            [self changeGPUPipeline];
        }
    }
}

- (void) setPlayRate:(CGFloat) rate
{
    if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
    {
        DCVideoCamera* camera = (DCVideoCamera *)self.mPreviewDataSource;
        [camera setPlayRate:rate];
    }
}

- (void) setFps:(int) fps
{
    _fps = fps;
}



- (CGSize) cameraSize:(DCVideoCamera* )camera
{
    CGSize size = CGSizeMake(720, 1280);
    NSString *present = camera.captureSession.sessionPreset;
    if( AVCaptureSessionPreset640x480 == present){
        size = CGSizeMake(480, 640);
    }else if(AVCaptureSessionPreset1920x1080 == present){
        size = CGSizeMake(1080, 1920);
    }else if(AVCaptureSessionPreset352x288 == present){
        size = CGSizeMake(288, 352);
    }else if(AVCaptureSessionPreset1920x1080 ==  present){
        size = CGSizeMake(1080, 1920);
    }
    
    return  size;
}

- (void) saveVideoToFile:(NSString *) localPath bitRate:(NSInteger) bitRate warterMark:(GPUImageWritterWaterMark *)waterMark{
    
    if (![localPath isKindOfClass:[NSString class]] || [localPath length] < 10) {
        return;
    }
    if (self.movieWriter) {
        [self.movieWriter finishRecording];
        
    }
    self.movieWriter = nil;
    NSURL *movieURL = [NSURL fileURLWithPath:localPath];
    if(movieURL != nil){
        if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
        {
            DCVideoCamera* camera = (DCVideoCamera *)self.mPreviewDataSource;
            CGSize size = [self cameraSize:camera];
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             AVVideoCodecH264,AVVideoCodecKey,@(size.width),AVVideoWidthKey,
                                             @(size.height),AVVideoHeightKey,
                                             @(YES),@"EncodingLiveVideo",
                                             nil];
            
            
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey,AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            self.movieWriter= [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:size fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            camera.audioEncodingTarget = self.movieWriter;
            if(waterMark != nil){
                self.movieWriter.waterMark = waterMark;
            }
            [self changeGPUPipeline];
            [self.movieWriter startRecording2];
            if(self.specialEffectsView != nil) {
                self.specialEffectsView.voidFrame =  NO;
            }
        }
    }
    
}

- (void) saveVideoToFileWithOutAudio:(NSString *) localPath bitRate:(NSInteger) bitRate warterMark:(GPUImageWritterWaterMark *)waterMark{
    if (![localPath isKindOfClass:[NSString class]] || [localPath length] < 10) {
        return;
    }
    if (self.movieWriter)
    {
        [self.movieWriter finishRecording];
        
    }
    self.movieWriter = nil;
    NSURL *movieURL = [NSURL fileURLWithPath:localPath];
    if(movieURL != nil)
    {
        if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
        {
            DCVideoCamera* camera = (DCVideoCamera *)self.mPreviewDataSource;
            CGSize size = [self cameraSize:camera];
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             AVVideoCodecH264,AVVideoCodecKey,@(size.width),AVVideoWidthKey,
                                             @(size.height),AVVideoHeightKey,
                                             @(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey,AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
            
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            self.movieWriter= [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:size fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            if(waterMark != nil){
                self.movieWriter.waterMark = waterMark;
            }
            [self changeGPUPipeline];
            [self.movieWriter startRecording2];
            if(self.specialEffectsView != nil)
            {
                self.specialEffectsView.voidFrame =  NO;
            }
        }
    }
}

- (void) saveVideoToFileWithOutAudio:(NSString *) localPath warterMark:(GPUImageWritterWaterMark *)waterMark
{
    if (![localPath isKindOfClass:[NSString class]] || [localPath length] < 10)
    {
        return;
    }
    if (self.movieWriter)
    {
        [self.movieWriter finishRecording];
        
    }
    if(self.pipeline != nil)
    {
        [self.pipeline setOutput:nil];
        [self.pipeline refreshChanges];
    }
    
    self.movieWriter = nil;
    NSURL *movieURL = [NSURL fileURLWithPath:localPath];
    if(movieURL != nil)
    {
        if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
        {
            DCVideoCamera* camera = (DCVideoCamera *)self.mPreviewDataSource;
            CGSize size = [self cameraSize:camera];
            self.movieWriter= [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:size];
            
            if(waterMark != nil)
            {
                self.movieWriter.waterMark = waterMark;
            }
            [self changeGPUPipeline];
            [self.movieWriter startRecording];
        }
    }
}

- (void) saveVideoToFile:(NSString *) localPath warterMark:(GPUImageWritterWaterMark *)waterMark
{
    if (![localPath isKindOfClass:[NSString class]] || [localPath length] < 10)
    {
        return;
    }
    if (self.movieWriter)
    {
        [self.movieWriter finishRecording];
        
    }
    self.movieWriter = nil;
    NSURL *movieURL = [NSURL fileURLWithPath:localPath];
    if(movieURL != nil)
    {
        if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
        {
            DCVideoCamera* camera = (DCVideoCamera *)self.mPreviewDataSource;
            CGSize size = [self cameraSize:camera];
            self.movieWriter= [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:size];
            camera.audioEncodingTarget = self.movieWriter;
            if(waterMark != nil)
            {
                self.movieWriter.waterMark = waterMark;
            }
            [self changeGPUPipeline];
            [self.movieWriter startRecording];
        }
    }
}

- (void) stopSaveFile
{
    if(self.movieWriter != nil)
    {
        if(self.specialEffectsView != nil)
        {
            self.specialEffectsView.voidFrame = self.supportGhost? YES:NO;
        }
        [self.movieWriter setPaused:YES];
        __block GPUImageMovieWriter *writer = self.movieWriter;
        
        [writer finishRecordingWithCompletionHandler:^{
            
            self.currentSectionTime = writer.sectionTime;
            writer = nil;
        }];
        
        self.movieWriter = nil;
        [self changeGPUPipeline];
    }
}

- (void) changeGPUPipeline
{
    DCVideoCamera* camera =  nil;
    if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
    {
        camera = (DCVideoCamera *)self.mPreviewDataSource;
    }
    
    if((camera != nil) && (camera.captureSession != nil))
    {
        [camera  pauseCameraCapture];
        [camera.captureSession beginConfiguration];
    }
    
    if(self.mPreviewDataSource != nil)
    {
        if(cleanupBlock) {
            cleanupBlock();
        }
        
        //清理上次GPUImage缓存
#ifdef bEnablePurgeBuffer
        GPUImageFramebuffer *frameBuffer = [camera framebufferForOutput];
        [[GPUImageContext sharedFramebufferCache] purgeTextureFramebuffers:frameBuffer];
#else
        [[GPUImageContext sharedFramebufferCache] purgeTextureFramebuffers];
#endif
        
        
        
        NSMutableArray *filterList = [NSMutableArray arrayWithCapacity:8];
        if (self.filterDataSource && [self.filterDataSource respondsToSelector:@selector(filterListForGPUImage)]) {
            NSMutableArray *tmp = [self.filterDataSource filterListForGPUImage];
            if ([tmp count]) {
                [filterList addObjectsFromArray:tmp];
            }
        }
        GPUImageFilter *showOnlyFilter = nil;
        for (GPUImageFilter *filter in filterList){
            if([filter respondsToSelector:@selector(showOnly)]){
                if(filter.showOnly){
                    [filterList removeObject:filter];
                    showOnlyFilter = filter;
                    break;
                }
            }
        }///GPUImageSharpenFilter
        [self.skinFilter removeAllTargets];
        [self.snapshotFilter removeAllTargets];
        [self.pipeline removeAllFilters];
        self.pipeline = nil;
        self.skinFilter = nil;
        self.snapshotFilter = nil;
        GPUImageSharpenFilter *filter = [[GPUImageSharpenFilter alloc] init];
        [filter setSharpness:0.25];
        self.skinFilter = filter;
        //self.skinFilter = [[GPUImageFilter alloc]init];
        self.snapshotFilter = [[GPUImageFilter alloc] init];
        
        NSMutableArray *arrayTemp = [[NSMutableArray alloc]init];
        dispatch_block_t addingBlock=^{
            if(self.specialEffectsView != nil){
                if(showOnlyFilter != nil){
                    [showOnlyFilter addTarget:self.specialEffectsView];
                    [self.snapshotFilter addTarget:showOnlyFilter];
                }else{
                    [self.snapshotFilter addTarget:self.specialEffectsView];
                }
            }
        };
        
        [arrayTemp addObject:self.skinFilter];
        
        if ([filterList count]) {
            [arrayTemp addObjectsFromArray:filterList];
        }
        
        [arrayTemp addObject:self.snapshotFilter];
        id <GPUImageInput> gpuInput = self.movieWriter;
        [self.movieWriter setRecord:YES];
        self.pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:arrayTemp input:self.mPreviewDataSource output:gpuInput];
        addingBlock();
    }
    
    if((camera != nil) && (camera.captureSession != nil)) {
        [camera  resumeCameraCapture];
        [camera.captureSession commitConfiguration];
    }
}


-(void)startGhost
{
    if(self.specialEffectsView != nil)
    {
        self.specialEffectsView.voidFrame =  YES;
    }
}

- (void) stopGhost{
    if(self.specialEffectsView != nil)
    {
        self.specialEffectsView.voidFrame =  NO;
    }
}

- (void) clearGhost
{
    if(self.specialEffectsView != nil)
    {
        self.specialEffectsView.voidFrame =  NO;
    }
}

-(void)setIsBattle:(BOOL)isBattle
{
    if (self.specialEffectsView != nil)
    {
        self.specialEffectsView.isSplite = isBattle;
    }
}


- (void)setGhostImage:(UIImage *) image{
    if(self.specialEffectsView != nil) {
        return [self.specialEffectsView setGhostImage:image];
    }
}

- (UIImage *) getCurrentGhostImage{
    if(self.specialEffectsView != nil) {
        return [self.specialEffectsView currentGhostImage];
    }
    
    return nil;
    
}
- (void) getCurrentGhostImage:(void (^) (UIImage *)) hander{
    if(self.specialEffectsView != nil) {
        [self.specialEffectsView currentGhostImage :hander];
    }
}

- (double) getCurrentSectionTime
{
    return self.currentSectionTime;
}

- (void) dealloc
{
    [self.pipeline removeAllFilters];
    [self.mPreviewDataSource removeAllTargets];
    self.filterDataSource = nil;
    self.faceTrackDelegate = nil;
    [self.filterManager resetAllFilterController];
    _filterManager = nil;
    if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
    {
        DCVideoCamera* camera = (DCVideoCamera *)self.mPreviewDataSource;
        camera.delegate = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"dealloc %s, %s",__FILE__ ,__FUNCTION__);
}

#pragma mark --- FaceTrack
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (self.faceTrackDelegate && [self.faceTrackDelegate respondsToSelector:@selector(succToPickWithStreamBufferForFaceTrack:position:)]) {
        CMSampleBufferRef sbufCopyOut;
        CMSampleBufferCreateCopy(CFAllocatorGetDefault(), sampleBuffer, &sbufCopyOut);
        if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
        {
            DCVideoCamera *camera = (DCVideoCamera *)self.mPreviewDataSource;
            [self.faceTrackDelegate succToPickWithStreamBufferForFaceTrack:sbufCopyOut position:[camera cameraPosition]];
        }
        
        CFRelease(sbufCopyOut);
    }
}


- (void) saveVideoToPath:(NSString *)outPath withHandler:(void (^) (BOOL status, NSString *outPath, NSError *error))handler{
    [self saveVideoToPath:outPath videoSize:HAVVideoSizeNature withHandler:handler];
}

- (void) saveVideoToPath:(NSString *)outPath videoSize:(HAVVideoSize) avVideoSize withHandler:(void (^) (BOOL status, NSString *outPath, NSError *error))handler
{
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]])
    {
        HAVMovieReader *reader = (HAVMovieReader *)self.mPreviewDataSource;
        [reader stop];
        [reader saveVideoToPath:outPath videoSize:avVideoSize withHandler:handler];
    }
}


-(void)applicationEnterBackground
{
    self.isExportAbort = YES;
    
    NSLog(@"applicationEnterBackground self.isExportAbort:%d",self.isExportAbort);
    NSLog(@"self.gpuMovie.progress:%f",self.gpuMovie.progress);
    if (self.gpuMovie.progress != 1.0f)
    {
        
        [self.gpuMovie cancelProcessing];
        [self.exportMovieWriter cancelRecording];
        
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) exportVideo:(NSString *)outPath bitRate:(NSInteger) bitRate videoRequestSize:(HAVVideoSize)videoRequestSize metaData:(NSString *) metaData withHandler:(void (^) (BOOL status, NSString *outPath, NSError *error))handler
{
    
    self.isExportAbort = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name: UIApplicationDidEnterBackgroundNotification object:nil];
    
    
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]])
    {
        
        if(outPath != nil)
        {
            unlink([outPath UTF8String]);
        }
        HAVMovieReader *reader = (HAVMovieReader *)self.mPreviewDataSource;
        [reader stop];
        [reader pauseMediaPlayer];
        NSMutableArray *filterList = [NSMutableArray arrayWithCapacity:8];
        if (self.filterDataSource && [self.filterDataSource respondsToSelector:@selector(filterListForGPUImage)])
        {
            NSMutableArray *tmp = [self.filterDataSource filterListForGPUImage];
            if ([tmp count])
            {
                [filterList addObjectsFromArray:tmp];
            }
        }
        GPUImageFilter <GPUImageInput> *skinFilter = [[GPUImageFilter alloc] init];
        NSMutableArray *arrayTemp = [[NSMutableArray alloc]init];
        [arrayTemp addObject:skinFilter];
        
        if ([filterList count]) {
            [arrayTemp addObjectsFromArray:filterList];
        }
        
        if (self.filterDataSource.filterListForGPUImage.count > 0) {
            [arrayTemp addObjectsFromArray:self.filterDataSource.filterListForGPUImage];
        }
        AVAsset *inputAsset = [reader getAsset];
        NSURL *url = [NSURL fileURLWithPath:outPath];
        BOOL hasAudio = ([[inputAsset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
        CGSize videoSize = [inputAsset videoSize:videoRequestSize];
        
        if(url != nil){
            
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             AVVideoCodecH264,AVVideoCodecKey,
                                             @(videoSize.width),AVVideoWidthKey,
                                             @(videoSize.height),AVVideoHeightKey,
                                             @(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary * compressionProperties = nil;
            
            if(bitRate > 0){
                compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                         @(bitRate),AVVideoAverageBitRateKey,
                                         AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,
                                         nil];
            }else{
                compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                         AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,
                                         nil];
            }
            
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            self.exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            
            if(metaData.length > 0){
                AVMutableMetadataItem *descriptionMetadata = [AVMutableMetadataItem metadataItem];
                
                descriptionMetadata.key = AVMetadataCommonKeyDescription;
                descriptionMetadata.keySpace = AVMetadataKeySpaceCommon;
                descriptionMetadata.locale = [NSLocale currentLocale];
                descriptionMetadata.value = metaData;
                [self.exportMovieWriter setMetaData:@[descriptionMetadata]];
            }
            if(inputAsset != nil){
                
                //                HAVQuickSpeedImageMovie
                self.gpuMovie = [[HAVQuickSpeedImageMovie alloc] initWithAsset:inputAsset];
                self.gpuMovie.playAtActualSpeed = NO;
                self.gpuMovie.audioEncodingTarget = hasAudio?self.exportMovieWriter:nil;
                self.exportMovieWriter.hasAudioTrack = hasAudio;
                self.exportMovieWriter.encodingLiveVideo = YES;
                
                [self.gpuMovie enableSynchronizedEncodingUsingMovieWriter:self.exportMovieWriter];
                self.exportPipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:arrayTemp input:self.gpuMovie output:self.exportMovieWriter];
                __block GPUImageFilterPipeline *pipeLine = self.exportPipeline;
                __block GPUImageMovieWriter *movieWritter = self.exportMovieWriter;
                __block GPUImageMovie *movieFile = self.gpuMovie;
                
                //                __weak __typeof(self) weakSelf = self;
                
                [self.exportMovieWriter setCompletionBlock:^{
                    [pipeLine removeAllFilters];
                    [movieFile endProcessing];
                    
                    if (movieFile.progress != 1.0f)
                    {
                        [movieWritter finishRecordingWithCompletionHandler:^{
                            
                            [movieWritter setFailureBlock:nil];
                            [movieWritter setCompletionBlock:nil];
                            
                            NSLog(@"我在这个时候发送了通知");
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:ENTERBACKGROUND_EXPORTABORT object:nil];
                            });
                            
                            
                            if (handler != nil)
                            {
                                handler(NO, outPath, nil);
                            }
                            
                            return;
                        }];
                        
                    }else
                    {
                        [movieWritter finishRecordingWithCompletionHandler:^{
                            
                            [movieWritter setFailureBlock:nil];
                            [movieWritter setCompletionBlock:nil];
                            
                            if (handler != nil)
                            {
                                handler(YES, outPath, nil);
                            }
                            
                            return;
                        }];
                    }
                    
                }];
                [self.exportMovieWriter startRecording];
                [self.gpuMovie startProcessing];
            }else{
                
            }
        }
    }
    
}

- (void) saveVideoTo2File:(NSString *) nonKeyPath keyPath:(NSString *)keyPath nonKeyRate:(NSInteger) bitRate keyRate:(NSInteger)bitrate2 warterMark:(GPUImageWritterWaterMark *)waterMark useOriginalAudio:(BOOL)use{
    if (![nonKeyPath isKindOfClass:[NSString class]] || [nonKeyPath length] < 10) {
        return;
    }
    
    [self.pipeline removeAllFilters];
    self.pipeline = nil;
    
    for (int i = 0; i < self.arrayWriter.count; i++) {
        GPUImageMovieWriter *wr = self.arrayWriter[i];
        if (wr)
        {
            [wr finishRecording];
            wr = nil;
        }
    }
    [self.arrayWriter removeAllObjects];
    
    NSURL *movieURL = [NSURL fileURLWithPath:nonKeyPath];
    NSURL *movieURL2 = [NSURL fileURLWithPath:keyPath];
    if(movieURL && movieURL2)
    {
        if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
        {
            DCVideoCamera* camera = (DCVideoCamera *)self.mPreviewDataSource;
            CGSize size = [self cameraSize:camera];
            
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             AVVideoCodecH264,AVVideoCodecKey,@(size.width),AVVideoWidthKey,
                                             @(size.height),AVVideoHeightKey,
                                             @(YES),@"EncodingLiveVideo",nil];
            
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey,AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            
            
            NSMutableDictionary *settings2 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                              AVVideoCodecH264,AVVideoCodecKey,@(size.width),AVVideoWidthKey,
                                              @(size.height),AVVideoHeightKey,
                                              @(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary *compressionProperties2 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey,@(1),AVVideoMaxKeyFrameIntervalKey,AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
            
            [settings2 setObject:compressionProperties2 forKey:AVVideoCompressionPropertiesKey];
            NSArray *settingsArr = @[settings, settings2];
            NSArray *urlsArr = @[movieURL, movieURL2];
            for (int i = 0; i < settingsArr.count; i++) {
                GPUImageMovieWriter *wr = [[GPUImageMovieWriter alloc] initWithMovieURL:urlsArr[i] size:size fileType:AVFileTypeQuickTimeMovie outputSettings:settingsArr[i]];
                [self.arrayWriter addObject:wr];
                
                if (use) {
                    camera.audioEncodingTarget = self.movieWriter;
                }
                
                if(waterMark != nil){
                    wr.waterMark = waterMark;
                }
                
                [wr startRecording2];
                if(self.specialEffectsView != nil) {
                    self.specialEffectsView.voidFrame =  NO;
                }
            }
            [self changeGPUPipeline2File:self.arrayWriter];
        }
    }
}

- (void)stopSave2File{
    
    for (int i = 0; i < self.arrayWriter.count; i++) {
        GPUImageMovieWriter *wr = self.arrayWriter[i];
        if (wr) {
            if(self.specialEffectsView != nil) {
                self.specialEffectsView.voidFrame = self.supportGhost? YES:NO;
            }
            [wr setPaused:YES];
            __block GPUImageMovieWriter *writer = wr;
            
            [writer finishRecordingWithCompletionHandler:^{
                
                self.currentSectionTime = writer.sectionTime;
                writer = nil;
            }];
            
            wr = nil;
            
        }
    }
    [self changeGPUPipeline2File:self.arrayWriter];
}

- (void) changeGPUPipeline2File:(NSArray *)array{
    DCVideoCamera* camera =  nil;
    if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
    {
        camera = (DCVideoCamera *)self.mPreviewDataSource;
    }
    
    if((camera != nil) && (camera.captureSession != nil))
    {
        [camera  pauseCameraCapture];
        [camera.captureSession beginConfiguration];
    }
    
    if(self.mPreviewDataSource != nil)
    {
        if(cleanupBlock)
        {
            cleanupBlock();
        }
        
#ifdef bEnablePurgeBuffer
        GPUImageFramebuffer *frameBuffer = [camera framebufferForOutput];
        [[GPUImageContext sharedFramebufferCache] purgeTextureFramebuffers:frameBuffer];
#else
        [[GPUImageContext sharedFramebufferCache] purgeTextureFramebuffers];
#endif
        
        NSMutableArray *filterList = [NSMutableArray arrayWithCapacity:8];
        if (self.filterDataSource && [self.filterDataSource respondsToSelector:@selector(filterListForGPUImage)]) {
            NSMutableArray *tmp = [self.filterDataSource filterListForGPUImage];
            if ([tmp count]) {
                [filterList addObjectsFromArray:tmp];
            }
        }
        GPUImageFilter *showOnlyFilter = nil;
        for (GPUImageFilter *filter in filterList){
            if([filter respondsToSelector:@selector(showOnly)]){
                if(filter.showOnly){
                    [filterList removeObject:filter];
                    showOnlyFilter = filter;
                    break;
                }
            }
        }
        
        GPUImageSharpenFilter *filter = [[GPUImageSharpenFilter alloc] init];
        [filter setSharpness:0.25];
        self.skinFilter = filter;
        
        self.snapshotFilter = [[GPUImageFilter alloc] init];
        
        NSMutableArray *arrayTemp = [[NSMutableArray alloc]init];
        dispatch_block_t addingBlock=^{
            if(self.specialEffectsView != nil){
                if(showOnlyFilter != nil){
                    [self.snapshotFilter addTarget:showOnlyFilter];
                    [showOnlyFilter addTarget:self.specialEffectsView];
                    
                }else{
                    [self.snapshotFilter addTarget:self.specialEffectsView];
                }
            }
        };
        
        [arrayTemp addObject:self.skinFilter];
        
        if ([filterList count]) {
            [arrayTemp addObjectsFromArray:filterList];
        }
        
        [arrayTemp addObject:self.snapshotFilter];
        
        GPUImageMovieWriter *wr0 = array[0];
        GPUImageMovieWriter *wr1 = array[1];
        
        self.pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:arrayTemp input:self.mPreviewDataSource output:wr0];
        
        //        if(showOnlyFilter != nil){
        //            [self.snapshotFilter addTarget:showOnlyFilter];
        //            [showOnlyFilter addTarget:wr1];
        //        }else{
        //
        //            [self.snapshotFilter addTarget:wr1];
        //        }
        [self.self.snapshotFilter addTarget:wr1];
        
        
        addingBlock();
    }
    
    if((camera != nil) && (camera.captureSession != nil)) {
        [camera  resumeCameraCapture];
        [camera.captureSession commitConfiguration];
    }
}

- (NSMutableArray *)arrayWriter{
    if (!_arrayWriter) {
        _arrayWriter = [NSMutableArray array];
    }
    return _arrayWriter;
}
@end

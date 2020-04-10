//
//  DCEffectController.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "DCEffectController.h"

#import "DCSpecialEffectsView.h"
#import "DCVideoCamera.h"
#import "HAVSpecialEffectsController.h"
#import "AVAsset+MetalData.h"
#import "HAVMovieReader.h"
#import "HAVSpliteFilter.h"
#import "HAVQuickSpeedImageMovie.h"
#import <GPUKit/GPUKit.h>
#import "HAVTools.h"
#import "HAVGifFilter.h"

//#import "HAVScrawlAndTextFilter.h"


@interface DCEffectController()
<AVCaptureVideoDataOutputSampleBufferDelegate, GPUImageVideoCameraDelegate>
{
    dispatch_block_t cleanupBlock;
    int _samplerate;
    int _channels;
    CMSampleTimingInfo *testcmtime;
}
@property (nonatomic, weak) id<HAVGPUImageFilterDataSource> filterDataSource;
@property (nonatomic, weak) id<HAVStreamPickerFaceTrackDelegate> faceTrackDelegate;
@property (nonatomic, strong) DCSpecialEffectsView *specialEffectsView;
@property (nonatomic, strong) GPUImageOutput * mPreviewDataSource;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
//@property (nonatomic, strong) HAVRtmpWriter *rtmpWriter;
@property (nonatomic, strong) GPUImageFilterPipeline *pipeline;
@property (nonatomic, strong) GPUImageFilter <GPUImageInput> *skinFilter;
@property (nonatomic, strong) GPUImageFilter <GPUImageInput> *snapshotFilter;
@property (nonatomic, assign) NSTimeInterval currentSectionTime;
//@property (nonatomic, strong) GPUImageFilter *emptyFilter;
@property (nonatomic, strong) GPUImageFilter *outputFilter;

- (CGSize) cameraSize:(DCVideoCamera* )camera;

@end

@implementation DCEffectController

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        
        _filterManager = [[HAVGPUImageFilterManager alloc] init];
        self.filterDataSource = self.filterManager;
        self.faceTrackDelegate = self.filterManager;
        self.movieWriter = nil;
       // self.rtmpWriter = nil;
    }
    return self;
}

- (void) setPreView:(HAVSpecialEffectsView *)preview
{
    _specialEffectsView = preview;
    if((self.mPreviewDataSource != nil) && (_specialEffectsView != nil))
    {
        [self changeGPUPipeline];
    }
}

//-(void)setRtmpWriter:(HAVRtmpWriter*)rtmpWriter
//{
//    _rtmpWriter = rtmpWriter;
//    if((self.mPreviewDataSource != nil) && (_specialEffectsView != nil))
//    {
//        [self changeGPUPipeline];
//    }
//}

- (void) setDataSource:(GPUImageOutput*) dataSource
{
    if(dataSource != nil)
    {
        if(self.mPreviewDataSource != nil)
        {
            [self.mPreviewDataSource removeAllTargets];
        }
        self.mPreviewDataSource = dataSource;
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
    self.outputFilter = nil;
    if(self.mPreviewDataSource != nil){
        if(cleanupBlock) {
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
        for (int i = 0; i < filterList.count; i++) {
            GPUImageFilter *filter = filterList[i];
            
            if([filter respondsToSelector:@selector(showOnly)]){
                if(filter.showOnly){
                    [filterList removeObject:filter];
                    showOnlyFilter = filter;
                    break;
                }
            }
            
//            if ([filter isKindOfClass:[HAVScrawlAndTextFilter class]])
//            {
//                HAVScrawlAndTextFilter *f = (HAVScrawlAndTextFilter *)filter;
//                if (f.disableShow)
//                {
//                    [filterList removeObject:filter];
//                    if(self.outputFilter == nil)
//                    {
//                        self.outputFilter = f;
//                    }else
//                    {
//                        [self.outputFilter addTarget:f];
//                    }
//                }
//            }
            
            //            if ([filter isKindOfClass:[HAVLoadGifFilter class]]) {
            //                ((HAVLoadGifFilter *)filter).fillMode = _specialEffectsView.fillMode;
            //            }
            
            if ([filter isKindOfClass:[HAVGifFilter class]])
            {
                ((HAVGifFilter *)filter).fillMode = _specialEffectsView.fillMode;
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
        
        if ([filterList count])
        {
            [arrayTemp addObjectsFromArray:filterList];
        }
        
        if(self.snapshotFilter != nil)
        {
            [arrayTemp addObject:self.snapshotFilter];
        }
        if(self.outputFilter != nil)
        {
            [arrayTemp addObject:self.outputFilter];
        }
        
//        id<GPUImageInput> input = (self.rtmpWriter == nil)?self.movieWriter:self.rtmpWriter;
//        if (self.rtmpWriter || self.movieWriter)
//        {
//            self.pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:arrayTemp input:self.mPreviewDataSource output:input];
//        }
//        else
//        {
//            self.pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:arrayTemp input:self.mPreviewDataSource output:nil];
//        }
        
        
        
        id <GPUImageInput> gpuInput = self.movieWriter;
        [self.movieWriter setRecord:YES];
        self.pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:arrayTemp input:self.mPreviewDataSource output:gpuInput];
        addingBlock();
    }
    
    if((camera != nil) && (camera.captureSession != nil))
    {
        [camera  resumeCameraCapture];
        [camera.captureSession commitConfiguration];
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

- (void) startGhost
{
    if(self.specialEffectsView != nil)
    {
        self.specialEffectsView.voidFrame =  YES;
    }
}

- (void) clearGhost{
    if(self.specialEffectsView != nil){
        self.specialEffectsView.voidFrame =  NO;
    }
}

- (void) stopGhost{
    if(self.specialEffectsView != nil){
        self.specialEffectsView.voidFrame =  NO;
    }
}

- (void) setIsBattle:(BOOL)isBattle{
    if (self.specialEffectsView != nil){
        self.specialEffectsView.isSplite = isBattle;
    }
}

- (void) setGhostImage:(UIImage *) image{
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
        [self.specialEffectsView currentGhostImage: hander];
    }
}
-(void)getCoverImage:(void (^)(UIImage *)) hander
{
    UIImage* scrawImage = nil;
//    for (GPUImageFilter* filter in self.filterManager.filterListForGPUImage)
//    {
//        if ([filter isKindOfClass:[HAVScrawlAndTextFilter class]])
//        {
//            scrawImage = [(HAVScrawlAndTextFilter*)filter updatedImage];
//        }
//    }
    if(self.specialEffectsView != nil && scrawImage)
    {
        UIImage* backImage = [self.specialEffectsView currentGhostImage];
        
        UIGraphicsBeginImageContext(backImage.size);
        CGRect rect = CGRectMake(0,0,backImage.size.width,backImage.size.height);
        [scrawImage drawInRect:rect];
        UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        UIImage* aaImage = [HAVTools image:newimg rotation:UIImageOrientationDown];
        
        CIImage *outputImage = [CIImage imageWithCGImage:aaImage.CGImage];
        CIFilter *sourceOverCompositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [sourceOverCompositingFilter setValue:outputImage forKey:kCIInputImageKey];
        [sourceOverCompositingFilter setValue:[CIImage imageWithCGImage:backImage.CGImage] forKey:kCIInputBackgroundImageKey];
        outputImage = sourceOverCompositingFilter.outputImage;
        struct CGImage *cgImage = [[CIContext contextWithOptions: nil]createCGImage:outputImage fromRect:outputImage.extent];
        UIImage* resultImage = [UIImage imageWithCGImage:cgImage];
        if (hander)
        {
            hander(resultImage);
        }
        
    }else
    {
        [self.specialEffectsView currentCoverImage:hander];
    }
    
    
}

- (NSTimeInterval) getCurrentSectionTime{
    return self.currentSectionTime;
}

- (void) stopSaveFile{
    if(self.movieWriter != nil){
        if(self.specialEffectsView != nil) {
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

- (BOOL) stopSaveFileBackground{
    __block BOOL result = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [self stopSaveFileWithCompleteBlock:^(BOOL complete) {
        result = complete;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return result;
}

- (void) stopSaveFileWithCompleteBlock:(void (^)(BOOL complete)) block
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
            
            [self changeGPUPipeline];
            if(block != nil)
            {
                block(YES);
            }
        }];
        //        self.movieWriter = nil;
        
    }else{
        block(YES);
    }
}

- (CGSize) cameraSize:(DCVideoCamera* )camera
{
    CGSize size = CGSizeMake(720, 1280);
    
    NSString *present = camera.captureSession.sessionPreset;
    if( AVCaptureSessionPreset640x480 == present)
    {
        size = CGSizeMake(480, 640);
        
    }else if(AVCaptureSessionPreset1920x1080 == present)
    {
        size = CGSizeMake(1080, 1920);
        
    }else if(AVCaptureSessionPreset352x288 == present)
    {
        size = CGSizeMake(288, 352);
        
    }else if(AVCaptureSessionPreset1920x1080 ==  present)
    {
        size = CGSizeMake(1080, 1920);
    }
    
    return  size;
}

- (void) startSaveVideoFile:(NSString *)videoPath hasAudio:(BOOL) hasAudio bitRate:(NSInteger) bitRate waterMark:(HAVVideoWaterMark *) waterMark{
    if (self.movieWriter)
    {
        [self.movieWriter finishRecording];
        
    }
    [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    self.movieWriter = nil;
    NSURL *movieURL = [NSURL fileURLWithPath:videoPath];
    if(movieURL != nil)
    {
        if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
        {
            DCVideoCamera* camera = (DCVideoCamera *)self.mPreviewDataSource;
            CGSize size = [self cameraSize:camera];

            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,@(size.width),AVVideoWidthKey,@(size.height),AVVideoHeightKey,
                                             @(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey,AVVideoProfileLevelH264High40,AVVideoProfileLevelKey, nil];
            
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            self.movieWriter= [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:size fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            
            if(hasAudio){
                camera.audioEncodingTarget = self.movieWriter;
                AudioChannelLayout acl;
                bzero( &acl, sizeof(acl));
                acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
                
                NSDictionary *audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                                     [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                                     [ NSNumber numberWithFloat: 44100 ], AVSampleRateKey,
                                                     [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                                     [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                                     nil];
                [self.movieWriter setHasAudioTrack:YES audioSettings:audioOutputSettings];
            }
            
            if(waterMark != nil)
            {
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

- (void) startSaveVideoFile:(NSString *)videoPath hasAudio:(BOOL) hasAudio bitRate:(NSInteger) bitRate waterMark:(HAVVideoWaterMark *) waterMark outSize:(CGSize)outSize
{
    if (self.movieWriter)
    {
        [self.movieWriter finishRecording];
        
    }
    [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    self.movieWriter = nil;
    NSURL *movieURL = [NSURL fileURLWithPath:videoPath];
    if(movieURL != nil)
    {
        if([self.mPreviewDataSource isKindOfClass:[DCVideoCamera class]])
        {
            DCVideoCamera* camera = (DCVideoCamera *)self.mPreviewDataSource;
            CGSize size = [self cameraSize:camera];
            CGSize tempSize = ( (outSize.width > 0 && outSize.height > 0) ? outSize : size);
            
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,@(tempSize.width),AVVideoWidthKey,@(tempSize.height),AVVideoHeightKey,
                                             @(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey,AVVideoProfileLevelH264High40,AVVideoProfileLevelKey, nil];
            
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            self.movieWriter= [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:size fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            
            if(hasAudio){
                camera.audioEncodingTarget = self.movieWriter;
                AudioChannelLayout acl;
                bzero( &acl, sizeof(acl));
                acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
                
                NSDictionary *audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                                     [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                                     [ NSNumber numberWithFloat: 44100 ], AVSampleRateKey,
                                                     [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                                     [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                                     nil];
                [self.movieWriter setHasAudioTrack:YES audioSettings:audioOutputSettings];
            }
            
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

-(CMTime)recordDuration{
    return (self.movieWriter ? self.movieWriter.duration : kCMTimeZero);
}

#pragma mark --- FaceTrack
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if(!CMSampleBufferIsValid(sampleBuffer))
    {
        return;
    }
    if (self.faceTrackDelegate && [self.faceTrackDelegate respondsToSelector:@selector(succToPickWithStreamBufferForFaceTrack:position:)])
    {
        
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

- (void) dealloc
{
    NSLog(@"----%s----", __FUNCTION__);
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
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]])
    {
        HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
        [movieReader endProcessing];
    }
    self.mPreviewDataSource = nil;
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
    format.mChannelsPerFrame = channels;
    format.mBytesPerFrame = format.mBitsPerChannel / 8 * format.mChannelsPerFrame;
    format.mFramesPerPacket = 1;
    format.mBytesPerPacket = format.mBytesPerFrame*format.mFramesPerPacket;
    format.mReserved = 0;
    return format;
}

- (CMSampleBufferRef)createAudioSample:(void *)audioData frames:(UInt32)len
{
    Float64 samplerate = _samplerate;
    UInt32 channels = _channels;
    //    NSLog(@"channels:%d", channels);
    AudioBufferList audioBufferList;
    audioBufferList.mNumberBuffers = 1;
    audioBufferList.mBuffers[0].mNumberChannels=channels;
    audioBufferList.mBuffers[0].mDataByteSize=len;
    audioBufferList.mBuffers[0].mData = audioData;
    AudioStreamBasicDescription asbd = [self getAudioFormat];
    CMSampleBufferRef buff = NULL;
    
    CMFormatDescriptionRef format = NULL;
    
    CMTime time = CMTimeMake(len/2 , samplerate);
    CMTime pts = self->testcmtime->presentationTimeStamp;
    //    NSLog(@"pts value:%lld scale:%d", pts.value, pts.timescale);
    
    CMSampleTimingInfo timing = {CMTimeMake(1,samplerate), pts, kCMTimeInvalid };
    
    OSStatus error = 0;
    if(format == NULL)
    {
        error = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &asbd, 0, NULL, 0, NULL, NULL, &format);
        if (error)
        {
            NSLog(@"CMAudioFormatDescriptionCreate returned error: %ld", (long)error);
            return NULL;
        }
    }
    
    error = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, len/(2*channels), 1, &timing, 0, NULL, &buff);
    if ( error )
    {
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

-(CVPixelBufferRef)resultPixelBuffer
{
    __block CVPixelBufferRef pixelBuffer = NULL;
    GPUImageFilter* firstFilter = [self.filterManager.filterListForGPUImage firstObject];
    [firstFilter setFrameProcessingCompletionBlock:^(GPUImageOutput * output, CMTime nowTime)
     {
         GPUImageFramebuffer* fbo = [output framebufferForOutput];
         pixelBuffer = fbo.pixelBuffer;
     }];
    return pixelBuffer;
}

-(void)pushEffectedVideo
{
    
    __block CVPixelBufferRef pixelBuffer = NULL;
    GPUImageFilter* firstFilter = [self.filterManager.filterListForGPUImage firstObject];
    [firstFilter setFrameProcessingCompletionBlock:^(GPUImageOutput * output, CMTime nowTime)
     {
         GPUImageFramebuffer* fbo = [output framebufferForOutput];
         pixelBuffer = fbo.pixelBuffer;
         
         //推流加过特效的Video
//         if (self.pushVideoDelegate && [self.pushVideoDelegate respondsToSelector:@selector(pushVideoFrame:atTime:)])
//         {
//             [self.pushVideoDelegate pushVideoFrame:pixelBuffer atTime:nowTime];
//         }
         
     }];
}

@end

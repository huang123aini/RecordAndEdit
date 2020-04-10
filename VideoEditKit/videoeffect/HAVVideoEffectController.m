//
//  HAVVideoEffectController.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVVideoEffectController.h"
#import "HAVMovieReader.h"
#import "HAVVideoEffectController.h"
#import "DCSpecialEffectsView.h"
#import "AVAsset+MetalData.h"
#import <GPUKit/GPUKit.h>

#import "HAVParticleFilterController.h"

@interface HAVVideoEffectController()<HAVPlayerPlayBackDelegate>
{
    BOOL useSpliteFilter;
    BOOL isExportAbort;
}

@property (nonatomic, strong) GPUImageMovie *gpuMovier;
@property (nonatomic, strong) DCSpecialEffectsView *specialEffectsView;
@property (nonatomic, strong) GPUImageOutput * mPreviewDataSource;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) GPUImageFilterPipeline *pipeline;
@property (nonatomic, strong) HAVVideoEffectFilterController *effectFilterController;
@property (nonatomic, strong) GPUImageFilter <GPUImageInput> *snapshotFilter;
@property (nonatomic, strong) GPUImageMovieWriter *exportMovieWriter;
@property (nonatomic, strong) HAVSpliteFilterController *spliteFilterController;
@property (nonatomic, strong) HAVParticleFilterController *particleFilterController;
@property (nonatomic, strong) AVMutableComposition *outComposition;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) dispatch_queue_t encodingQueue;


@end

@implementation HAVVideoEffectController

- (instancetype) init{
    self = [super init];
    if(self){
        
    }
    return self;
}

-(NSData*)getSoulImage
{
    dispatch_semaphore_t  soulSemaphore = dispatch_semaphore_create(1);
    __block  NSData* imageData;
    
    dispatch_semaphore_wait(soulSemaphore, DISPATCH_TIME_FOREVER);
    [_specialEffectsView currentSoulImage:^(UIImage *image)
     {
         if (image)
         {
             imageData = UIImagePNGRepresentation(image);
         }
         dispatch_semaphore_signal(soulSemaphore);
     }];
    
    return imageData;
}

-(void)setSoulImage:(NSData*)imageData
{
    UIImage* image = [UIImage imageWithData:imageData];
    [self.effectFilterController setSoulImage:image];
}

-(void)setSoulInfoss:(NSArray*)array
{
    [self.effectFilterController setSoulInfoss:array];
}

- (void) createVideoEffect{
    if(self.effectFilterController == nil){
        self.effectFilterController = [[HAVVideoEffectFilterController alloc] init];
        [self changeGPUPipeline];
    }
}

- (void) destoryVideoEffect{
    self.effectFilterController = nil;
}


- (void) addSpliteFilterController:(HAVSpliteFilterController *)controller{
    self.spliteFilterController = controller;
}

- (void) setSpecialEffectsView:(DCSpecialEffectsView *)view{
    _specialEffectsView = view;
    if((self.mPreviewDataSource != nil) && (_specialEffectsView != nil)){
        [self changeGPUPipeline];
    }
}

- (void) setPreViewDataSource:(GPUImageOutput*) previewDataSource {
    [self setPreViewDataSource:previewDataSource showFirstFrame:YES];
}

- (void) setPreViewDataSource:(GPUImageOutput*) previewDataSource showFirstFrame:(BOOL) showFirstFrame{
    if(previewDataSource != nil){
        if(self.mPreviewDataSource != nil){
            [self.mPreviewDataSource removeAllTargets];
            if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
                HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
                [movieReader endProcessing];
            }
        }
        self.mPreviewDataSource = previewDataSource;
        if((self.mPreviewDataSource != nil) && (self.specialEffectsView != nil)){
            if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
                HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
                [movieReader setPlayLoopDelegate:self];
                movieReader.showFirstFrame = showFirstFrame;
                CGFloat druation = [movieReader duration];
                [self.effectFilterController setDuration:druation];
            }
        }
    }else{
        [self.mPreviewDataSource removeAllTargets];
        if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
            HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
            [movieReader endProcessing];
        }
        self.mPreviewDataSource = nil;
    }
    [self changeGPUPipeline];
}

- (void) changeGPUPipeline{
    
    if(self.mPreviewDataSource != nil){
        NSLog(@"-------------------------changeGPUPipeline");
        
        //清理上次GPUImage缓存
#ifdef bEnablePurgeBuffer
        GPUImageFramebuffer *frameBuffer = [self.mPreviewDataSource framebufferForOutput];
        [[GPUImageContext sharedFramebufferCache] purgeTextureFramebuffers:frameBuffer];
#else
        [[GPUImageContext sharedFramebufferCache] purgeTextureFramebuffers];
#endif
        self.pipeline = nil;
        self.snapshotFilter= [[GPUImageFilter alloc] init];
        
        NSMutableArray *arrayTemp = [[NSMutableArray alloc]init];
        dispatch_block_t addingBlock=^{
            if(self.specialEffectsView != nil){
                [self.snapshotFilter addTarget:self.specialEffectsView];
            }
        };
        
        if(self.effectFilterController == nil){
            self.effectFilterController = [[HAVVideoEffectFilterController alloc] init];
            if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
                HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
                CGFloat duration = [movieReader duration];
                [self.effectFilterController setDuration:duration];
            }
        }
        if(self.effectFilterController != nil){
            NSArray *array =[self.effectFilterController filters];
            if(array.count > 0){
                [arrayTemp addObjectsFromArray:array];
            }
        }
        
        if(self.particleFilterController != nil){
            NSArray *array =[self.particleFilterController filters];
            if(array.count > 0){
                [arrayTemp addObjectsFromArray:array];
            }
        }
        if(self.spliteFilterController != nil){
            [arrayTemp addObjectsFromArray:[self.spliteFilterController filters]];
        }
        [arrayTemp addObject:self.snapshotFilter];
        id <GPUImageInput> gpuInput = self.movieWriter;
        self.pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:arrayTemp input:self.mPreviewDataSource output:gpuInput];
        addingBlock();
    }
}

- (CGFloat) currentTime{
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
        HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
        return [movieReader currentTimeSeconds];
        //        CMTime frameDuration = [movieReader frameDuration];
        //        NSInteger frameIndex = [self.effectFilterController currentFrameIndex];
        //        return CMTimeGetSeconds(frameDuration) * frameIndex;
    }
    return 0;
}

- (void) seek:(NSTimeInterval) time{
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
        HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
        [movieReader seek:time];
        CMTime frameDuration = [movieReader frameDuration];
        if(CMTimeCompare(frameDuration, kCMTimeInvalid) != 0){
            //            CMTime current = CMTimeMake(time*1000000000, 1000000000);
            //            int frameIndex = (int) ((current.value * frameDuration.timescale)/(frameDuration.value * current.timescale));
            [self.effectFilterController seekToTime:time];
        }
    }
}

- (void) seekToTime:(NSTimeInterval) time {
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
        HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
        [movieReader seekToTime:time];
        CMTime frameDuration = [movieReader frameDuration];
        if(CMTimeCompare(frameDuration, kCMTimeInvalid) != 0){
            //            CMTime current = CMTimeMake(time*1000000000, 1000000000);
            //            int frameIndex = (int) ((current.value * frameDuration.timescale)/(frameDuration.value * current.timescale));
            [self.effectFilterController seekToTime:time];
        }
    }
}

- (void) showFrameAtTime:(NSTimeInterval) time{
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
        HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
        [movieReader showFrameAtTime:time];
        CMTime frameDuration = [movieReader frameDuration];
        if(CMTimeCompare(frameDuration, kCMTimeInvalid) != 0){
            CMTime current = [movieReader currentTime];
            [self.effectFilterController seekToTime:CMTimeGetSeconds(current)];
        }
    }
    
}

- (void) showFrameAtTime2:(NSTimeInterval) time{
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
        HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
        [movieReader showFrameAtTime:time completionHandler:^(BOOL finished) {
            if(finished){
                CMTime frameDuration = [movieReader frameDuration];
                if(CMTimeCompare(frameDuration, kCMTimeInvalid) != 0){
                    CMTime current = [movieReader currentTime];
                    [self.effectFilterController seekToTime:CMTimeGetSeconds(current)];
                }
            }
        }];
    }
    
}

- (NSArray *) archiver{
    return [self.effectFilterController archiver];
}

- (void) unArchiver:(NSArray *) array{
    return [self.effectFilterController unArchiver:array];
}

- (void) play{
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
        HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
        [movieReader startProcessing];
    }
}
- (void) stop{
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
        HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
        [movieReader endProcessing];
    }
}

- (void) back{
    [self.effectFilterController back];
}

- (void) reset{
    [self.effectFilterController reset];
}

- (void) clear{
    [self.effectFilterController clear];
}

- (void) resetFileReader{
    if (self.spliteFilterController) {
        [self.spliteFilterController reset];
    }
}

- (void) setEffectId:(int)effectId{
    [self.effectFilterController setVideoEffectID:effectId];
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
        if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
            HAVMovieReader* reader = (HAVMovieReader *)self.mPreviewDataSource;
            reader.playAtActualSpeed = NO;
            CGSize size = [[reader getAsset] videoNaturalSize];
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecTypeH264,AVVideoCodecKey,@(size.width),AVVideoWidthKey,@(size.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey/*,@(30),AVVideoMaxKeyFrameIntervalKey*/,AVVideoProfileLevelH264High40,
                                                           AVVideoProfileLevelKey,nil];
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            self.movieWriter= [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:size fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            reader.audioEncodingTarget = self.movieWriter;
            if(waterMark != nil){
                self.movieWriter.waterMark = waterMark;
            }
            [self changeGPUPipeline];
            [self.movieWriter startRecording];
        }
    }
}

- (void)exportEffectVideo:(NSString *)outPath bitRate:(NSInteger) bitRate{
    [self exportEffectVideo:outPath bitRate:bitRate withHandler:nil];
}

- (void)exportEffectVideoWithSpliteFilter:(NSString *) outPath bitRate:(NSInteger) bitRate withHandler:(void(^)(BOOL status , NSString *path, NSError * error))handler{
    useSpliteFilter = YES;
    [self exportEffectVideo:outPath bitRate:bitRate withHandler:handler];
}

- (void)exportEffectVideo:(NSString *) outPath bitRate:(NSInteger) bitRate withHandler:(void(^)(BOOL status , NSString *path, NSError * error))handler{
    useSpliteFilter = NO;
    if(outPath != nil){
        unlink([outPath UTF8String]);
    }
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
        HAVMovieReader *reader = (HAVMovieReader *)self.mPreviewDataSource;
        if (self.movieWriter != nil) {
            [self.movieWriter finishRecording];
        }
        
        self.movieWriter = nil;
        NSURL *url  =[NSURL fileURLWithPath:outPath];
        AVAsset *inputAsset = [reader getAsset];
        CGSize videoSize = [reader getFixedVideoSize];
        BOOL hasAudio = ([[inputAsset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
        if(url != nil){
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecTypeH264,AVVideoCodecKey,@(videoSize.width),AVVideoWidthKey,@(videoSize.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey/*,@(30),AVVideoMaxKeyFrameIntervalKey*/,
                                                           AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            
            self.exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            if(inputAsset != nil){
                self.gpuMovier = [[GPUImageMovie alloc] initWithAsset:inputAsset];
                self.gpuMovier.playAtActualSpeed = NO;
                self.gpuMovier.audioEncodingTarget = hasAudio?self.exportMovieWriter:nil;
                self.exportMovieWriter.hasAudioTrack = hasAudio;
                self.exportMovieWriter.encodingLiveVideo = YES;
                
                NSMutableArray* arrayTemp = [[NSMutableArray alloc] init];
                if(self.effectFilterController != nil){
                    [self.effectFilterController reset];
                    NSArray *array = [self.effectFilterController filters];
                    if(array.count > 0){
                        [arrayTemp addObjectsFromArray:array];
                    }
                }
                
                //=======================================
                if (useSpliteFilter) {
                    if (self.spliteFilterController) {
                        [self.spliteFilterController reset];
                        [arrayTemp addObject:self.spliteFilterController.spliteFilter];
                    }
                }
                //=======================================
                if(self.particleFilterController != nil){
                    [self.particleFilterController reset];
                    NSArray *array = [self.particleFilterController filters];
                    if(array.count > 0){
                        [arrayTemp addObjectsFromArray:array];
                    }
                }
                
                [self.gpuMovier enableSynchronizedEncodingUsingMovieWriter:self.exportMovieWriter];
                self.pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:arrayTemp input:self.gpuMovier output:self.exportMovieWriter];
                __block GPUImageFilterPipeline *pipeLine = self.pipeline;
                __block GPUImageMovieWriter *movieWritter = self.exportMovieWriter;
                __block GPUImageMovie *movieFile = self.gpuMovier;
                [self.exportMovieWriter setCompletionBlock:^{
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
                [self.exportMovieWriter startRecording];
                [self.gpuMovier startProcessing];
                //                if (self.spliteFilterController) {
                //                    [self.spliteFilterController.fileReader start];
                //                }
                
            }else{
                NSError *error = [NSError errorWithDomain:@"export error inputAsset = nil" code:-1 userInfo:nil];
                if(handler != nil){
                    handler(NO, outPath, error);
                }
            }
        }else{
            NSError *error = [NSError errorWithDomain:@"export error out path = nil" code:-1 userInfo:nil];
            if(handler != nil){
                handler(NO, outPath, error);
            }
        }
    }else{
        NSError *error = [NSError errorWithDomain:@"export error movie reader is null" code:-1 userInfo:nil];
        if(handler != nil){
            handler(NO, outPath, error);
        }
    }
}

- (void) exportVideo:(NSString *) outPath withHandler:(void (^) (BOOL status,NSString *path, NSError *error) ) handler{
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
        HAVMovieReader *reader = (HAVMovieReader *)self.mPreviewDataSource;
        [reader stop];
        NSMutableArray *arrayTemp = [[NSMutableArray alloc] init];
        if(self.effectFilterController != nil){
            [self.effectFilterController reset];
            NSArray *array =[self.effectFilterController filters];
            if(array.count > 0){
                [arrayTemp addObjectsFromArray:array];
            }
        }
        
        
        if(self.particleFilterController != nil){
            [self.particleFilterController reset];
            NSArray *array =[self.particleFilterController filters];
            if(array.count > 0){
                [arrayTemp addObjectsFromArray:array];
            }
        }
        //        NSString *path  = [[NSBundle mainBundle] pathForResource:@"0" ofType:@"mp4"];
        
        //        AVAsset *inputAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];//
        AVAsset *inputAsset = [reader getAsset];
        NSURL *url  =[NSURL fileURLWithPath:outPath];
        if(url != nil){
            CGSize videoSize = [reader getVideoSize];//[inputAsset videoNaturalSize];
            self.exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:nil];
            if(inputAsset != nil){
                self.gpuMovier = [[GPUImageMovie alloc] initWithAsset:inputAsset];
                self.gpuMovier.playAtActualSpeed = NO;
                //                self.gpuMovier.audioEncodingTarget = self.exportMovieWriter;
                
                self.exportMovieWriter.hasAudioTrack=YES;
                self.exportMovieWriter.encodingLiveVideo = YES;
                
                [self.gpuMovier enableSynchronizedEncodingUsingMovieWriter:self.exportMovieWriter];
                self.pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:arrayTemp input:self.gpuMovier output:self.exportMovieWriter];
                __block GPUImageFilterPipeline *pipeLine = self.pipeline;
                __block GPUImageMovieWriter *movieWritter = self.exportMovieWriter;
                __block GPUImageMovie *movieFile = self.gpuMovier;
                [self.exportMovieWriter setCompletionBlock:^{
                    [pipeLine removeAllFilters];
                    [movieFile endProcessing];
                    [movieWritter finishRecording];
                    [movieWritter setFailureBlock:nil];
                    [movieWritter setCompletionBlock:nil];
                }];
                
                [self.gpuMovier startProcessing];
                [self.exportMovieWriter startRecording];
                //                self.gpuMovier.audioEncodingTarget = self.exportMovieWriter;
            }else{
                
            }
        }
    }
}

- (void)exportEffectVideo2:(NSString *)outPath bitRate:(NSInteger) bitRate videoRequestSize:(HAVVideoSize)videoRequestSize metaData:(NSString *) metaData useSpliteFilter:(BOOL)use withHandler:(void (^) (BOOL status, NSString *outPath, NSError *error))handler{
    useSpliteFilter = use;
    if(outPath != nil){
        unlink([outPath UTF8String]);
    }
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
        HAVMovieReader *reader = (HAVMovieReader *)self.mPreviewDataSource;
        if (self.movieWriter != nil) {
            [self.movieWriter finishRecording];
        }
        
        self.movieWriter = nil;
        NSURL *url  =[NSURL fileURLWithPath:outPath];
        AVAsset *inputAsset = [reader getAsset];
        //        CGSize videoSize = [reader getFixedVideoSize];
        BOOL hasAudio = ([[inputAsset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
        CGSize videoSize = [inputAsset videoSize:videoRequestSize];
        NSLog(@"videoSize:%f %f", videoSize.width, videoSize.height);
        if(url != nil){
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             AVVideoCodecH264,AVVideoCodecKey,
                                             @(videoSize.width),AVVideoWidthKey,
                                             @(videoSize.height),AVVideoHeightKey,
                                             @(YES),@"EncodingLiveVideo",
                                             nil];
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey/*,@(30),AVVideoMaxKeyFrameIntervalKey*/,
                                                           AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
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
                self.gpuMovier = [[GPUImageMovie alloc] initWithAsset:inputAsset];
                self.gpuMovier.playAtActualSpeed = NO;
                self.gpuMovier.audioEncodingTarget = hasAudio?self.exportMovieWriter:nil;
                self.exportMovieWriter.hasAudioTrack = hasAudio;
                self.exportMovieWriter.encodingLiveVideo = YES;
                NSMutableArray* arrayTemp = [[NSMutableArray alloc] init];
                if(self.effectFilterController != nil){
                    [self.effectFilterController reset];
                    NSArray *array = [self.effectFilterController filters];
                    if(array.count > 0){
                        [arrayTemp addObjectsFromArray:array];
                    }
                }
                
                if(self.particleFilterController != nil){
                    [self.particleFilterController reset];
                    NSArray *array = [self.particleFilterController filters];
                    if(array.count > 0){
                        [arrayTemp addObjectsFromArray:array];
                    }
                }
                //                for (id aa in [self.effectFilterController filters]) {
                //                    NSLog(@"xxoo田老师 class:%@", [aa class]);
                //                }
                
                //=======================================
                if (useSpliteFilter) {
                    if (self.spliteFilterController) {
                        [self.spliteFilterController reset];
                        [arrayTemp addObject:self.spliteFilterController.spliteFilter];
                    }
                }
                //=======================================
                
                
                
                [self.gpuMovier enableSynchronizedEncodingUsingMovieWriter:self.exportMovieWriter];
                //                GPUImageSepiaFilter *ff = [[GPUImageSepiaFilter alloc] init];
                self.pipeline = [[GPUImageFilterPipeline alloc] initWithOrderedFilters:arrayTemp input:self.gpuMovier output:self.exportMovieWriter];
                __block GPUImageFilterPipeline *pipeLine = self.pipeline;
                __block GPUImageMovieWriter *movieWritter = self.exportMovieWriter;
                __block GPUImageMovie *movieFile = self.gpuMovier;
                [self.exportMovieWriter setCompletionBlock:^{
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
                [self.exportMovieWriter startRecording];
                [self.gpuMovier startProcessing];
                //                if (self.spliteFilterController) {
                //                    [self.spliteFilterController.fileReader start];
                //                }
                
            }else{
                NSError *error = [NSError errorWithDomain:@"export error inputAsset = nil" code:-1 userInfo:nil];
                if(handler != nil){
                    handler(NO, outPath, error);
                }
            }
        }else{
            NSError *error = [NSError errorWithDomain:@"export error out path = nil" code:-1 userInfo:nil];
            if(handler != nil){
                handler(NO, outPath, error);
            }
        }
    }else{
        NSError *error = [NSError errorWithDomain:@"export error movie reader is null" code:-1 userInfo:nil];
        if(handler != nil){
            handler(NO, outPath, error);
        }
    }
}

-(void)dealloc{
    [self.pipeline removeAllFilters];
    self.pipeline = nil;
    [self.mPreviewDataSource removeAllTargets];
    if([self.mPreviewDataSource isKindOfClass:[HAVMovieReader class]]){
        HAVMovieReader *movieReader = (HAVMovieReader*)self.mPreviewDataSource;
        [movieReader endProcessing];
    }
    self.mPreviewDataSource = nil;
}

- (void) loopPlayStart:(HAVPlayer *) player{
    [self.effectFilterController reset];
}

- (void) setReverse:(BOOL) reverse{
    [self.effectFilterController setReverse:reverse];
}


- (HAVMovieReader *)movieReader{
    return (HAVMovieReader *)self.mPreviewDataSource;
}

- (HAVMovieFileReader *)fileReader{
    return self.spliteFilterController.fileReader;
}

- (void) saveFileAfterTimeEffect:(NSURL *)savePath withVideoSize:(HAVVideoSize)vsize bitRate:(NSUInteger)bitRate metaData:(NSString*) metaData forceFramerate:(BOOL)flag completion:(void (^)(NSError *err))completion{
    HAVMovieReader *mr = (HAVMovieReader *)self.mPreviewDataSource;
    _outComposition = mr.outComposition;
    AVAssetTrack *videoTrack = [[_outComposition tracksWithMediaType:AVMediaTypeVideo] firstObject];
    float realBitRate = [videoTrack estimatedDataRate];
    NSInteger comBitRate = realBitRate > bitRate? bitRate : realBitRate;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self reencodeComposition:self->_outComposition toMP4File:savePath videoSize:vsize bitRate:comBitRate
                         metaData:metaData forceFramerate:flag withCompletionHandler:completion];
    });
}


- (void)reencodeComposition:(AVComposition *)composition toMP4File:(NSURL *)mp4FileURL videoSize:(HAVVideoSize)vsize bitRate:(NSUInteger)bitRate metaData:(NSString *) metaData forceFramerate:(BOOL)flag withCompletionHandler:(void (^)(NSError *error))handler{
#define FFALIGN(x, a) (((x)+(a)-1)&~((a)-1))
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
        if (vsize) {
            if (vsize == HAVVideoSizeCustom540) {
                
                int sw, sh;
                if (width < height) {
                    sw = 540;
                    sh = sw * height / width;
                    sh = FFALIGN(sh, 2);
                }
                else {
                    sh = 540;
                    sw = width * sh / height;
                }
                width = sw;
                height = sh;
                
            }
            else {
                CGSize videoSize = [composition videoSize:vsize];
                width = videoSize.width;
                height = videoSize.height;
            }
        }
        
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
        
        __weak HAVVideoEffectController *weakself = self;
        
        
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

#pragma mark - getter and setter
- (dispatch_queue_t)encodingQueue
{
    if(!_encodingQueue)
    {
        _encodingQueue = dispatch_queue_create("com.myProject.encoding", NULL);
    }
    return _encodingQueue;
}
#pragma mark-
#pragma magic controller

- (void) createMagicFinger{
    if(self.particleFilterController == nil){
        self.particleFilterController = [[HAVParticleFilterController alloc] init];
        [self changeGPUPipeline];
    }
}

- (void) destoryMagicFinger{
    self.particleFilterController = nil;
}

- (void) magicStop{
    [self.particleFilterController stop];
}

- (void) magicBack{
    [self.particleFilterController back];
}

- (void) magicReset{
    [self.particleFilterController reset];
}

- (NSArray *) magicArchiver{
    return [self.particleFilterController archiver];
}

- (void) removeAllMagic{
    [self.particleFilterController removeAllMagic];
}

- (void) magicUnarchiver:(NSArray *) array{
    [self.particleFilterController unarchiver:array];
}

- (void) changeSourcePosition:(CGPoint) position{
    [self.particleFilterController changeSourcePosition:position];
}

- (void) addParticle:(NSString *) file atPosition:(CGPoint) point{
    [self.particleFilterController addParticle:file atPosition:point];
}

- (void) addParticles:(NSArray *) files atPosition:(CGPoint) point{
    [self.particleFilterController addParticles:files atPosition:point];
}

- (HAVParticleFilterController*) currentParticleFilterController{
    return self.particleFilterController;
}
@end

//
//  HWatermarkExport.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/9.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HWatermarkExport.h"
#import "HWaterMarkFilter.h"
#import <GPUKit/GPUKit.h>
#import "AVURLAsset+MetalData.h"
@interface HWatermarkExport ()

@property (nonatomic, strong) AVAsset *videoAsset;
@property (nonatomic, strong) GPUImageMovie *gpuMovier;
@property (nonatomic, strong) GPUImageFilterPipeline *pipeline;
@property (nonatomic, strong) HWaterMarkFilter *imageFilter;
@property (nonatomic, strong) GPUImageMovieWriter *exportMovieWriter;
@property (nonatomic, strong) NSTimer* sampleTimer;

@end

@implementation HWatermarkExport

- (instancetype) initWithWaterMark:(HWaterMark *) waterMark videoUrl:(NSURL *)url{
    self = [super init];
    if(self){
        self.videoAsset = [AVAsset assetWithURL:url];
        self.imageFilter = [[HWaterMarkFilter alloc] initWithWaterMark:waterMark];
        self.sampleTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                            target:self
                                                          selector:@selector(getProgress)
                                                          userInfo:nil
                                                           repeats:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBack:) name:UIApplicationWillResignActiveNotification object:nil];
        
    }
    return self;
}


-(instancetype)initWithWaterMarkImageFilter:(HWaterMarkFilter*)waterFilter videoUrl:(NSURL*)url
{
    self = [super init];
    if(self)
    {
        self.videoAsset = [AVAsset assetWithURL:url];
        self.imageFilter = waterFilter;
        
        self.sampleTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                            target:self
                                                          selector:@selector(getProgress)
                                                          userInfo:nil
                                                           repeats:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBack:) name:UIApplicationWillResignActiveNotification object:nil];
        
    }
    return self;
    
}

- (void)handleBack:(NSNotification *)notif
{
    if(self.gpuMovier.progress < 1)
    {
        [self cancelExport];
    }
}

-(void)getProgress
{
    
    if (self.gpuMovier != nil)
    {
        self.progress = self.gpuMovier.progress;
        
    }
    
}

-(void)cancelExport
{
    
    if (self.gpuMovier != nil)
    {
        //回到主线程杀死
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.gpuMovier cancelProcessing];
            [self.gpuMovier endProcessing];
            [self.exportMovieWriter cancelRecording];
            self.exportMovieWriter = nil;
            self.gpuMovier = nil;
            self.pipeline = nil;
            self.imageFilter = nil;
            [self.sampleTimer invalidate];
        });
    }
}


- (void)exportWaterMarkVideo:(NSString *) outPath bitRate:(NSInteger) bitRate withHandler:(void(^)(BOOL status , NSString *path, NSError * error))handler{
    if(outPath != nil){
        unlink([outPath UTF8String]);
    }
    NSURL *url  =[NSURL fileURLWithPath:outPath];
    AVAsset *inputAsset = self.videoAsset;
    CGSize videoSize = [self.videoAsset videoNaturalSize];
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
            NSMutableArray* arrayTemp=[[NSMutableArray alloc] init];
            if(self.imageFilter != nil){
                [arrayTemp addObject:self.imageFilter];
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
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            handler(YES, outPath, nil);
                        });
                    }
                }];
            }];
            [self.exportMovieWriter startRecording];
            [self.gpuMovier startProcessing];
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
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

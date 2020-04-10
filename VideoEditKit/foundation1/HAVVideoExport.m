//
//  HAVVideoExport.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVVideoExport.h"
#import "HAVVideoItem.h"
#import "HAVVideoExport.h"
#import "AVAsset+MetalData.h"
#import <GPUKit/GPUKit.h>
#import "HAVGPUImageMovie.h"

@interface ExportHandler ()
@property (nonatomic ,weak) GPUImageMovie *movie;
@property (nonatomic ,weak) GPUImageMovieWriter *writter;

@end

@implementation ExportHandler

-(void) cancel{
    [self.writter cancelRecording];
    [self.movie cancelProcessing];
    [self.writter setCompletionBlock:nil];
    [self.writter setFailureBlock:nil];
}

@end

@implementation HAVVideoExport

+ (void) exportVideo1:(NSString *)outpath videoSize:(HAVVideoSize) avVideoSize withVideoItems:(NSArray *) videoItems withAudioUrl:(HAVAudioItem *) audioItem withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler{
    
    if(outpath != nil){
        AVMutableComposition *composition = [AVMutableComposition composition];
        NSMutableArray *audioMixParams = [[NSMutableArray alloc] init];
        if(videoItems.count > 0){
            AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            AVMutableCompositionTrack *audioTrack = nil;
            AVMutableCompositionTrack *audioTrack2 = nil;
            AVAssetTrack *songAudioTrack = nil;
            //CMTime audioDuration = kCMTimeZero;
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
            CGFloat songVolume = audioItem.volume;
            for (HAVVideoItem *videoItem in videoItems){
                volume = videoItem.volume;
                AVAsset *videoAsset = [videoItem getVideoAsset];
                AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
                AVAssetTrack *sourceAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
                // AVAsset *audioAsset = [audioItem getVideoAsset];
                // AVAssetTrack *songAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
                NSError *error = nil;
                BOOL ok = NO;
                CMTime startTime = CMTimeMultiply([sourceVideoTrack minFrameDuration], 3);
                CMTime trackDuration = [sourceVideoTrack timeRange].duration;
                trackDuration = CMTimeSubtract(trackDuration, startTime);
                CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
                ok = [videoTrack insertTimeRange:tRange ofTrack:sourceVideoTrack atTime:offset error:&error];
                if(sourceAudioTrack != nil){
                    if(audioTrack == nil){
                        audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                    }
                    ok = [audioTrack insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:offset error:&error];
                }
                
                //if(songAudioTrack != nil){
                //                    CMTime totalDuration = CMTimeAdd(audioOffset, trackDuration);
                //                    if(CMTimeCompare(totalDuration, audioDuration) < 0){
                //                        CMTimeRange tRange2 = CMTimeRangeMake(audioOffset, trackDuration);
                //                        ok = [audioTrack2 insertTimeRange:tRange2 ofTrack:songAudioTrack atTime:offset error:&error];
                //
                //                    }else{
                //                        CMTime secondSegmentDuratuon = CMTimeSubtract(totalDuration, audioDuration);
                //                        CMTime firstSegmentDuratuon = CMTimeSubtract(trackDuration, secondSegmentDuratuon);
                //
                //                        CMTimeRange tRange2 = CMTimeRangeMake(audioOffset, firstSegmentDuratuon);
                //                        ok = [audioTrack2 insertTimeRange:tRange2 ofTrack:songAudioTrack atTime:offset error:&error];
                //
                //                        audioOffset = kCMTimeZero;
                //                        tRange2 = CMTimeRangeMake(audioOffset, secondSegmentDuratuon);
                //                        ok = [audioTrack2 insertTimeRange:tRange2 ofTrack:songAudioTrack atTime:offset error:&error];
                //                    }
                //                }
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
            AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
            [trackMix setVolume:volume atTime:kCMTimeZero];
            [audioMixParams addObject:trackMix];
            trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack2];
            [trackMix setVolume:songVolume atTime:kCMTimeZero];
            [audioMixParams addObject:trackMix];
        }
        
        
        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                          initWithAsset: composition
                                          presetName: [composition presetFromVideoSize:avVideoSize]];
        exporter.audioMix = audioMix;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        
        /** 导出的文件存在即删除**/
        if ([[NSFileManager defaultManager] fileExistsAtPath:outpath]) {
            [[NSFileManager defaultManager] removeItemAtPath:outpath error:nil];
        }
        NSURL *exportURL = [NSURL fileURLWithPath:outpath];
        exporter.outputURL = exportURL;
        if( composition != nil && CMTimeCompare([ composition duration] , kCMTimeZero ) > 0){
            exporter.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
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


+ (void) exportVideo:(NSString *)outpath videoSize:(HAVVideoSize) avVideoSize withVideoItems:(NSArray *) videoItems withAudioUrl:(HAVAudioItem *) audioItem withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler{
    
    if(outpath != nil){
        AVMutableComposition *composition = [AVMutableComposition composition];
        NSMutableArray *audioMixParams = [[NSMutableArray alloc] init];
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
            CGFloat songVolume = audioItem.volume;
            for (HAVVideoItem *videoItem in videoItems){
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
                if(sourceAudioTrack != nil){
                    if(audioTrack == nil){
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
            AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
            [trackMix setVolume:volume atTime:kCMTimeZero];
            [audioMixParams addObject:trackMix];
            trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack2];
            [trackMix setVolume:songVolume atTime:kCMTimeZero];
            [audioMixParams addObject:trackMix];
        }
        
        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                          initWithAsset: composition
                                          presetName: [composition presetFromVideoSize:avVideoSize]];
        exporter.audioMix = audioMix;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        
        /** 导出的文件存在即删除**/
        if ([[NSFileManager defaultManager] fileExistsAtPath:outpath]) {
            [[NSFileManager defaultManager] removeItemAtPath:outpath error:nil];
        }
        NSURL *exportURL = [NSURL fileURLWithPath:outpath];
        exporter.outputURL = exportURL;
        if( composition != nil && CMTimeCompare([ composition duration] , kCMTimeZero ) > 0){
            exporter.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
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
// 多段合成非全I帧
+ (ExportHandler *) exportVideo:(NSString *)outpath videoSize:(HAVVideoSize) avVideoSize bitRate:(NSInteger) bitRate withVideoItems:(NSArray *) videoItems withAudioUrl:(HAVAudioItem *) audioItem withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler{
    ExportHandler *exportHandler = nil;
    if(outpath != nil){
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
            for (HAVVideoItem *videoItem in videoItems){
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
                if(sourceAudioTrack != nil){
                    if(audioTrack == nil){
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
            if(outpath != nil){
                unlink([outpath UTF8String]);
            }
            AVAsset *asset = composition;
            BOOL hasAudio = ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
            if(outpath != nil){
                NSURL *url  = [NSURL fileURLWithPath:outpath];
                CGSize videoSize = [asset videoSize:avVideoSize];
                if(url != nil){
                    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,@(videoSize.width),AVVideoWidthKey,@(videoSize.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
                    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey,
                                                                   AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
                    [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
                    GPUImageMovieWriter *exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
                    if(asset != nil){
                        HAVGPUImageMovie *gpuMovie = [[HAVGPUImageMovie alloc] initWithAsset:asset];
                        gpuMovie.playAtActualSpeed = NO;
                        gpuMovie.audioEncodingTarget = hasAudio?exportMovieWriter:nil;
                        exportMovieWriter.hasAudioTrack = hasAudio;
                        exportMovieWriter.encodingLiveVideo = YES;
                        [gpuMovie enableSynchronizedEncodingUsingMovieWriter:exportMovieWriter];
                        [gpuMovie addTarget:exportMovieWriter];
                        __block GPUImageMovieWriter *movieWritter = exportMovieWriter;
                        __block GPUImageMovie *movieFile = gpuMovie;
                        movieWritter.forceFps = YES;
                        movieWritter.fps = 31;
                        [exportMovieWriter setCompletionBlock:^{
                            [movieFile endProcessing];
                            [movieWritter finishRecordingWithCompletionHandler:^{
                                [movieWritter setFailureBlock:nil];
                                [movieWritter setCompletionBlock:nil];
                                if(handler != nil){
                                    handler(YES, outpath, nil);
                                }
                            }];
                        }];
                        [exportMovieWriter setFailureBlock:^(NSError *err){
                            NSLog(@"setFailureBlock failed!");
                            handler(NO, outpath, err);
                            [movieWritter setCompletionBlock:nil];
                            [movieWritter setFailureBlock:nil];
                        }];
                        [exportMovieWriter startRecording];
                        [gpuMovie startProcessing];
                        exportHandler = [[ExportHandler alloc] init];
                        exportHandler.movie = gpuMovie;
                        exportHandler.writter = exportMovieWriter;
                    }else{
                        NSError *error = [NSError errorWithDomain:@"asset error" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"asset error" forKey:@"error"]];
                        if(handler != nil){
                            handler(NO , outpath, error);
                        }
                    }
                }else{
                    NSError *error = [NSError errorWithDomain:@"tmp path url error" code:-2 userInfo:[NSDictionary dictionaryWithObject:@"tmp path url error" forKey:@"error"]];
                    if(handler != nil){
                        handler(NO , outpath, error);
                    }
                }
            }else{
                NSError *error = [NSError errorWithDomain:@"tmp path error" code:-3 userInfo:[NSDictionary dictionaryWithObject:@"tmp path error" forKey:@"error"]];
                if(handler != nil){
                    handler(NO , outpath, error);
                }
            }
        }else{
            NSDictionary *dic = [NSDictionary dictionaryWithObject:@"input video item is null" forKey:@"error"];
            NSError *error = [NSError errorWithDomain:@"input video item is null" code:-1 userInfo:dic];
            handler(NO, outpath, error);
        }
    }else{
        NSDictionary *dic = [NSDictionary dictionaryWithObject:@"export file path is empty" forKey:@"error"];
        NSError *error = [NSError errorWithDomain:@"export file path is empty" code:-1 userInfo:dic];
        handler(NO, outpath, error);
    }
    return exportHandler;
}
// 多段合成全I帧
+ (ExportHandler*) exportiFrameVideo:(NSString *)outpath videoSize:(HAVVideoSize) avVideoSize bitRate:(NSInteger) bitRate withVideoItems:(NSArray *) videoItems withAudioUrl:(HAVAudioItem *) audioItem withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler{
    ExportHandler *exportHandler = nil;
    if(outpath != nil){
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
            for (HAVVideoItem *videoItem in videoItems){
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
                if(sourceAudioTrack != nil){
                    if(audioTrack == nil){
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
            if(outpath != nil){
                unlink([outpath UTF8String]);
            }
            AVAsset *asset = composition;
            BOOL hasAudio = ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
            if(outpath != nil){
                NSURL *url  = [NSURL fileURLWithPath:outpath];
                CGSize videoSize = [asset videoSize:avVideoSize];
                if(url != nil){
                    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,@(videoSize.width),AVVideoWidthKey,@(videoSize.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
                    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey,@(1),AVVideoMaxKeyFrameIntervalKey,
                                                                   AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
                    [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
                    GPUImageMovieWriter *exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
                    if(asset != nil){
                        HAVGPUImageMovie *gpuMovie = [[HAVGPUImageMovie alloc] initWithAsset:asset];
                        gpuMovie.playAtActualSpeed = NO;
                        gpuMovie.audioEncodingTarget = hasAudio?exportMovieWriter:nil;
                        exportMovieWriter.hasAudioTrack = hasAudio;
                        exportMovieWriter.encodingLiveVideo = YES;
                        [gpuMovie enableSynchronizedEncodingUsingMovieWriter:exportMovieWriter];
                        [gpuMovie addTarget:exportMovieWriter];
                        __block GPUImageMovieWriter *movieWritter = exportMovieWriter;
                        __block GPUImageMovie *movieFile = gpuMovie;
                        movieWritter.forceFps = YES;
                        movieWritter.fps = 31;
                        [exportMovieWriter setCompletionBlock:^{
                            [movieFile endProcessing];
                            [movieWritter finishRecordingWithCompletionHandler:^{
                                [movieWritter setFailureBlock:nil];
                                [movieWritter setCompletionBlock:nil];
                                if(handler != nil){
                                    handler(YES, outpath, nil);
                                }
                            }];
                        }];
                        [exportMovieWriter setFailureBlock:^(NSError *err){
                            NSLog(@"setFailureBlock failed!");
                            handler(NO, outpath, err);
                            [movieWritter setCompletionBlock:nil];
                            [movieWritter setFailureBlock:nil];
                        }];
                        [exportMovieWriter startRecording];
                        [gpuMovie startProcessing];
                        exportHandler = [[ExportHandler alloc] init];
                        exportHandler.movie = gpuMovie;
                        exportHandler.writter = exportMovieWriter;
                    }else{
                        NSError *error = [NSError errorWithDomain:@"asset error" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"asset error" forKey:@"error"]];
                        if(handler != nil){
                            handler(NO , outpath, error);
                        }
                    }
                }else{
                    NSError *error = [NSError errorWithDomain:@"tmp path url error" code:-2 userInfo:[NSDictionary dictionaryWithObject:@"tmp path url error" forKey:@"error"]];
                    if(handler != nil){
                        handler(NO , outpath, error);
                    }
                }
            }else{
                NSError *error = [NSError errorWithDomain:@"tmp path error" code:-3 userInfo:[NSDictionary dictionaryWithObject:@"tmp path error" forKey:@"error"]];
                if(handler != nil){
                    handler(NO , outpath, error);
                }
            }
        }else{
            NSDictionary *dic = [NSDictionary dictionaryWithObject:@"input video item is null" forKey:@"error"];
            NSError *error = [NSError errorWithDomain:@"input video item is null" code:-1 userInfo:dic];
            handler(NO, outpath, error);
        }
    }else{
        NSDictionary *dic = [NSDictionary dictionaryWithObject:@"export file path is empty" forKey:@"error"];
        NSError *error = [NSError errorWithDomain:@"export file path is empty" code:-1 userInfo:dic];
        handler(NO, outpath, error);
    }
    return exportHandler;
}



// 多段合成非全I帧
+ (ExportHandler *) exportVideo:(NSString *)outpath videoSize:(HAVVideoSize)  avVideoSize bitRate:(NSInteger) bitRate withVideoItems:(NSArray *) videoItems  withMovieFile:(HAVVideoItem *) audioSource isBattlePreview:(BOOL)isPreview withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler;
{
    ExportHandler *exportHandler = nil;
    if(outpath != nil)
    {
        AVMutableComposition *composition = [AVMutableComposition composition];
        if(videoItems.count > 0)
        {
            AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            AVMutableCompositionTrack *audioTrack2 = nil;
            AVAssetTrack *songAudioTrack = nil;
            CMTime offset = kCMTimeZero;
            CGFloat volume = [(HAVVideoItem*)[videoItems firstObject] volume];
            for (HAVVideoItem *videoItem in videoItems)
            {
                volume = videoItem.volume;
                AVAsset *videoAsset = [videoItem getVideoAsset];
                AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
                
                NSError *error = nil;
                BOOL ok = NO;
                CMTime startTime = kCMTimeZero;
                CMTime trackDuration = [sourceVideoTrack timeRange].duration;
                trackDuration = CMTimeSubtract(trackDuration, startTime);
                CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
                ok = [videoTrack insertTimeRange:tRange ofTrack:sourceVideoTrack atTime:offset error:&error];
                
                if((videoItem.rate != 1.0f) && (videoItem.rate != 0.0f))
                {
                    CMTime newDuration = CMTimeMultiplyByFloat64(trackDuration, 1.0f/videoItem.rate);
                    CMTime startTime = CMTimeSubtract(composition.duration, trackDuration);
                    tRange = CMTimeRangeMake(startTime,trackDuration);
                    [videoTrack scaleTimeRange:tRange toDuration:newDuration];
                    
                    offset = CMTimeAdd(offset, newDuration);
                }else
                {
                    offset = CMTimeAdd(offset, trackDuration);
                }
            }
            
            if(audioSource != nil)
            {
                AVAsset *audioAsset = [audioSource getVideoAsset];
                songAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
                if(songAudioTrack != nil)
                {
                    audioTrack2 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                    NSError* error;
                    
                    CMTimeRange audioRange;
                    
                    if (isPreview)
                    {
                        audioRange = CMTimeRangeMake(kCMTimeZero, [videoTrack timeRange].duration);
                    }else
                    {
                        audioRange = [songAudioTrack timeRange];
                    }
                    
                    BOOL ok = [audioTrack2 insertTimeRange:audioRange ofTrack:songAudioTrack atTime:kCMTimeZero error:&error];
                    if (!ok)
                    {
                        //                        NSLog(@"添加音频错误");
                    }
                }
            }
            
            //视频对齐音频
            
            if (!isPreview)
            {
                if(songAudioTrack != nil)
                {
                    CMTime audioDuration = [songAudioTrack timeRange].duration;
                    [videoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, [videoTrack timeRange].duration) toDuration:audioDuration];
                }
            }
            
            
            if(outpath != nil)
            {
                unlink([outpath UTF8String]);
            }
            AVAsset *asset = composition;
            BOOL hasAudio = ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
            if(outpath != nil)
            {
                NSURL *url  = [NSURL fileURLWithPath:outpath];
                CGSize videoSize = [asset videoSize:avVideoSize];
                if(url != nil)
                {
                    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,@(videoSize.width),AVVideoWidthKey,@(videoSize.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
                    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey,
                                                                   AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
                    [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
                    GPUImageMovieWriter *exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
                    if(asset != nil)
                    {
                        HAVGPUImageMovie *gpuMovie = [[HAVGPUImageMovie alloc] initWithAsset:asset];
                        gpuMovie.playAtActualSpeed = NO;
                        gpuMovie.audioEncodingTarget = hasAudio?exportMovieWriter:nil;
                        
                        if (hasAudio)
                        {
                            //                            exportMovieWriter.audioSourceAsset = [audioSource getVideoAsset];
                        }
                        
                        exportMovieWriter.hasAudioTrack = hasAudio;
                        exportMovieWriter.encodingLiveVideo = YES;
                        [gpuMovie enableSynchronizedEncodingUsingMovieWriter:exportMovieWriter];
                        [gpuMovie addTarget:exportMovieWriter];
                        __block GPUImageMovieWriter *movieWritter = exportMovieWriter;
                        __block GPUImageMovie *movieFile = gpuMovie;
                        movieWritter.forceFps = YES;
                        movieWritter.fps = 31;
                        [exportMovieWriter setCompletionBlock:^{
                            [movieFile endProcessing];
                            [movieWritter finishRecordingWithCompletionHandler:^{
                                [movieWritter setFailureBlock:nil];
                                [movieWritter setCompletionBlock:nil];
                                if(handler != nil)
                                {
                                    handler(YES, outpath, nil);
                                }
                            }];
                        }];
                        [exportMovieWriter setFailureBlock:^(NSError *err)
                         {
                             NSLog(@"setFailureBlock failed!");
                             handler(NO, outpath, err);
                             [movieWritter setCompletionBlock:nil];
                             [movieWritter setFailureBlock:nil];
                         }];
                        [exportMovieWriter startRecording];
                        [gpuMovie startProcessing];
                        exportHandler = [[ExportHandler alloc] init];
                        exportHandler.movie = gpuMovie;
                        exportHandler.writter = exportMovieWriter;
                    }else
                    {
                        NSError *error = [NSError errorWithDomain:@"asset error" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"asset error" forKey:@"error"]];
                        if(handler != nil)
                        {
                            handler(NO , outpath, error);
                        }
                    }
                }else
                {
                    NSError *error = [NSError errorWithDomain:@"tmp path url error" code:-2 userInfo:[NSDictionary dictionaryWithObject:@"tmp path url error" forKey:@"error"]];
                    if(handler != nil)
                    {
                        handler(NO , outpath, error);
                    }
                }
            }else
            {
                NSError *error = [NSError errorWithDomain:@"tmp path error" code:-3 userInfo:[NSDictionary dictionaryWithObject:@"tmp path error" forKey:@"error"]];
                if(handler != nil)
                {
                    handler(NO , outpath, error);
                }
            }
        }else
        {
            NSDictionary *dic = [NSDictionary dictionaryWithObject:@"input video item is null" forKey:@"error"];
            NSError *error = [NSError errorWithDomain:@"input video item is null" code:-1 userInfo:dic];
            handler(NO, outpath, error);
        }
    }else
    {
        NSDictionary *dic = [NSDictionary dictionaryWithObject:@"export file path is empty" forKey:@"error"];
        NSError *error = [NSError errorWithDomain:@"export file path is empty" code:-1 userInfo:dic];
        handler(NO, outpath, error);
    }
    return exportHandler;
}

// 多段合成全I帧
+ (ExportHandler *) exportiFrameVideo:(NSString *)outpath videoSize:(HAVVideoSize)  avVideoSize bitRate:(NSInteger) bitRate withVideoItems:(NSArray *) videoItems  withMovieFile:(HAVVideoItem *) audioSource isBattlePreview:(BOOL)isPreview withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler;
{
    ExportHandler *exportHandler = nil;
    if(outpath != nil)
    {
        AVMutableComposition *composition = [AVMutableComposition composition];
        if(videoItems.count > 0)
        {
            AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            AVMutableCompositionTrack *audioTrack2 = nil;
            AVAssetTrack *songAudioTrack = nil;
            CMTime offset = kCMTimeZero;
            CGFloat volume = [(HAVVideoItem*)[videoItems firstObject] volume];
            for (HAVVideoItem *videoItem in videoItems)
            {
                volume = videoItem.volume;
                AVAsset *videoAsset = [videoItem getVideoAsset];
                AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
                
                NSError *error = nil;
                BOOL ok = NO;
                CMTime startTime = kCMTimeZero;
                CMTime trackDuration = [sourceVideoTrack timeRange].duration;
                trackDuration = CMTimeSubtract(trackDuration, startTime);
                CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
                ok = [videoTrack insertTimeRange:tRange ofTrack:sourceVideoTrack atTime:offset error:&error];
                
                if((videoItem.rate != 1.0f) && (videoItem.rate != 0.0f))
                {
                    CMTime newDuration = CMTimeMultiplyByFloat64(trackDuration, 1.0f/videoItem.rate);
                    CMTime startTime = CMTimeSubtract(composition.duration, trackDuration);
                    tRange = CMTimeRangeMake(startTime,trackDuration);
                    [videoTrack scaleTimeRange:tRange toDuration:newDuration];
                    
                    offset = CMTimeAdd(offset, newDuration);
                }else
                {
                    offset = CMTimeAdd(offset, trackDuration);
                }
            }
            
            
            
            
            if(audioSource != nil)
            {
                AVAsset *audioAsset = [audioSource getVideoAsset];
                songAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
                if(songAudioTrack != nil)
                {
                    audioTrack2 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                    NSError* error;
                    
                    CMTimeRange audioRange;
                    
                    if (isPreview)
                    {
                        audioRange = CMTimeRangeMake(kCMTimeZero, [videoTrack timeRange].duration);
                    }else
                    {
                        audioRange = [songAudioTrack timeRange];
                    }
                    
                    BOOL ok = [audioTrack2 insertTimeRange:audioRange ofTrack:songAudioTrack atTime:kCMTimeZero error:&error];
                    if (!ok)
                    {
                        //                        NSLog(@"添加音频错误");
                    }
                }
            }
            
            //视频对齐音频
            
            if (!isPreview)
            {
                if(songAudioTrack != nil)
                {
                    CMTime audioDuration = [songAudioTrack timeRange].duration;
                    [videoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, [videoTrack timeRange].duration) toDuration:audioDuration];
                }
            }
            
            
            if(outpath != nil)
            {
                unlink([outpath UTF8String]);
            }
            AVAsset *asset = composition;
            BOOL hasAudio = ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
            if(outpath != nil)
            {
                NSURL *url  = [NSURL fileURLWithPath:outpath];
                CGSize videoSize = [asset videoSize:avVideoSize];
                if(url != nil)
                {
                    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,@(videoSize.width),AVVideoWidthKey,@(videoSize.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
                    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(bitRate),AVVideoAverageBitRateKey,@(1),AVVideoMaxKeyFrameIntervalKey,
                                                                   AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
                    [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
                    GPUImageMovieWriter *exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
                    if(asset != nil)
                    {
                        HAVGPUImageMovie *gpuMovie = [[HAVGPUImageMovie alloc] initWithAsset:asset];
                        gpuMovie.playAtActualSpeed = NO;
                        gpuMovie.audioEncodingTarget = hasAudio?exportMovieWriter:nil;
                        
                        if (hasAudio)
                        {
                            //                            exportMovieWriter.audioSourceAsset = [audioSource getVideoAsset];
                        }
                        
                        exportMovieWriter.hasAudioTrack = hasAudio;
                        exportMovieWriter.encodingLiveVideo = YES;
                        [gpuMovie enableSynchronizedEncodingUsingMovieWriter:exportMovieWriter];
                        [gpuMovie addTarget:exportMovieWriter];
                        __block GPUImageMovieWriter *movieWritter = exportMovieWriter;
                        __block GPUImageMovie *movieFile = gpuMovie;
                        movieWritter.forceFps = YES;
                        movieWritter.fps = 31;
                        [exportMovieWriter setCompletionBlock:^{
                            [movieFile endProcessing];
                            [movieWritter finishRecordingWithCompletionHandler:^{
                                [movieWritter setFailureBlock:nil];
                                [movieWritter setCompletionBlock:nil];
                                if(handler != nil)
                                {
                                    handler(YES, outpath, nil);
                                }
                            }];
                        }];
                        [exportMovieWriter setFailureBlock:^(NSError *err)
                         {
                             NSLog(@"setFailureBlock failed!");
                             handler(NO, outpath, err);
                             [movieWritter setCompletionBlock:nil];
                             [movieWritter setFailureBlock:nil];
                         }];
                        [exportMovieWriter startRecording];
                        [gpuMovie startProcessing];
                        exportHandler = [[ExportHandler alloc] init];
                        exportHandler.movie = gpuMovie;
                        exportHandler.writter = exportMovieWriter;
                    }else
                    {
                        NSError *error = [NSError errorWithDomain:@"asset error" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"asset error" forKey:@"error"]];
                        if(handler != nil)
                        {
                            handler(NO , outpath, error);
                        }
                    }
                }else
                {
                    NSError *error = [NSError errorWithDomain:@"tmp path url error" code:-2 userInfo:[NSDictionary dictionaryWithObject:@"tmp path url error" forKey:@"error"]];
                    if(handler != nil)
                    {
                        handler(NO , outpath, error);
                    }
                }
            }else
            {
                NSError *error = [NSError errorWithDomain:@"tmp path error" code:-3 userInfo:[NSDictionary dictionaryWithObject:@"tmp path error" forKey:@"error"]];
                if(handler != nil)
                {
                    handler(NO , outpath, error);
                }
            }
        }else
        {
            NSDictionary *dic = [NSDictionary dictionaryWithObject:@"input video item is null" forKey:@"error"];
            NSError *error = [NSError errorWithDomain:@"input video item is null" code:-1 userInfo:dic];
            handler(NO, outpath, error);
        }
    }else
    {
        NSDictionary *dic = [NSDictionary dictionaryWithObject:@"export file path is empty" forKey:@"error"];
        NSError *error = [NSError errorWithDomain:@"export file path is empty" code:-1 userInfo:dic];
        handler(NO, outpath, error);
    }
    return exportHandler;
}


- (instancetype) initWithAVAsset:(AVAsset *) asset videoSize:(HAVVideoSize)avVideoSize{
    self = [super init];
    if(self){
        _asset = asset;
        _videoSize = avVideoSize;
    }
    return self;
}

- (CGSize) getVideoSize{
    return [self.asset videoSize:self.videoSize];
}

+ (HAVVideoExport *) createVideoAssetWithSize:(HAVVideoSize) avVideoSize withVideoItems:(NSArray *) videoItems withAudioUrl:(HAVAudioItem *) audioItem{
    AVMutableComposition *composition = [AVMutableComposition composition];
    NSMutableArray *audioMixParams = [[NSMutableArray alloc] init];
    if(videoItems.count > 0){
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *audioTrack = nil;
        AVMutableCompositionTrack *audioTrack2 = nil;
        AVAssetTrack *songAudioTrack = nil;
        //            CMTime audioDuration = kCMTimeZero;
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
        CGFloat songVolume = audioItem.volume;
        for (HAVVideoItem *videoItem in videoItems){
            volume = videoItem.volume;
            AVAsset *videoAsset = [videoItem getVideoAsset];
            AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
            AVAssetTrack *sourceAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            
            NSError *error = nil;
            BOOL ok = NO;
            CMTime startTime = CMTimeMultiply([sourceVideoTrack minFrameDuration], 3);
            CMTime trackDuration = [sourceVideoTrack timeRange].duration;
            trackDuration = CMTimeSubtract(trackDuration, startTime);
            CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
            ok = [videoTrack insertTimeRange:tRange ofTrack:sourceVideoTrack atTime:offset error:&error];
            if(sourceAudioTrack != nil){
                if(audioTrack == nil){
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
        AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
        [trackMix setVolume:volume atTime:kCMTimeZero];
        [audioMixParams addObject:trackMix];
        trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack2];
        [trackMix setVolume:songVolume atTime:kCMTimeZero];
        [audioMixParams addObject:trackMix];
    }
    HAVVideoExport *export = [[HAVVideoExport alloc] initWithAVAsset:composition videoSize:avVideoSize];
    return export;
    
}

// 本地视频导出，用于pk
+ (ExportHandler*) exportKeyFrameVideo:(NSString *) outPath videoSize:(HAVVideoSize) avVideoSize withVideoPath:(NSString *) localpath withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler{
    
    ExportHandler *exportHandler = nil;
    if(outPath != nil){
        unlink([outPath UTF8String]);
    }
    
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:localpath]];
    BOOL hasAudio = ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
    if(outPath != nil){
        
        NSURL *url  = [NSURL fileURLWithPath:outPath];
        CGSize videoSize = [asset videoSize:avVideoSize];
        if(url != nil){
            
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,@(videoSize.width),AVVideoWidthKey,@(videoSize.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(1),AVVideoMaxKeyFrameIntervalKey,
                                                           AVVideoProfileLevelH264High40,AVVideoProfileLevelKey,nil];
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            GPUImageMovieWriter *exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            if(asset != nil){
                
                HAVGPUImageMovie *gpuMovie = [[HAVGPUImageMovie alloc] initWithAsset:asset];
                gpuMovie.playAtActualSpeed = NO;
                gpuMovie.audioEncodingTarget = hasAudio?exportMovieWriter:nil;
                exportMovieWriter.hasAudioTrack = hasAudio;
                exportMovieWriter.encodingLiveVideo = YES;
                [gpuMovie enableSynchronizedEncodingUsingMovieWriter:exportMovieWriter];
                [gpuMovie addTarget:exportMovieWriter];
                __block GPUImageMovieWriter *movieWritter = exportMovieWriter;
                __block GPUImageMovie *movieFile = gpuMovie;
                [exportMovieWriter setCompletionBlock:^{
                    
                    [movieFile endProcessing];
                    [movieWritter finishRecordingWithCompletionHandler:^{
                        
                        [movieWritter setFailureBlock:nil];
                        [movieWritter setCompletionBlock:nil];
                        if(handler != nil){
                            handler(YES, outPath, nil);
                        }
                    }];
                }];
                [exportMovieWriter setFailureBlock:^(NSError *err){
                    NSLog(@"setFailureBlock failed!");
                    handler(NO, outPath, err);
                    [movieWritter setCompletionBlock:nil];
                    [movieWritter setFailureBlock:nil];
                }];
                [exportMovieWriter startRecording];
                [gpuMovie startProcessing];
                exportHandler = [[ExportHandler alloc] init];
                exportHandler.movie = gpuMovie;
                exportHandler.writter = exportMovieWriter;
                
            }else{
                NSError *error = [NSError errorWithDomain:@"asset error" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"asset error" forKey:@"error"]];
                if(handler != nil){
                    handler(NO , outPath, error);
                }
            }
        }else{
            NSError *error = [NSError errorWithDomain:@"tmp path url error" code:-2 userInfo:[NSDictionary dictionaryWithObject:@"tmp path url error" forKey:@"error"]];
            if(handler != nil){
                handler(NO , outPath, error);
            }
        }
    }else{
        NSError *error = [NSError errorWithDomain:@"tmp path error" code:-3 userInfo:[NSDictionary dictionaryWithObject:@"tmp path error" forKey:@"error"]];
        if(handler != nil){
            handler(NO , outPath, error);
        }
    }
    
    return exportHandler;
}

+ (ExportHandler *) exportKeyFrameVideo2:(NSString *) outPath videoSize:(HAVVideoSize) avVideoSize withVideoPath:(NSString *) localpath bitRate:(NSInteger) bitRate withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler{
    
    ExportHandler *exportHandler = nil;
    if(outPath != nil){
        unlink([outPath UTF8String]);
    }
    
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:localpath]];
    BOOL hasAudio = ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
    if(outPath != nil){
        
        NSURL *url  = [NSURL fileURLWithPath:outPath];
        CGSize videoSize = [asset videoSize:avVideoSize];
        if(url != nil){
            
            NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,@(videoSize.width),AVVideoWidthKey,@(videoSize.height),AVVideoHeightKey,@(YES),@"EncodingLiveVideo",nil];
            NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                           @(bitRate),AVVideoAverageBitRateKey,
                                                           @(1),AVVideoMaxKeyFrameIntervalKey,
                                                           AVVideoProfileLevelH264High40,
                                                           AVVideoProfileLevelKey,
                                                           nil];
            [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
            GPUImageMovieWriter *exportMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
            if(asset != nil){
                
                HAVGPUImageMovie *gpuMovie = [[HAVGPUImageMovie alloc] initWithAsset:asset];
                gpuMovie.playAtActualSpeed = NO;
                gpuMovie.audioEncodingTarget = hasAudio?exportMovieWriter:nil;
                exportMovieWriter.hasAudioTrack = hasAudio;
                exportMovieWriter.encodingLiveVideo = YES;
                [gpuMovie enableSynchronizedEncodingUsingMovieWriter:exportMovieWriter];
                [gpuMovie addTarget:exportMovieWriter];
                __block GPUImageMovieWriter *movieWritter = exportMovieWriter;
                __block GPUImageMovie *movieFile = gpuMovie;
                [exportMovieWriter setCompletionBlock:^{
                    
                    [movieFile endProcessing];
                    [movieWritter finishRecordingWithCompletionHandler:^{
                        
                        [movieWritter setFailureBlock:nil];
                        [movieWritter setCompletionBlock:nil];
                        if(handler != nil){
                            handler(YES, outPath, nil);
                        }
                    }];
                }];
                [exportMovieWriter setFailureBlock:^(NSError *err){
                    NSLog(@"setFailureBlock failed!");
                    handler(NO, outPath, err);
                    [movieWritter setCompletionBlock:nil];
                    [movieWritter setFailureBlock:nil];
                }];
                [exportMovieWriter startRecording];
                [gpuMovie startProcessing];
                exportHandler = [[ExportHandler alloc] init];
                exportHandler.movie = gpuMovie;
                exportHandler.writter = exportMovieWriter;
                
            }else{
                NSError *error = [NSError errorWithDomain:@"asset error" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"asset error" forKey:@"error"]];
                if(handler != nil){
                    handler(NO , outPath, error);
                }
            }
        }else{
            NSError *error = [NSError errorWithDomain:@"tmp path url error" code:-2 userInfo:[NSDictionary dictionaryWithObject:@"tmp path url error" forKey:@"error"]];
            if(handler != nil){
                handler(NO , outPath, error);
            }
        }
    }else{
        NSError *error = [NSError errorWithDomain:@"tmp path error" code:-3 userInfo:[NSDictionary dictionaryWithObject:@"tmp path error" forKey:@"error"]];
        if(handler != nil){
            handler(NO , outPath, error);
        }
    }
    
    return exportHandler;
}

//要求输入源必须是全I帧
+ (void) exportIReversedFile:(NSURL *)url outPath:(NSURL *)outPath completion:(void (^)(NSError *error))completion{
    AVAsset *assert = [AVAsset assetWithURL:url];
    AVAssetTrack *videoTrack = [[assert tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (!videoTrack) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Not find video track" forKey:NSLocalizedDescriptionKey];
        NSError *err = [NSError errorWithDomain:@"ExportIReversedFile" code:-10086 userInfo:userInfo];
        if (completion)
        {
            completion(err);
        }
        return ;
    }
    
    AVAssetTrack *audioTrack = [[assert tracksWithMediaType:AVMediaTypeAudio] firstObject];
    AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:assert error:nil];
    
    NSMutableArray *timeRangeArray = [NSMutableArray array];
    NSMutableArray *startTimeArray = [NSMutableArray array];
    CMTime startTime = kCMTimeZero;
    for (NSInteger i = 0; i <(CMTimeGetSeconds(assert.duration)); i ++)
    {
        CMTimeRange timeRange = CMTimeRangeMake(startTime, CMTimeMakeWithSeconds(1, assert.duration.timescale));
        if (CMTimeRangeContainsTimeRange(videoTrack.timeRange, timeRange))
        {
            [timeRangeArray addObject:[NSValue valueWithCMTimeRange:timeRange]];
        } else {
            timeRange = CMTimeRangeMake(startTime, CMTimeSubtract(assert.duration, startTime));
            [timeRangeArray addObject:[NSValue valueWithCMTimeRange:timeRange]];
        }
        [startTimeArray addObject:[NSValue valueWithCMTime:startTime]];
        CMTimeShow(startTime);
        startTime = CMTimeAdd(timeRange.start, timeRange.duration);
    }
    
    NSMutableArray *tracks = [NSMutableArray array];
    NSMutableArray *assets = [NSMutableArray array];
    
    for (NSInteger i = 0; i < timeRangeArray.count; i ++)
    {
        AVMutableComposition *subAsset = [[AVMutableComposition alloc] init];
        AVMutableCompositionTrack *subTrack =   [subAsset addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [subTrack  insertTimeRange:[timeRangeArray[i] CMTimeRangeValue] ofTrack:videoTrack atTime:[startTimeArray[i] CMTimeValue] error:nil];
        
        AVAsset *assetNew = [subAsset copy];
        AVAssetTrack *assetTrackNew = [[assetNew tracksWithMediaType:AVMediaTypeVideo] lastObject];
        [tracks addObject:assetTrackNew];
        [assets addObject:assetNew];
        
    }
    
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:nil];
    assetReaderOutput.alwaysCopiesSampleData = NO;
    
    if([assetReader canAddOutput:assetReaderOutput])
    {
        [assetReader addOutput:assetReaderOutput];
    }
    
    AVAssetReaderOutput *assetAudioReaderOutput = nil;
    if (audioTrack)
    {
        assetAudioReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
        assetAudioReaderOutput.alwaysCopiesSampleData = NO;
        if([assetReader canAddOutput:assetAudioReaderOutput])
        {
            [assetReader addOutput:assetAudioReaderOutput];
        }
    }
    
    
    __block AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:outPath
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
            if (completion) {
                completion(assetWriter.error);
            }
        });
        
        assetWriter = nil;
        myInputSerialQueue = nil;
    }];
}

+ (void) exportAudioFileWithNeededTime:(NSURL *)audioUrl output:(NSString *)outputPath dstDuration:(CMTime)dstDuration type:(ExportAudioFileType)type completion:(void (^)(NSError *error))completion
{
    if (!outputPath || CMTimeCompare(dstDuration, kCMTimeZero) == 0) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Para incorrect" forKey:NSLocalizedDescriptionKey];
        NSError *err = [NSError errorWithDomain:@"exportAudioFileWithNeededTime" code:-10087 userInfo:userInfo];
        if (completion){
            completion(err);
        }
        return ;
    }
    AVAsset *asset = [AVAsset assetWithURL:audioUrl];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if (!track) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"audio track nil" forKey:NSLocalizedDescriptionKey];
        NSError *err = [NSError errorWithDomain:@"exportAudioFileWithNeededTime" code:-10088 userInfo:userInfo];
        if (completion){
            completion(err);
        }
        return ;
    }
    
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *trackComposition = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, track.timeRange.duration);
    CMTime tmpAdd = kCMTimeZero;
    while (CMTimeCompare(tmpAdd, dstDuration) < 0) {
        NSLog(@"tmpAdd:%f dstDuration:%f", CMTimeGetSeconds(tmpAdd), CMTimeGetSeconds(dstDuration));
        CMTime t = CMTimeAdd(tmpAdd, track.timeRange.duration);
        if (CMTimeCompare(t, dstDuration) > 0 && type == ExportAudioFileNormal) {
            CMTimeRange r = CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(dstDuration, track.timeRange.duration));
            [trackComposition insertTimeRange:r ofTrack:track atTime:tmpAdd error:nil];
        }
        else {
            [trackComposition insertTimeRange:range ofTrack:track atTime:tmpAdd error:nil];
        }
        
        tmpAdd = CMTimeAdd(tmpAdd, track.timeRange.duration);
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.outputFileType = AVFileTypeAppleM4A;
    exporter.outputURL = [NSURL fileURLWithPath:outputPath];
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        int exportStatus = exporter.status;
        switch (exportStatus) {
            case AVAssetExportSessionStatusCompleted:{
                if (completion) {
                    completion(nil);
                }
                break;
            }
            case AVAssetExportSessionStatusFailed:
            case AVAssetExportSessionStatusUnknown:
            case AVAssetExportSessionStatusExporting:
            case AVAssetExportSessionStatusCancelled:
            case AVAssetExportSessionStatusWaiting:
            default:{
                if (completion) {
                    completion(exporter.error);
                }
                break;
            }
                
        }
    }];
    
}

+ (void)reverseAnyVideo:(NSString *)sourceUrl outputURL:(NSString *)outputURL videoSize:(HAVVideoSize)avVideoSize progressHandle:(void (^)(CGFloat progress))progressHandle cancle:(BOOL *)cancle finishHandle:(void (^)(BOOL flag, NSError *error))finishHandle{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *tmpUrl =  [documentsDirectory stringByAppendingPathComponent:@"tmp.mov"];
    [[NSFileManager defaultManager] removeItemAtPath:tmpUrl error:nil];
    
    if (*(cancle)) {
        return ;
    }
    NSError *error;
    //获取视频的总轨道
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:sourceUrl]];
    CMTime duration = asset.duration;
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    //    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    //按照每秒一个视频的长度，分割轨道，生成对应的时间范围
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
    
    AVAssetReader *totalReader = nil ;;
    
    NSDictionary *totalReaderOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
    AVAssetReaderOutput *totalReaderOutput = nil;
    
    totalReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:totalReaderOutputSettings];
    
    totalReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    if([totalReader canAddOutput:totalReaderOutput]){
        [totalReader addOutput:totalReaderOutput];
    } else {
        return ;
    }
    totalReaderOutput.alwaysCopiesSampleData = NO;
    
    //    AVAssetReaderOutput *assetAudioReaderOutput = nil;
    //    if (audioTrack)
    //    {
    //        assetAudioReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
    //        assetAudioReaderOutput.alwaysCopiesSampleData = NO;
    //        if([totalReader canAddOutput:assetAudioReaderOutput])
    //        {
    //            [totalReader addOutput:assetAudioReaderOutput];
    //        }
    //    }
    
    [totalReader startReading];
    NSMutableArray *sampleTimes = [NSMutableArray array];
    CMSampleBufferRef totalSample;
    
    while((totalSample = [totalReaderOutput copyNextSampleBuffer])) {
        CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(totalSample);
        [sampleTimes addObject:[NSValue valueWithCMTime:presentationTime]];
        CFRelease(totalSample);
    }
    
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
    
    //    AVAssetWriterInput *assetAudioWriterInput = nil;
    //    if (audioTrack) {
    //        assetAudioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil] ;
    //        assetAudioWriterInput.expectsMediaDataInRealTime = YES;
    //        [writer addInput:assetAudioWriterInput];
    //    }
    
    [writer startWriting];
    [writer startSessionAtSourceTime:videoTrack.timeRange.start];
    
    NSInteger counter = 0;
    size_t countOfFrames = 0;
    //    size_t totalCountOfArray = 40;
    //    size_t arrayIncreasment = 40;
    //    CMSampleBufferRef *sampleBufferRefs = (CMSampleBufferRef *) malloc(totalCountOfArray * sizeof(CMSampleBufferRef *));
    //    memset(sampleBufferRefs, 0, sizeof(CMSampleBufferRef *) * totalCountOfArray);
    
    NSMutableArray *sampless = [NSMutableArray array];
    
    for (NSInteger i = tracks.count -1; i <= tracks.count; i --) {
        if (*(cancle)) {
            [writer cancelWriting];
            //            free(sampleBufferRefs);
            return ;
        }
        AVAssetReader *reader = nil;
        
        countOfFrames = 0;
        AVAssetReaderOutput *readerOutput = nil;
        
        
        readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:tracks[i] outputSettings:totalReaderOutputSettings];
        readerOutput.alwaysCopiesSampleData = NO;
        
        //test
        //        AVMutableComposition *tt = compositions[i];
        //        CMTimeRange tt2 = [timeRangeArray[i] CMTimeRangeValue];
        //        [tt scaleTimeRange:tt2 toDuration:CMTimeMakeWithSeconds(3, duration.timescale)];
        //test end
        
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
                //                if (countOfFrames  + 1 > totalCountOfArray) {
                //                    totalCountOfArray += arrayIncreasment;
                //                    sampleBufferRefs = (CMSampleBufferRef *)realloc(sampleBufferRefs, totalCountOfArray);
                //                }
                //                *(sampleBufferRefs + countOfFrames) = sample;
                countOfFrames++;
                [sampless addObject:(__bridge id _Nonnull)(sample)];
            } else {
                if (sample != NULL) {
                    CFRelease(sample);
                }
            }
            //            [sampless addObject:(__bridge id _Nonnull)(sample)];
        }
        //        [sampless removeObjectAtIndex:0];
        
        [reader cancelReading];
        for(NSInteger j = 0; j < countOfFrames; j++) {
            // Get the presentation time for the frame
            if (counter > sampleTimes.count - 1) {
                break;
            }
            CMTime presentationTime = [sampleTimes[counter] CMTimeValue];
            
            // take the image/pixel buffer from tail end of the array
            //            CMSampleBufferRef bufferRef = *(sampleBufferRefs + countOfFrames - j - 1);
            CMSampleBufferRef bufferRef = (__bridge CMSampleBufferRef)sampless[countOfFrames - j - 1];
            CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer(bufferRef);
            
            while (!writerInput.readyForMoreMediaData) {
                //                NSLog(@"waitting...");
                [NSThread sleepForTimeInterval:0.05];
            }
            [pixelBufferAdaptor appendPixelBuffer:imageBufferRef withPresentationTime:presentationTime];
            if (progressHandle) {
                progressHandle(((CGFloat)counter/(CGFloat)sampleTimes.count));
            }
            
            counter++;
            CFRelease(bufferRef);
            //            *(sampleBufferRefs + countOfFrames - j - 1) = NULL;
        }
    }
    
    //    free(sampleBufferRefs);
    
    
    [writer finishWritingWithCompletionHandler:^{
        NSLog(@"Video finished.");
        NSLog(@"田老师开始做spa...");
        AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:sourceUrl]];
        AVAssetTrack *audioTrack2 = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        if (!audioTrack2) {
            NSError *error;
            [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:tmpUrl] toURL:[NSURL fileURLWithPath:outputURL] error:&error];
            if (finishHandle) {
                finishHandle(YES, error);
                [[NSFileManager defaultManager] removeItemAtPath:tmpUrl error:nil];
                NSLog(@"田老师做完spa了");
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
                                          presetName: [composition presetFromVideoSize:avVideoSize]];
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        
        /** 导出的文件存在即删除**/
        if ([[NSFileManager defaultManager] fileExistsAtPath:outputURL]) {
            [[NSFileManager defaultManager] removeItemAtPath:outputURL error:nil];
        }
        NSURL *exportURL = [NSURL fileURLWithPath:outputURL];
        exporter.outputURL = exportURL;
        //        if( composition != nil && CMTimeCompare([ composition duration] , kCMTimeZero ) > 0){
        //            exporter.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
        //        }
        exporter.shouldOptimizeForNetworkUse = YES;
        //        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        //        AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
        ////        [trackMix setVolume:volume atTime:kCMTimeZero];
        //        audioMix.inputParameters = @[trackMix];
        //        exporter.audioMix = audioMix;
        
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            int exportStatus = exporter.status;
            switch (exportStatus) {
                case AVAssetExportSessionStatusCompleted:{
                    if (finishHandle) {
                        NSLog(@"田老师做完spa了");
                        finishHandle(YES, exporter.error);
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
                        finishHandle(NO, exporter.error);
                        [[NSFileManager defaultManager] removeItemAtPath:tmpUrl error:nil];
                    };
                }
                    break;
            }
        }];
    }];
    
}
@end

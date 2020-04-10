//
//  HAVVideoClip.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVVideoClip.h"
#import "AVURLAsset+MetalData.h"

@implementation HAVVideoClip

- (instancetype) init
{
    self = [super init];
    if(self){
        self.volume = 1.0f;
        self.rate = 1.0f;
        self.startTime = 0.0f;
        self.duration = 0.0f;
    }
    return self;
}

- (NSString *) naturalVideoSize:(AVURLAsset *) videoAsset{
    if(videoAsset != nil){
        CGSize videoSize = [videoAsset videoNaturalSize];
        if(CGSizeEqualToSize(videoSize, CGSizeMake(640, 480))
           || CGSizeEqualToSize(videoSize, CGSizeMake(480, 640))){
            return AVAssetExportPreset640x480;
        }
        if(CGSizeEqualToSize(videoSize, CGSizeMake(960, 540))
           || CGSizeEqualToSize(videoSize, CGSizeMake(540, 960))){
            return AVAssetExportPreset960x540;
        }
        if(CGSizeEqualToSize(videoSize, CGSizeMake(1280, 720))
           || CGSizeEqualToSize(videoSize, CGSizeMake(720, 1280))){
            return AVAssetExportPreset1280x720;
        }
        if(CGSizeEqualToSize(videoSize, CGSizeMake(1920, 1080))
           || CGSizeEqualToSize(videoSize, CGSizeMake(1080, 1920))){
            return AVAssetExportPreset1920x1080;
        }
        if(CGSizeEqualToSize(videoSize, CGSizeMake(3840, 2160))
           || CGSizeEqualToSize(videoSize, CGSizeMake(2160, 3840))){
            return AVAssetExportPreset3840x2160;
        }
    }
    return AVAssetExportPreset960x540;
}

- (NSString *) videoSizePreset:(AVURLAsset *) videoAsset{
    switch (self.videoSize) {
        case HAVVideoSize480p:{
            return AVAssetExportPreset640x480;
        }
            break;
        case HAVVideoSize540p:{
            return AVAssetExportPreset960x540;
        }
            break;
        case  HAVVideoSize720p:{
            return AVAssetExportPreset1280x720;
        }
            break;
        case  HAVVideoSize1080p:{
            return AVAssetExportPreset1920x1080;
        }
            break;
        case  HAVVideoSize4K:{
            return AVAssetExportPreset3840x2160;
        }
            break;
        default:{
            return [self naturalVideoSize:videoAsset];
        }
            break;
    }
}

- (void) clipVideo:(NSString *) exportFile handler:(void (^) (BOOL status,NSString *path, NSError *error)) handler
{
    if((self.localPath != nil) && (exportFile != nil)){
        NSURL *url = [NSURL fileURLWithPath:self.localPath];
        if(url != nil){
            AVURLAsset *videoAsset = [AVURLAsset assetWithURL:url];
            if(videoAsset != nil){
                NSError *error = nil;
                BOOL ret = NO;
                AVMutableComposition *composition = [AVMutableComposition composition];
                AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
                CMTime startTime = kCMTimeZero;
                CMTime trackDuration = [videoAsset duration];
                CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
                ret = [videoTrack insertTimeRange:tRange ofTrack:sourceVideoTrack atTime:kCMTimeZero error:&error];
                if(!ret){
                    handler(NO, exportFile, error);
                }
                
                NSMutableArray *audioMixParams = [[NSMutableArray alloc] init];
                if(!self.isMute){
                    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                    AVAssetTrack *sourceAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
                    CMTime startTime = kCMTimeZero;
                    CMTime trackDuration = [videoAsset duration];
                    if(self.volume < 1.0f){
                        AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
                        [trackMix setVolume:self.volume atTime:startTime];
                        [audioMixParams addObject:trackMix];
                    }
                    CMTimeRange tRange = CMTimeRangeMake(startTime, trackDuration);
                    ret =  [audioTrack insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:kCMTimeZero error:&error];
                    if(!ret){
                        handler(NO, exportFile, error);
                    }
                }
                
                AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                                  initWithAsset: composition
                                                  presetName: [self videoSizePreset:videoAsset]];
                exporter.outputFileType = AVFileTypeQuickTimeMovie;
                
                if(audioMixParams.count > 0){
                    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
                    audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
                    exporter.audioMix = audioMix;
                }
                
                /** 导出的文件存在即删除**/
                if ([[NSFileManager defaultManager] fileExistsAtPath:exportFile]) {
                    [[NSFileManager defaultManager] removeItemAtPath:exportFile error:nil];
                }
                NSURL *exportURL = [NSURL fileURLWithPath:exportFile];
                exporter.outputURL = exportURL;
                if((self.startTime > 0) && (self.duration > 0)){////prneferredTimescale
                    Float64 totalDuration = CMTimeGetSeconds([videoAsset duration]);
                    if((totalDuration < self.startTime) && (totalDuration > self.duration)){
                        int32_t preferredTimescale = [videoAsset duration].timescale;
                        CMTime start = kCMTimeZero;
                        CMTime duration = CMTimeMake(self.duration*preferredTimescale, preferredTimescale);
                        exporter.timeRange = CMTimeRangeMake(start,duration);
                    }else if((totalDuration > self.startTime) && (totalDuration > self.startTime + self.duration)){
                        int32_t preferredTimescale = [videoAsset duration].timescale;
                        CMTime start = CMTimeMake(self.startTime*preferredTimescale, preferredTimescale);
                        CMTime duration = CMTimeMake(self.duration*preferredTimescale, preferredTimescale);
                        exporter.timeRange = CMTimeRangeMake(start,duration);
                        
                    }else if((totalDuration > self.startTime) && (totalDuration <= self.startTime + self.duration)){
                        int32_t preferredTimescale = [videoAsset duration].timescale;
                        CMTime start = CMTimeMake(self.startTime*preferredTimescale, preferredTimescale);
                        CMTime duration = CMTimeMake((totalDuration - self.startTime)*preferredTimescale, preferredTimescale);
                        exporter.timeRange = CMTimeRangeMake(start,duration);
                    }
                }
                exporter.shouldOptimizeForNetworkUse = YES;
                [exporter exportAsynchronouslyWithCompletionHandler:^{
                    int exportStatus = exporter.status;
                    switch (exportStatus) {
                        case AVAssetExportSessionStatusCompleted:{
                            handler(YES, exportFile, exporter.error);
                        }
                            break;
                        case AVAssetExportSessionStatusFailed:
                        case AVAssetExportSessionStatusUnknown:
                        case AVAssetExportSessionStatusExporting:
                        case AVAssetExportSessionStatusCancelled:
                        case AVAssetExportSessionStatusWaiting:
                        default:  {
                            handler(NO, exportFile, exporter.error);
                        }
                            break;
                    }
                }];
            }
        }
    }
}
@end

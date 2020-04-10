//
//  HAVSynthesis.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVSynthesis.h"
#import "HAVSynthesis.h"

@interface HAVSynthesis()

@property (nonatomic, strong) NSMutableArray *audioTracks;
@property (nonatomic, strong) HAVVideoTrack *videoTrack;

@end

@implementation HAVSynthesis

- (instancetype) init{
    self = [super init];
    if(self){
        _audioTracks = [[NSMutableArray alloc] init];
        self.videoSize = HAVVideoSizeNature;
    }
    return self;
}

- (void) addAudioTrack:(HAVAudioTrack*)audioTrack{
    if((_audioTracks != nil) && (audioTrack != nil)){
        [_audioTracks  addObject:audioTrack];
    }
}

- (void) setVideoTrack:(HAVVideoTrack*)videoTrack{
    _videoTrack = videoTrack;
}

- (NSString *) videoSizePreset{
    return [_videoTrack videoSizeToPreset:self.videoSize];
}

- (AVPlayerItem *) createPlayerItem{
    AVMutableComposition *composition = [AVMutableComposition composition];
    NSMutableArray *audioMixParams = [[NSMutableArray alloc] init];
    
    /** 给多个 video 添加到同一轨道**/
    if(_videoTrack != nil){
        [_videoTrack addToComposition:composition];
        NSArray *array = [_videoTrack getAudioMixInputParameters];
        if(array.count > 0){
            [audioMixParams addObjectsFromArray:array];
        }
    }
    CMTime offset = kCMTimeZero;
    /** 给每一个audio 添加到一个轨道**/
    for (HAVAudioTrack *audioTrack in _audioTracks){
        AVMutableAudioMixInputParameters *inputParameters = [audioTrack createAudioMixInputParameters:composition atOffsetTime:offset];
        if(inputParameters != nil){
            [audioMixParams addObject:inputParameters];
        }
        offset = CMTimeAdd(offset, [audioTrack duration]);
    }
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
    AVPlayerItem * playerItem = [[AVPlayerItem alloc] initWithAsset:composition];
    playerItem.audioMix =audioMix;
    return playerItem;
}

- (AVAsset *) getAsset{
    AVMutableComposition *composition = [AVMutableComposition composition];
    NSMutableArray *audioMixParams = [[NSMutableArray alloc] init];
    
    /** 给多个 video 添加到同一轨道**/
    if(_videoTrack != nil){
        [_videoTrack addToComposition:composition];
        NSArray *array = [_videoTrack getAudioMixInputParameters];
        if(array.count > 0){
            [audioMixParams addObjectsFromArray:array];
        }
    }
    CMTime offset = kCMTimeZero;
    /** 给每一个audio 添加到一个轨道**/
    for (HAVAudioTrack *audioTrack in _audioTracks){
        AVMutableAudioMixInputParameters *inputParameters = [audioTrack createAudioMixInputParameters:composition atOffsetTime:offset];
        if(inputParameters != nil){
            [audioMixParams addObject:inputParameters];
        }
        offset = CMTimeAdd(offset, [audioTrack duration]);
    }
    
    return composition;
    
}

- (void) exportVideo:(NSString *) exportFile handler:(void (^) (BOOL status,NSString *path, NSError *error)) handler{
    if(exportFile != nil){
        AVMutableComposition *composition = [AVMutableComposition composition];
        NSMutableArray *audioMixParams = [[NSMutableArray alloc] init];
        
        /** 给多个 video 添加到同一轨道**/
        if(_videoTrack != nil){
            [_videoTrack addToComposition:composition];
            NSArray *array = [_videoTrack getAudioMixInputParameters];
            if(array.count > 0){
                [audioMixParams addObjectsFromArray:array];
            }
        }
        CMTime offset = kCMTimeZero;
        /** 给每一个audio 添加到一个轨道**/
        for (HAVAudioTrack *audioTrack in _audioTracks){
            AVMutableAudioMixInputParameters *inputParameters = [audioTrack createAudioMixInputParameters:composition atOffsetTime:offset];
            if(inputParameters != nil){
                [audioMixParams addObject:inputParameters];
            }
            offset = CMTimeAdd(offset, [audioTrack duration]);
        }
        
        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                          initWithAsset: composition
                                          presetName: [self videoSizePreset]];
        exporter.audioMix = audioMix;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        
        /** 导出的文件存在即删除**/
        if ([[NSFileManager defaultManager] fileExistsAtPath:exportFile]) {
            [[NSFileManager defaultManager] removeItemAtPath:exportFile error:nil];
        }
        NSURL *exportURL = [NSURL fileURLWithPath:exportFile];
        exporter.outputURL = exportURL;
        if( _videoTrack != nil && CMTimeCompare([ _videoTrack duration] , kCMTimeZero ) > 0){
            exporter.timeRange = CMTimeRangeMake(kCMTimeZero, [_videoTrack duration]);
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
                default:{
                    handler(NO, exportFile, exporter.error);
                }
                    break;
            }
        }];
    }else{
        NSDictionary *dic = [NSDictionary dictionaryWithObject:@"export file path is empty" forKey:@"error"];
        NSError *error = [NSError errorWithDomain:@"export file path is empty" code:-1 userInfo:dic];
        handler(NO, exportFile, error);
    }
}

@end

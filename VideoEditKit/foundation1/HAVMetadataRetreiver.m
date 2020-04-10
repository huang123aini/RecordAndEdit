//
//  HAVMetadataRetreiver.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVMetadataRetreiver.h"
#import "AVAsset+MetalData.h"

@implementation HAVMetadataRetreiver

+ (HAVMetadata*) metadataRetreiver:(NSString *) path
{
    if(path != nil)
    {
        NSURL *url = [NSURL fileURLWithPath:path];
        if(url != nil)
        {
            return [self metadataRetreiverUrl:url];
        }
    }
    return nil;
}

+ (HAVMetadata*) metadataRetreiverUrl:(NSURL *) url
{
    if(url != nil){
        AVAsset *asset = [AVAsset assetWithURL:url];
        if(asset != nil){
            HAVMetadata *metadata = [[HAVMetadata alloc] init];
            metadata.mediaSize = [asset videoNaturalSize];
            metadata.duration = CMTimeGetSeconds([asset duration]);
            return metadata;
        }
    }
    return nil;
}

+ (BOOL) vaildVideo:(NSURL *) url{
    BOOL hasVideo = NO;
    if(url != nil){
        AVAsset *asset = [AVAsset assetWithURL:url];
        hasVideo = ([[asset tracksWithMediaType:AVMediaTypeVideo] count]> 0);
    }
    return hasVideo;
}

+ (NSTimeInterval) audioDurationWithUrl:(NSURL *) url{
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    return CMTimeGetSeconds([audioTrack timeRange].duration);
}

+ (NSTimeInterval) audioDurationWithPath:(NSString *) path{
    return [self audioDurationWithUrl:[NSURL fileURLWithPath:path]];
}

@end

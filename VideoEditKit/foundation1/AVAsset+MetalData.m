//
//  AVAsset+MetalData.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "AVAsset+MetalData.h"

#define FFALIGN2(x, a) (((x)+(a)-1)&~((a)-1))

@implementation AVAsset (MetalData)

-(CGSize) videoNaturalSize
{
    
    CGSize size = CGSizeZero;
    NSArray* allVideoTracks = [self tracksWithMediaType:AVMediaTypeVideo];
    if ([allVideoTracks count] > 0)
    {
        AVAssetTrack* track = [[self tracksWithMediaType:AVMediaTypeVideo] firstObject];
        size = [track naturalSize];
    }
    return size;
}

- (CGSize) videoSize:(HAVVideoSize) videosize
{
    CGSize size = [self videoNaturalSize];
    switch (videosize)
    {
        case HAVVideoSizeNature:
            return size;
            break;
        case HAVVideoSize360p:
        {
            if(size.height > size.width)
            {
                return  CGSizeMake(360, 640);
            }else
            {
                return  CGSizeMake(640, 360);
            }
        }
        case HAVVideoSize480p:{
            if(size.height > size.width){
                return  CGSizeMake(480, 640);
            }else{
                return  CGSizeMake(640, 480);
            }
        }
            break;
        case HAVVideoSize540p:{
            if(size.height > size.width){
                return  CGSizeMake(540, 960);
            }else{
                return  CGSizeMake(960, 540);
            }
            
        }
            break;
        case HAVVideoSize720p:{
            if(size.height > size.width){
                return  CGSizeMake(720, 1280);
            }else{
                return  CGSizeMake(1280, 720);
            }
            
        }
            break;
        case HAVVideoSize1080p:{
            if(size.height > size.width){
                return  CGSizeMake(1080, 1920);
            }else{
                return  CGSizeMake(1920, 1080);
            }
            
        }
            break;
        case HAVVideoSize4K:{
            if(size.height > size.width){
                return  CGSizeMake(2160, 3840);
            }else{
                return  CGSizeMake(3840, 2160);
            }
            
        }
            break;
            
        case HAVVideoSizeCustom540:{
            if(size.height > size.width){///540p
                if(size.height * 540 > 960 * size.width){
                    int width = (size.width * 960) / size.height;
                    width = FFALIGN2(width,2);
                    return CGSizeMake(width, 960);
                }else{
                    int height = (size.height * 540)/size.width;
                    height = FFALIGN2(height,2);
                    return CGSizeMake(540, height);
                }
            }else{
                if(size.height * 960 > 540 * size.width){
                    int width = (size.width * 540) / size.height;
                    width = FFALIGN2(width, 2);
                    return CGSizeMake(width, 540);
                }else{
                    int height = (size.height * 960) / size.width;
                    height = FFALIGN2(height,2);
                    return CGSizeMake(960, height);
                }
            }
        }
            break;
        default:
            return size;
            break;
    }
}

- (NSString *) videoSizePreset{
    CGSize videoSize = [self videoNaturalSize];
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
    return AVAssetExportPreset960x540;
}

- (NSString *) presetFromVideoSize:(HAVVideoSize) videoSize{
    switch (videoSize) {
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
            return [self videoSizePreset];
        }
            break;
    }
    
}

@end

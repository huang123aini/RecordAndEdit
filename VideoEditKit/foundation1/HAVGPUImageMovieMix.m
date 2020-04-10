//
//  HAVGPUImageMovieMix.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVGPUImageMovieMix.h"
@interface  HAVGPUImageMovieMix ()

@property (nonatomic, strong) AVURLAsset *videoAsset;
@property (nonatomic, strong) AVURLAsset *audioAsset;

@end

@implementation HAVGPUImageMovieMix

- (id) initWithVideoFile:(NSString *) videoFile AudioFile:(NSString *) audioFile{
    if(videoFile.length > 0)
    {
        NSURL *url = [NSURL fileURLWithPath:videoFile];
        if(url != nil)
        {
            _videoAsset = [AVURLAsset assetWithURL:url];
        }
    }
    if(audioFile.length > 0)
    {
        NSURL *url = [NSURL fileURLWithPath:audioFile];
        if(url != nil)
        {
            _audioAsset = [AVURLAsset assetWithURL:url];
        }
    }
    return self;
}
@end

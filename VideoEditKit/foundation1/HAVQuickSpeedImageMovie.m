//
//  HAVQuickSpeedImageMovie.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVQuickSpeedImageMovie.h"

@interface HAVQuickSpeedImageMovie ()
{
    CMTime currentFrameTime;
    CVImageBufferRef currentPixelBuffer;
}

@end

@implementation HAVQuickSpeedImageMovie

- (void)processMovieFrame:(CMSampleBufferRef)movieSampleBuffer
{
    
    CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(movieSampleBuffer);
    if(currentPixelBuffer != NULL){
        CMTime lastFrameTime = currentFrameTime;
        CMTime diff = CMTimeAdd(lastFrameTime, CMTimeMake(1, 20));
        while(CMTimeCompare(currentSampleTime, diff) > 0){
            lastFrameTime = CMTimeAdd(lastFrameTime, CMTimeMake(1, 30));
            [self processMovieFrame:currentPixelBuffer withSampleTime:lastFrameTime];
            diff = CMTimeAdd(lastFrameTime, CMTimeMake(1, 20));
        }
        CFRelease(currentPixelBuffer);
        currentPixelBuffer = NULL;
    }
    CVImageBufferRef movieFrame = CMSampleBufferGetImageBuffer(movieSampleBuffer);
    [self processMovieFrame:movieFrame withSampleTime:currentSampleTime];
    currentPixelBuffer = movieFrame;
    currentFrameTime = currentSampleTime;
    CFRetain(currentPixelBuffer);
}

-(void)dealloc{
    if(currentPixelBuffer != NULL){
        CFRelease(currentPixelBuffer);
        currentPixelBuffer = NULL;
    }
}

@end

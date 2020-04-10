//
//  HAVAssetReaderOutput.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVAssetReaderOutput.h"

@interface HAVAssetReaderOutput()
{
    CMSampleBufferRef currentBuffer;
    CMSampleBufferRef nextBuffer;
}

@end

@implementation HAVAssetReaderOutput

- (CMSampleBufferRef) readNextSampleBuffer
{
    return [self copyNextSampleBuffer];
}

- (CVPixelBufferRef) copyPixelBufferForItemTime:(CMTime) time
{
    if((currentBuffer == NULL) && (nextBuffer == NULL))
    {
        currentBuffer = [self readNextSampleBuffer];
        nextBuffer = [self readNextSampleBuffer];
    }

    if((currentBuffer != NULL) && (nextBuffer != NULL))
    {
        CGFloat frameTime = CMTimeGetSeconds(time);
        CMTime currentTime = CMSampleBufferGetOutputPresentationTimeStamp(currentBuffer);
        CMTime nextTime = CMSampleBufferGetOutputPresentationTimeStamp(nextBuffer);
        CGFloat currentFrameTime = CMTimeGetSeconds(currentTime);
        CGFloat nextFrameTime = CMTimeGetSeconds(nextTime);
        if((currentFrameTime <= frameTime) &&
           (frameTime <= nextFrameTime)){
            if((frameTime - currentFrameTime ) > (nextFrameTime - frameTime)){
                CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(nextBuffer);
                CFRetain(buffer);
                return buffer;
            }else{
                CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(currentBuffer);
                CFRetain(buffer);
                return buffer;
            }
        }else if(frameTime <= currentFrameTime){
            CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(currentBuffer);
            CFRetain(buffer);
            return buffer;
        }else if(frameTime >= nextFrameTime){
            CFRelease(currentBuffer);
            currentBuffer = nextBuffer;
            CMSampleBufferRef bufferRef = [self readNextSampleBuffer];
            nextBuffer = bufferRef;
            return [self copyPixelBufferForItemTime:time];
        }
    }else{ ///数据读取到头了
        return NULL;
    }
    return NULL;
}

-(void)dealloc
{
    if(nextBuffer != NULL){
        CFRelease(nextBuffer);
        nextBuffer = NULL;
    }
    if(currentBuffer != NULL){
        CFRelease(currentBuffer);
        currentBuffer = NULL;
    }
}
@end


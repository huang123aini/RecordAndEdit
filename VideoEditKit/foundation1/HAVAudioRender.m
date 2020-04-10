//
//  HAVAudioRender.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVAudioRender.h"
#import <AudioToolbox/AudioToolbox.h>

static UInt32 gBufferSizeBytes=0x10000;

#define NUM_BUFFERS 3

@interface HAVAudioRender ()
{
    AudioQueueRef audioQueue ;
    AudioQueueBufferRef buffers[NUM_BUFFERS];
    AudioStreamPacketDescription *packetDescs;
    NSMutableArray *audioDataArray ;
}
-(void) audioQueueOutputWithQueue:(AudioQueueRef)audioQueue queueBuffer:(AudioQueueBufferRef)audioQueueBuffer;
@end

@implementation HAVAudioRender
void audioQueueOutputCallback(
                              void * __nullable       inUserData,
                              AudioQueueRef           inAQ,
                              AudioQueueBufferRef     inBuffer){
    HAVAudioRender* render=(__bridge HAVAudioRender*)inUserData;
    [render audioQueueOutputWithQueue:inAQ queueBuffer:inBuffer];
};

- (instancetype) init{
    self = [super init];
    if(self){
        audioQueue = NULL;
    }
    return self;
}


- (void) initRender:(CMSampleBufferRef)audioBuffer
{
    AudioStreamBasicDescription inAudioStreamBasicDescription = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(audioBuffer));
    OSStatus err = AudioQueueNewOutput(&inAudioStreamBasicDescription, audioQueueOutputCallback, (__bridge void*)self, NULL, NULL, 0, &audioQueue);
    if(err != noErr)
    {
        //never errs, am using breakpoint to check
        CFRelease(audioQueue);
        audioQueue = NULL;
    }
    for (int i=0; i<NUM_BUFFERS; i++)
    {
        AudioQueueAllocateBuffer(audioQueue, gBufferSizeBytes, &buffers[i]);
        //读取包数据
        [self audioQueueOutputWithQueue:audioQueue queueBuffer:buffers[i]];
    }
    AudioQueueStart(audioQueue, nil);
    
}

-(void) audioQueueOutputWithQueue:(AudioQueueRef)audioQueue queueBuffer:(AudioQueueBufferRef)audioQueueBuffer
{

}


- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer{
    
    if(audioBuffer != NULL){
        
        if(audioQueue == NULL){
            [self initRender:audioBuffer];
        }
        AudioBufferList audioBufferList;
        //    NSMutableData *data = [NSMutableData data];
        CMBlockBufferRef blockBuffer;
        OSStatus status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(audioBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
        //     NSLog(@"noErr AudioRender %ld",status);
        if(status == noErr){
            
            for( int y=0; y<audioBufferList.mNumberBuffers; y++ )
            {
                //        NSData* throwData;
                AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
                //        [self.delegate streamer:self didGetAudioBuffer:audioBuffer];
                
                //             Float32 *frame = (Float32*)audioBuffer.mData;
                NSData *throwData = [NSData dataWithBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
                @synchronized (audioDataArray) {
                    [audioDataArray addObject:throwData];
                }
                //             [self.delegate streamer:self didGetAudioBuffer:throwData];
                //             [data appendBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
                
            }
            CFRelease(blockBuffer);
            //        CFRelease(audioBufferList);
        }
    }
}
@end

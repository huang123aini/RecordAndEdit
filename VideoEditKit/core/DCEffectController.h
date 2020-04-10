//
//  DCEffectController.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUKit/GPUKit.h>
#import "HAVGPUImageFilterManager.h"
#import "HAVVideoWaterMark.h"
//#import "HAVPusherDelegate.h"
//#import "HAVRtmpWriter.h"

@class DCSpecialEffectsView;

@interface DCEffectController : NSObject

@property (nonatomic, assign) BOOL supportGhost;

@property (nonatomic, strong, readonly) HAVGPUImageFilterManager *filterManager;
@property (nonatomic, readonly) CMTime recordDuration;
@property (nonatomic, strong) NSDictionary *stSetting;
@property (nonatomic, copy) void (^updatePCMBuffer)(int16_t *buffer, int32_t len);

//@property (nonatomic,weak)id<HAVPushVideoDelegate> pushVideoDelegate;

- (void) setPreView:(DCSpecialEffectsView *) preview;

- (void) setDataSource:(GPUImageOutput*) dataSource;

//-(void)setRtmpWriter:(HAVRtmpWriter*)rtmpWriter;

- (void) startGhost;

- (void) clearGhost;

- (void) stopGhost;

- (void) changeGPUPipeline;

- (void) setPlayRate:(CGFloat) rate;

- (void) setIsBattle:(BOOL)isBattle;

- (void) setGhostImage:(UIImage *) image;

- (UIImage *) getCurrentGhostImage;

- (void) getCurrentGhostImage:(void (^)(UIImage *)) hander;
- (NSTimeInterval) getCurrentSectionTime;

- (void) stopSaveFile;

- (void) stopSaveFileWithCompleteBlock:(void (^)(BOOL complete)) block;

- (BOOL) stopSaveFileBackground;

- (void) startSaveVideoFile:(NSString *)videoPath hasAudio:(BOOL) hasAudio bitRate:(NSInteger) bitRate waterMark:(HAVVideoWaterMark *) waterMark;

- (void) startSaveVideoFile:(NSString *)videoPath hasAudio:(BOOL) hasAudio bitRate:(NSInteger) bitRate waterMark:(HAVVideoWaterMark *) waterMark outSize:(CGSize)outSize;

- (void) startSaveVideoFileWithSettings:(NSString *)videoPath hasAudio:(BOOL) hasAudio settings:(NSDictionary *) settings waterMark:(HAVVideoWaterMark *) waterMark;

-(CVPixelBufferRef)resultPixelBuffer;

-(void)pushEffectedVideo;
-(void)getCoverImage:(void (^)(UIImage *)) hander;


@end

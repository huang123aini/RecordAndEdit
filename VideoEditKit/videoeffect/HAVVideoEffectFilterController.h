//
//  HAVVideoEffectFilterController.h
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVGPUImageFilterProtocol.h"
@interface HAVVideoEffectFilterController : NSObject <HAVGPUImageFaceTrackProtocol>

- (instancetype) init;

- (void) reset;

- (void) clear;

- (void) back;

- (Float64) currentFrameTime;

- (void) seekToTime:(Float64) frameTime;

- (void) setVideoEffectID:(int) effectId;

- (NSArray *) archiver;

- (void) unArchiver:(NSArray *) array;

- (void) setReverse:(BOOL) reverse;

- (void) setDuration:(CGFloat)duration;

- (void) setSoulImage:(UIImage*)soulImage;

- (void) setSoulInfoss:(NSArray*)array;

- (void) remove;

- (void) changeVideoEffectID:(int) effectId;

- (void) stopCurrentEffect;

@end

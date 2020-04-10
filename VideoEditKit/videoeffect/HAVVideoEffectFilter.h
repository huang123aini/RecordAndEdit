//
//  HAVVideoEffectFilter.h
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>
@interface HAVVideoEffectFilter : GPUImageFilter

- (instancetype) init;
- (void) reset;

- (void) back;

- (void) seekToTime:(Float64)frameTime;

- (Float64) currentFrameTime;

- (void) setVideoEffectID:(int) effectId;

- (void) changeVideoEffectID:(int) effectId;

- (NSArray *) archiver;

- (void) unArchiver:(NSArray *) array;

- (void) setReverse:(BOOL) reverse;

- (void) setDuration:(CGFloat)duration;

- (void) clearVideoEffects;

- (void)setSoulImage:(UIImage*)soulImage;

- (void) setSoulInfoss:(NSArray*)array;

- (void) remove;

- (void) stopCurrentEffect;

@end

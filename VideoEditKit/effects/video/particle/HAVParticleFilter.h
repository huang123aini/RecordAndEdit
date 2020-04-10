//
//  HAVParticleFilter.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>
@interface HAVParticleFilter : GPUImageFilter

- (instancetype) init;

- (void) back;

- (void) stop;

- (void) reset;

- (void) removeAllMagic;

- (void) changeSourcePosition:(CGPoint) position;

- (void) addParticle:(NSString *) file atPosition:(CGPoint) point;

- (void) addParticles:(NSArray *) files atPosition:(CGPoint) point;

- (NSArray *) archiver;

- (void) unarchiver:(NSArray *) array;

@end

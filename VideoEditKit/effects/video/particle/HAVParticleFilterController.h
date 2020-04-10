//
//  HAVParticleFilterController.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVGPUImageFilterProtocol.h"
#import <Foundation/Foundation.h>

@interface HAVParticleFilterController : NSObject <HAVGPUImageFaceTrackProtocol>

- (instancetype) init ;

- (void) stop;

- (void) back;

- (void) reset;

- (NSArray *) archiver;

- (void) removeAllMagic;

- (void) unarchiver:(NSArray *) array;

/**
 ** position 范围 0.0 ~ 1.0
 **/

- (void) changeSourcePosition:(CGPoint) position;

/**
 ** position 范围 0.0 ~ 1.0
 **/

- (void) addParticle:(NSString *) file atPosition:(CGPoint) point;

/**
 ** position 范围 0.0 ~ 1.0
 **/

- (void) addParticles:(NSArray *) files atPosition:(CGPoint) point;

@end

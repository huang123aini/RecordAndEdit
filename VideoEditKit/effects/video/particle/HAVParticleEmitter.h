//
//  HAVParticleEmitter.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVParticle.h"
#import <Foundation/Foundation.h>

enum kParticleTypes {
    kParticleTypeGravity,
    kParticleTypeRadial
};

@interface HAVParticleEmitter : NSObject <NSCoding>

@property (nonatomic, assign) GLKVector2 sourcePosition;
@property (nonatomic, assign) GLint particleCount;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) GLfloat duration;

- (instancetype) initParticleEmitterWithFile:(NSString*)filePath;

- (void)renderParticles;

- (void)updateWithDelta:(GLfloat)aDelta;

- (void)stopParticleEmitter;

- (void)reset;

- (void)usePrograma;

- (instancetype) initWithCoder:(NSCoder *)aDecoder;

- (GLfloat) particleMaxLiveTime;

- (void) setResolution:(CGSize) size;

@end

//
//  HAVParticleSystem.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>

@interface HAVParticleSystem : NSObject <NSCoding>

@property (nonatomic, assign) CGFloat startTime;
@property (nonatomic, assign) CGFloat endTime;

- (instancetype) initWithConfigFile:(NSString *) configFile;
- (instancetype) initWithCoder:(NSCoder *)aDecoder;

- (void) reset;
- (void) renderParticles;
- (void) updateWithDelta:(GLfloat) aDelta;
- (void) setSourcePosition:(CGPoint) position;
- (void) stopParticleEmitter;
- (void) setResolution:(CGSize) size;

@end

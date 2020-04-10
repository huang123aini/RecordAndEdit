//
//  HAVParticle.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>

@interface HAVParticle : NSObject <NSCoding>

@property (nonatomic, assign) GLKVector2 position;
@property (nonatomic, assign) GLKVector2 direction;
@property (nonatomic, assign) GLKVector2 originPosition;
@property (nonatomic, assign) GLKVector2 originDirection;
@property (nonatomic, assign) GLKVector2 startPos;
@property (nonatomic, assign) GLKVector4 color;
@property (nonatomic, assign) GLKVector4 deltaColor;
@property (nonatomic, assign) GLfloat rotation;
@property (nonatomic, assign) GLfloat rotationDelta;
@property (nonatomic, assign) GLfloat radialAcceleration;
@property (nonatomic, assign) GLfloat tangentialAcceleration;
@property (nonatomic, assign) GLfloat radius;
@property (nonatomic, assign) GLfloat radiusDelta;
@property (nonatomic, assign) GLfloat angle;
@property (nonatomic, assign) GLfloat degreesPerSecond;
@property (nonatomic, assign) GLfloat particleSize;
@property (nonatomic, assign) GLfloat particleSizeDelta;
@property (nonatomic, assign) GLfloat timeToLive;
@property (nonatomic, assign) GLfloat createTime;
@property (nonatomic, assign) GLfloat lastUpdateTime;

- (instancetype) init;
- (instancetype) initWithCoder:(NSCoder *)aDecoder;

- (HAVParticle *) currentParticle:(GLfloat) time emitterType:(int) emitterType yCoordFlipped:(int) yCoordFlipped gravity:(GLKVector2) gravity;

@end

//
//  HAVParticleSystem.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVParticleSystem.h"
#import "HAVParticleEmitter.h"

@interface HAVParticlePosition: NSObject <NSCoding>

@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGFloat startTime;
@property (nonatomic, assign) CGFloat endTime;

- (instancetype) init;
- (instancetype) initWithCoder:(NSCoder *)aDecoder;

- (BOOL) positionAtTime:(CGFloat) time;

@end

@implementation HAVParticlePosition

- (instancetype) init{
    self = [super init];
    if(self){
        self.startTime = 0.0f;
        self.endTime = 0.0f;
    }
    return self;
}
- (instancetype) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self){
        self.startTime = [aDecoder decodeFloatForKey:@"startTime"];
        self.endTime = [aDecoder decodeFloatForKey:@"endTime"];
        self.position = [aDecoder decodeCGPointForKey:@"position"];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeFloat:self.startTime forKey:@"startTime"];
    [aCoder encodeFloat:self.endTime forKey:@"endTime"];
    [aCoder encodeCGPoint:self.position forKey:@"position"];
}

- (BOOL) positionAtTime:(CGFloat) time{
    if(((time > self.startTime) || (self.startTime <= 0.0f)) && (time < self.endTime)){
        return YES;
    }
    return NO;
}

@end

@interface HAVParticleSystem()

@property (nonatomic, assign) BOOL isRender;
@property (nonatomic, assign) GLfloat lastUpdateTime;
@property (nonatomic, strong) HAVParticleEmitter *particleEmitter;
@property (nonatomic, strong) NSMutableArray *positions;

- (BOOL) showAtTime:(CGFloat) time;

@end

@implementation HAVParticleSystem
- (instancetype) initWithConfigFile:(NSString *) configFile{
    self = [super init];
    if(self){
        self.startTime = 0.0f;
        self.endTime = 0.0f;
        self.lastUpdateTime = 0.0f;
        self.isRender = NO;
        self.particleEmitter = [[HAVParticleEmitter alloc] initParticleEmitterWithFile:configFile];
        self.positions = [NSMutableArray array];
    }
    return self;
}

- (void) setSourcePosition:(CGPoint) position{
    self.particleEmitter.sourcePosition = GLKVector2Make(position.x, position.y);
    HAVParticlePosition *particlePoistion = [self.positions lastObject];
    if((particlePoistion != nil) && ([particlePoistion isKindOfClass:[HAVParticlePosition class]])){
        particlePoistion.endTime = self.lastUpdateTime;
    }
    particlePoistion = [[HAVParticlePosition alloc] init];
    particlePoistion.position = position;
    particlePoistion.startTime = self.lastUpdateTime;
    [self.positions addObject:particlePoistion];
    
}

- (void) reset{
    [self.particleEmitter reset];
}

- (void) setResolution:(CGSize) size{
    [self.particleEmitter setResolution:size];
}

- (void) renderParticles{
    if(self.isRender){
        [self.particleEmitter usePrograma];
        [self.particleEmitter renderParticles];
        self.isRender = NO;
    }
}

- (BOOL) showAtTime:(CGFloat) time{
    if(((time > self.startTime) || (self.startTime <= 0.0f)) && ((time < self.endTime) || (self.endTime <= 0.0f))){
        return YES;
    }
    return NO;
}

- (CGPoint) postionWithTime:(CGFloat) time{
    for (HAVParticlePosition *position in self.positions){
        if([position positionAtTime:time]){
            return position.position;
        }
    }
    return CGPointZero;
}

- (void) updateWithDelta:(GLfloat) currentTime{
    self.isRender = [self showAtTime:currentTime];
    if(self.isRender){
        if(self.startTime <= 0.0f){
            self.startTime = currentTime;
        }
        GLfloat aDelta = currentTime;
        CGPoint position = [self postionWithTime:currentTime];
        if(!CGPointEqualToPoint(position, CGPointZero)){
            self.particleEmitter.sourcePosition = GLKVector2Make(position.x, position.y);
        }
        
        [self.particleEmitter updateWithDelta:aDelta];
        self.lastUpdateTime = currentTime;
    }
}

- (void) stopParticleEmitter{
    [self.particleEmitter stopParticleEmitter];
    self.endTime = self.lastUpdateTime + [self.particleEmitter particleMaxLiveTime];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self){
        self.startTime = [aDecoder decodeFloatForKey:@"startTime"];
        self.endTime = [aDecoder decodeFloatForKey:@"endTime"];
        self.lastUpdateTime = [aDecoder decodeFloatForKey:@"lastUpdateTime"];
        self.particleEmitter = [aDecoder decodeObjectForKey:@"particleEmitter"];
        self.positions = [aDecoder decodeObjectForKey:@"positions"];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeFloat:self.startTime forKey:@"startTime"];
    [aCoder encodeFloat:self.endTime forKey:@"endTime"];
    [aCoder encodeFloat:self.lastUpdateTime forKey:@"lastUpdateTime"];
    [aCoder encodeObject:self.particleEmitter forKey:@"particleEmitter"];
    [aCoder encodeObject:self.positions forKey:@"positions"];
}

@end


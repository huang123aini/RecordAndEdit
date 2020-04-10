//
//  HAVParticle.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVParticle.h"
#import "HAVParticleEmitter.h"
static const GLKVector2 GLKVector2Zero = {0.0f, 0.0f};

@implementation HAVParticle

- (instancetype) init{
    self = [super init];
    if(self){
        self.position = GLKVector2Make(0.0f, 0.0f);
        self.direction = GLKVector2Make(0.0f, 0.0f);
        self.startPos = GLKVector2Make(0.0f, 0.0f);
        self.color = GLKVector4Make(0.0f, 0.0f, 0.0f, 0.0f);
        self.deltaColor = GLKVector4Make(0.0f, 0.0f, 0.0f, 0.0f);
        self.rotation = 0.0f;
        self.rotationDelta = 0.0f;
        self.radialAcceleration = 0.0f;
        self.tangentialAcceleration = 0.0f;
        self.radius = 0.0f;
        self.radiusDelta = 0.0f;
        self.angle = 0.0f;
        self.degreesPerSecond = 0.0f;
        self.particleSize = 0.0f;
        self.particleSizeDelta = 0.0f;
        self.timeToLive = 0.0f;
        self.createTime = 0.0f;
        self.originPosition = GLKVector2Make(0.0f, 0.0f);
        self.originDirection = GLKVector2Make(0.0f, 0.0f);
    }
    return self;
}

- (instancetype) initWithParicle:(HAVParticle *) particle{
    self = [super init];
    if(self){
        self.position = particle.position;
        self.direction = particle.direction;
        self.startPos = particle.startPos;
        self.color = particle.color;
        self.deltaColor = particle.deltaColor;
        self.rotation = particle.rotation;
        self.rotationDelta = particle.rotationDelta;
        self.radialAcceleration = particle.radialAcceleration;
        self.tangentialAcceleration = particle.tangentialAcceleration;
        self.radius = particle.radius;
        self.radiusDelta = particle.radiusDelta;
        self.angle = particle.angle;
        self.degreesPerSecond = particle.degreesPerSecond;
        self.particleSize = particle.particleSize;
        self.particleSizeDelta = particle.particleSizeDelta;
        self.timeToLive = particle.timeToLive;
        self.createTime = particle.createTime;
        self.originDirection = particle.originDirection;
        self.originPosition = particle.originPosition;
    }
    return self;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeFloat:self.startPos.x forKey:@"startPosx"];
    [aCoder encodeFloat:self.startPos.y forKey:@"startPosy"];
    [aCoder encodeFloat:self.createTime forKey:@"createTime"];
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self != nil){
        GLKVector2 startPos = {0, 0};
        startPos.x = [aDecoder decodeFloatForKey:@"startPosx"];
        startPos.y = [aDecoder decodeFloatForKey:@"startPosy"];
        self.startPos = startPos;
        self.createTime = [aDecoder decodeFloatForKey:@"createTime"];
        self.lastUpdateTime = self.createTime;
        
    }
    return self;
    
}

- (HAVParticle *) currentParticle:(GLfloat) time emitterType:(int) emitterType  yCoordFlipped:(int) yCoordFlipped gravity:(GLKVector2) gravity{
    if(time >= self.createTime && time <= self.createTime + self.timeToLive){
        GLfloat aDelta = time - self.createTime;
        HAVParticle * currentParticle = [[HAVParticle alloc] initWithParicle:self];
        if (emitterType == kParticleTypeRadial) {
            currentParticle.angle = self.angle + self.degreesPerSecond * aDelta;
            currentParticle.radius = self.radius + self.radiusDelta * aDelta;
            
            GLKVector2 tmp;
            tmp.x = self.startPos.x - cosf(currentParticle.angle) * currentParticle.radius * -yCoordFlipped;
            tmp.y = self.startPos.y - sinf(currentParticle.angle) * currentParticle.radius ;
            currentParticle.position = tmp;
            
        } else {
            GLfloat start = self.lastUpdateTime;
            if(time < self.lastUpdateTime){
                self.position = self.originPosition;
                self.direction = self.originDirection;
                currentParticle.position = self.originPosition;
                currentParticle.direction = self.originDirection;
                start = self.createTime;
            }
            GLfloat fact = 1.5 / 30.0f;
            while(time - start > 0.0f){
                if(time - start > fact){
                    aDelta = 1.0 / 30.0f;
                    start += aDelta;
                }else{
                    aDelta = (time - start);
                    start = time;
                }
                GLKVector2 tmp, radial, tangential;
                
                radial = GLKVector2Zero;
                
                // By default this emitters particles are moved relative to the emitter node position
                GLKVector2 positionDifference = GLKVector2Subtract(self.startPos, GLKVector2Zero);
                currentParticle.position = GLKVector2Subtract(currentParticle.position, positionDifference);
                
                if (currentParticle.position.x || currentParticle.position.y){
                    radial = GLKVector2Normalize(currentParticle.position);
                }
                
                tangential = radial;
                radial = GLKVector2MultiplyScalar(radial, self.radialAcceleration);
                
                GLfloat newy = tangential.x;
                tangential.x = -tangential.y;
                tangential.y = newy;
                tangential = GLKVector2MultiplyScalar(tangential, self.tangentialAcceleration);
                
                tmp = GLKVector2Add(GLKVector2Add(radial, tangential), gravity);
                tmp = GLKVector2MultiplyScalar(tmp, aDelta);
                currentParticle.direction = GLKVector2Add(currentParticle.direction, tmp);
                tmp = GLKVector2MultiplyScalar(currentParticle.direction, aDelta);
                tmp.x *= yCoordFlipped;
                tmp.y *= yCoordFlipped;
                currentParticle.position = GLKVector2Add(currentParticle.position, tmp);
                currentParticle.position = GLKVector2Add(currentParticle.position, positionDifference);
                
            }
        }
        aDelta =  time - self.createTime;
        
        // Update the particles color
        GLKVector4 color ;
        color.r = self.color.r + self.deltaColor.r * aDelta;
        color.g = self.color.g + self.deltaColor.g * aDelta;
        color.b = self.color.b + self.deltaColor.b * aDelta;
        color.a = self.color.a + self.deltaColor.a * aDelta;
        currentParticle.color = color;
        
        // Update the particle size
        currentParticle.particleSize =  self.particleSize + currentParticle.particleSizeDelta * aDelta;
        currentParticle.particleSize = MAX(0, currentParticle.particleSize);
        
        // Update the rotation of the particle
        currentParticle.rotation = self.rotation + self.rotationDelta * aDelta;
        self.lastUpdateTime = time;
        
        self.position =  currentParticle.position;
        self.direction = currentParticle.direction;
        return currentParticle;
    }
    return nil;
}
@end

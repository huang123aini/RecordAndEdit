//
//  HAVParticleFilter.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVParticleFilter.h"
#import "HAVParticleEmitter.h"
#import "HAVParticleSystem.h"

@interface HAVParticleFilter()

@property (nonatomic, assign) CGFloat lastUpdateTime;
@property (nonatomic, strong) NSMutableArray *particlesSystems;
@property (nonatomic, assign) CGSize resolution;

@end

@implementation HAVParticleFilter

- (instancetype) init{
    self = [super init];
    if(self){
        self.particlesSystems = [NSMutableArray array];
        self.lastUpdateTime = 0.0f;
        self.resolution = CGSizeZero;
    }
    return self;
}

- (void) changeSourcePosition:(CGPoint) position{
    runAsynchronouslyOnVideoProcessingQueue(^{
        NSArray *array = [self.particlesSystems lastObject];
        for (HAVParticleSystem *particleSystem in array){
            if(particleSystem != nil){
                [particleSystem setSourcePosition:position];
            }
        }
        
    });
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    if(CGSizeEqualToSize(self.resolution, CGSizeZero)){
        self.resolution = firstInputFramebuffer.size;
        for (NSArray *particles in self.particlesSystems){
            for (HAVParticleSystem *particleSystem in particles){
                [particleSystem setResolution:self.resolution];
            }
        }
    }
    [GPUImageContext setActiveShaderProgram:filterProgram];
    
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
 
    [firstInputFramebuffer unlock];
    for (NSArray *particles in self.particlesSystems){
        for (HAVParticleSystem *particleSystem in particles){
            [particleSystem renderParticles];
        }
    }

    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        for (NSArray *particles in self.particlesSystems){
            for (HAVParticleSystem *particleSystem in particles){
                self.lastUpdateTime = CMTimeGetSeconds(frameTime);
                [particleSystem updateWithDelta:self.lastUpdateTime];
            }
        }
    });
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
}

- (void) back{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [self.particlesSystems removeLastObject];
    });
}

- (void) stop{
    NSArray *particles = [self.particlesSystems lastObject];
    for (HAVParticleSystem *particleSystem in particles){
        if((particleSystem != nil) && ([particleSystem isKindOfClass:[particleSystem class]])){
            runAsynchronouslyOnVideoProcessingQueue(^{
                [particleSystem stopParticleEmitter];
            });
        }
    }
}

- (void) addParticle:(NSString *) file atPosition:(CGPoint) point{
    HAVParticleSystem *particleSystem = [[HAVParticleSystem alloc] initWithConfigFile:file];
    [particleSystem setSourcePosition:point];
    [particleSystem reset];
    runAsynchronouslyOnVideoProcessingQueue(^{
        NSArray *array = @[particleSystem];
        [self.particlesSystems addObject:array];
    });
  
}

- (void) addParticles:(NSArray *) files atPosition:(CGPoint) point{

    NSMutableArray *array = [NSMutableArray array];
    
    for (NSString *file in files){
        HAVParticleSystem *particleSystem = [[HAVParticleSystem alloc] initWithConfigFile:file];
        [particleSystem setSourcePosition:point];
        [particleSystem reset];
        [array addObject:particleSystem];
    }

    if(array.count > 0){
        runAsynchronouslyOnVideoProcessingQueue(^{
            [self.particlesSystems addObject:array];
        });
    }

}

- (NSArray *) archiver{
    NSMutableArray *array = [NSMutableArray array];
    for (NSArray *particles in self.particlesSystems){
        NSMutableArray *particlesArray = [NSMutableArray array];
        for (HAVParticleSystem *particleSystem in particles){
            NSData  *data = [NSKeyedArchiver archivedDataWithRootObject:particleSystem];
            [particlesArray addObject:data];
        }
        [array addObject:particlesArray];
    }
    return array;
}

- (void) removeAllMagic{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [self.particlesSystems removeAllObjects];
    });
}

- (void) unarchiver:(NSArray *) array{
    NSMutableArray *particlesSystem = [NSMutableArray array];
    for (NSArray *particles in array){
        NSMutableArray *particlesGroup = [NSMutableArray array];
        for (NSData *data in particles){
            HAVParticleSystem *particleSystem = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [particlesGroup addObject:particleSystem];
        }
        if(particlesGroup.count > 0){
            [particlesSystem addObject:particlesGroup];
        }
    }
    runAsynchronouslyOnVideoProcessingQueue(^{
        self.particlesSystems = particlesSystem;
    });
}

- (void) reset{
    isEndProcessing = NO;
}

@end

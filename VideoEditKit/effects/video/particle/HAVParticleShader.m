//
//  HAVParticleShader.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVParticleShader.h"
#import <GPUKit/GPUKit.h>

extern NSString *const kGPUImageParticalFragmentShaderString;
extern NSString *const kGPUImageParticalVertexShaderString;

static HAVParticleShader *mInstance = nil;

@interface HAVParticleShader()

@property(nonatomic ,strong) GLProgram *particleShader;

@end

@implementation HAVParticleShader

+ (HAVParticleShader *) sharedInstance{
    if(mInstance == nil){
        mInstance = [[HAVParticleShader alloc] init];
    }
    return mInstance;
}

- (void)setupShaders
{
        // Compile the shaders we are using...
    self.particleShader = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageParticalVertexShaderString fragmentShaderString:kGPUImageParticalFragmentShaderString];
    // ... and add the attributes the shader needs for the vertex position, color and texture st information'
    
    [self.particleShader addAttribute:@"inPosition"];
    [self.particleShader addAttribute:@"inColor"];
    [self.particleShader addAttribute:@"inTexCoord"];
    
    // Check to make sure everything lnked OK
    if (![self.particleShader link]) {
        self.particleShader = nil;
        exit(1);
    }
    // Setup the index pointers into the shader for our attributes
    self.inPositionAttrib = [self.particleShader attributeIndex:@"inPosition"];
    self.inColorAttrib = [self.particleShader attributeIndex:@"inColor"];
    self.inTexCoordAttrib = [self.particleShader attributeIndex:@"inTexCoord"];
    self.textureUniform = [self.particleShader uniformIndex:@"inputImageTexture"];
    self.u_opacityModifyRGB = [self.particleShader uniformIndex:@"u_opacityModifyRGB"];
    self.mvpMatrixUniform = [self.particleShader uniformIndex:@"mVPMatrix"];

    
}

- (instancetype) init{
    self = [super init];
    if (self) {
        [self setupShaders];
    }
    return self;
}

- (void) setActiveShaderProgram{
    [GPUImageContext setActiveShaderProgram:self.particleShader];
}

-(void)dealloc{
    
}
@end

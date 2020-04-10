//
//  HAVParticleShader.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HAVParticleShader : NSObject
@property (nonatomic, assign) GLuint inPositionAttrib;
@property (nonatomic, assign) GLuint inColorAttrib;
@property (nonatomic, assign) GLuint inTexCoordAttrib;
@property (nonatomic, assign) GLuint textureUniform;
@property (nonatomic, assign) GLuint mvpMatrixUniform;
@property (nonatomic, assign) GLuint u_opacityModifyRGB;

+ (HAVParticleShader *) sharedInstance;

- (void) setActiveShaderProgram;

@end


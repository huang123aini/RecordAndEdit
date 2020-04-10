//
//  HAVVideoEffect.h
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface HAVVideoEffect : NSObject <NSCoding>

@property (nonatomic, assign) int videoEffectId;
@property (nonatomic, assign) Float64 startFrameTime;
@property (nonatomic, assign) Float64 endFrameTime;
@property (nonatomic, strong) GLProgram *program;
@property (nonatomic, assign) float timeInterval;
@property (nonatomic, assign) GLuint mGlobalTime;
@property (nonatomic, assign) GLuint iResolution;

@property (nonatomic, assign) GLuint filterPositionAttribute;
@property (nonatomic, assign) GLuint filterTextureCoordinateAttribute;
@property (nonatomic, assign) GLuint filterInputTextureUniform;
@property (nonatomic, assign) GLuint filterInputTextureUniform2;
@property (nonatomic, assign) GLuint uHasSoulTexture;

@property (nonatomic, assign) BOOL reversed;

- (instancetype) init;

- (instancetype) initWithCoder:(NSCoder *)aDecoder;

@end

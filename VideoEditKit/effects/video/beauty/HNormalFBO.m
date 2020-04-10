//
//  HNormalFBO.m
//  HAVKit
//
//  Created by 黄世平 on 2019/1/20.
//  Copyright © 2019 黄世平. All rights reserved.
//

#import "HNormalFBO.h"

@implementation HNormalFBO

-(instancetype)initWithSize:(CGSize)size
{
    if (self = [super init])
    {
        [self createFBOTexture:size];
        self.fboSize = size;
        
    }
    return self;
}
-(void)createFBOTexture:(CGSize)size
{
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    GLuint fboTexture;
    glGenTextures(1, &fboTexture);
    glBindTexture(GL_TEXTURE_2D, fboTexture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)size.width, (int)size.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fboTexture, 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    self.fboTexture = fboTexture;
    self.fbo = framebuffer;
    
}

-(void)bindFBO
{
    glBindFramebuffer(GL_FRAMEBUFFER, self.fbo);
    glViewport(0, 0, self.fboSize.width, self.fboSize.height);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
}

-(void)unbindFBO
{
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

-(void)dealloc
{
    if (self.fbo)
    {
        glDeleteFramebuffers(1, &_fbo);
        self.fbo = 0;
    }
    if (self.fboTexture)
    {
        glDeleteTextures(1, &_fboTexture);
        self.fboTexture = 0;
    }
}

@end

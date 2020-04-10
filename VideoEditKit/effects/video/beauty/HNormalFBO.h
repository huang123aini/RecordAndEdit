//
//  HNormalFBO.h
//  HAVKit
//
//  Created by 黄世平 on 2019/1/20.
//  Copyright © 2019 黄世平. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNormalFBO : NSObject

@property(nonatomic,assign)GLuint fbo;
@property(nonatomic,assign)GLuint fboTexture;
@property(nonatomic,assign)CGSize fboSize;
-(instancetype)initWithSize:(CGSize)size;

-(void)bindFBO;
-(void)unbindFBO;

@end

NS_ASSUME_NONNULL_END

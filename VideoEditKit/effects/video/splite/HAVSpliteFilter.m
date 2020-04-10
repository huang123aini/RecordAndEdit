//
//  HAVSpliteFilter.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVSpliteFilter.h"
#import "HAVMovieFileReader.h"

NSString *const kGPUImage22PassthroughFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform int isLeft;
 uniform int hasVoidFrame;
 
 void main()
 {
     if(isLeft == 1)
     {
         
         if(hasVoidFrame == 1)
         {
             gl_FragColor = mix(texture2D(inputImageTexture, textureCoordinate),texture2D(inputImageTexture2, textureCoordinate),0.3);
         }else
         {
             gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
         }
         
     }else if(isLeft == 0)
     {
         gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
     }
     
 }
 );



@interface HAVSpliteFilter ()
{
    GLuint textureId;
    GLuint backGroundTextureId;
    
    BOOL isFirstFrameLeft;
    BOOL isFirstFrameRight;
    
    CMTime lastTime;
    
    GLProgram *spliteProgram;
    GPUImageFramebuffer* lastEffectiveFBO;
    GLint isLeft;
    GLint splitePositionAttribute, spliteTextureCoordinateAttribute;
    GLint spliteInputTextureUniform;
    GLint voidInputTextureUniform;
    GLint hasVoidFrame;
    
    
    BOOL    setVoidFrameParmsOnce;
    GLuint  leftGhostTexture;
    
    BOOL isVoidFrameOpen;
    
}

@property (nonatomic , strong) id<HAVDataSourceDelegate> dataSource;

@end

@implementation HAVSpliteFilter

- (GLuint)createTextureWithImage:(UIImage *)image
{
    CGImageRef spriteImage = image.CGImage;
    GLuint width = (GLuint)CGImageGetWidth(spriteImage);
    GLuint height = (GLuint)CGImageGetHeight(spriteImage);
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    CGContextRelease(spriteContext);
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    free(spriteData);
    return texName;
}

- (instancetype) initWithDataSource:(id<HAVDataSourceDelegate>) dataSource
{
    self = [super init];
    if(self)
    {
        self.dataSource = dataSource;
        self.displayModel = HAVSpliteScreen;
        
        textureId = 0;
        backGroundTextureId = 0;
        leftGhostTexture = 0;
        
        setVoidFrameParmsOnce = NO;
        isVoidFrameOpen = NO;
        
        lastEffectiveFBO = nil;
        
        isFirstFrameLeft = NO;
        isFirstFrameRight = NO;
        self.preview = NO;
    }
    return self;
}

-(void)addBackground:(UIImage*)image
{
    backGroundTextureId = [self createTextureWithImage:image];
}


- (GLuint)createTextureWithImage:(UIImage *)image textureId :(GLuint) inputTextureId
{
    
    CGImageRef spriteImage = image.CGImage;
    GLuint width = (GLuint)CGImageGetWidth(spriteImage);
    GLuint height = (GLuint)CGImageGetHeight(spriteImage);
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    CGContextRelease(spriteContext);
    GLuint texName = inputTextureId;
    if(texName == 0)
    {
        glGenTextures(1, &texName);
    }
    
    glBindTexture(GL_TEXTURE_2D, texName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    free(spriteData);
    return texName;
    
}

-(UIImage*)getBattleGhostImage
{
    if(lastEffectiveFBO != nil)
    {
        CGImageRef image = [lastEffectiveFBO newCGImageFromFramebufferContents];
        UIImage *ghostImage = [UIImage imageWithCGImage:image];
        CFRelease(image);
        return ghostImage;
    }
    return nil;
}
-(void)setGhostImage:(UIImage*)image
{
    leftGhostTexture = [self createTextureWithImage:image textureId:leftGhostTexture];
}

-(void)openGhost
{
    isVoidFrameOpen = YES;
}
-(void)shutDownGhost
{
    isVoidFrameOpen = NO;
}

- (void) copyMovieTexture:(CVPixelBufferRef) sampleBuffer
{
    if(sampleBuffer != NULL)
    {
        int bufferHeight = (int) CVPixelBufferGetHeight(sampleBuffer);
        CVPixelBufferLockBaseAddress(sampleBuffer, 0);
        int bytesPerRow = (int) CVPixelBufferGetBytesPerRow(sampleBuffer);
        if(textureId == 0)
        {
            glGenTextures(1, &textureId);
            glBindTexture(GL_TEXTURE_2D, textureId);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(sampleBuffer));
            CVPixelBufferUnlockBaseAddress(sampleBuffer, 0);
        }else
        {
            glBindTexture(GL_TEXTURE_2D, textureId);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(sampleBuffer));
            CVPixelBufferUnlockBaseAddress(sampleBuffer, 0);
        }
        CFRelease(sampleBuffer);
    }
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
    CVPixelBufferRef pixelBuffer = [self.dataSource copyFrameAtTime:frameTime];
    if(pixelBuffer != NULL)
    {
        [self copyMovieTexture:pixelBuffer];
    }
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    if (firstInputFramebuffer != nil)
    {
        lastEffectiveFBO = firstInputFramebuffer;
    }
    
    
    //添加虚帧的操作
    if (!setVoidFrameParmsOnce)
    {
        spliteProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImage22PassthroughFragmentShaderString];
        
        if (!spliteProgram.initialized)
        {
            [spliteProgram addAttribute:@"position"];
            [spliteProgram addAttribute:@"inputTextureCoordinate"];
            
            if (![spliteProgram link])
            {
                NSString *progLog = [spliteProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [spliteProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [spliteProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                spliteProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        splitePositionAttribute = [spliteProgram attributeIndex:@"position"];
        spliteTextureCoordinateAttribute = [spliteProgram attributeIndex:@"inputTextureCoordinate"];
        spliteInputTextureUniform = [spliteProgram uniformIndex:@"inputImageTexture"];
        voidInputTextureUniform = [spliteProgram uniformIndex:@"inputImageTexture2"];
        isLeft = [spliteProgram uniformIndex:@"isLeft"];
        
        hasVoidFrame = [spliteProgram uniformIndex:@"hasVoidFrame"];
        
        [GPUImageContext setActiveShaderProgram:spliteProgram];
        glEnableVertexAttribArray(splitePositionAttribute);
        glEnableVertexAttribArray(spliteTextureCoordinateAttribute);
        
        setVoidFrameParmsOnce = YES;
    }
    
    //使用 spliteProgram
    [GPUImageContext setActiveShaderProgram:spliteProgram];
    
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:0];
    
    
    if (backGroundTextureId == 0)
    {
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    }
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    //背景
    {
        if (backGroundTextureId != 0)
        {
            
            glActiveTexture(GL_TEXTURE4);
            glBindTexture(GL_TEXTURE_2D, backGroundTextureId);
            glUniform1i(spliteInputTextureUniform, 4);
            
            
            GLfloat vertices [] =
            {
                -1.0f,-1.0f,
                1.0f,-1.0f,
                -1.0f,1.0f,
                1.0f,1.0f
            };
            
            glVertexAttribPointer(splitePositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
        }
    }
    
    //左边虚帧
    {
        if (leftGhostTexture != 0 && isVoidFrameOpen)
        {
            
            glActiveTexture(GL_TEXTURE4);
            glBindTexture(GL_TEXTURE_2D, leftGhostTexture);
            glUniform1i(voidInputTextureUniform, 4);
            GLfloat vertices [] =
            {
                -1.0f,-0.5f,
                0.007f,-0.5f,
                -1.0f,0.5f,
                0.007f,0.5f
            };
            
            glUniform1i(hasVoidFrame, 1);
            
            glVertexAttribPointer(splitePositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        }else
        {
            glUniform1i(hasVoidFrame, 0);
        }
    }
    
    
    //左
    {
        if ([firstInputFramebuffer texture] != 0)
        {
            
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D,[firstInputFramebuffer texture]);
            glUniform1i(spliteInputTextureUniform, 2);
            
            glUniform1i(isLeft, 1);
            
            if(self.displayModel == HAVSpliteScreen)
            {
                
                float ratio = [self.dataSource getRatio];
                float ratio1 = ratio  * [[self framebufferForOutput] size].width / [[self framebufferForOutput] size].height;
                
                float y1 = -0.5f * ratio1;
                float y2 =  0.5f * ratio1;
                
                if (self.preview)
                {
                    //预览页
                    GLfloat vertices2 [] =
                    {
                        -1.0f,y1,
                        0.007f,y1,
                        -1.0f,y2,
                        0.007f,y2
                    };
                    
                    GLfloat vertices22[] =
                    {
                        -1.0f,-0.5f,
                        0.007f,-0.5f,
                        -1.0f,0.5f,
                        0.007f,0.5f
                    };
                    
                    if (ratio != 0)
                    {
                        glVertexAttribPointer(splitePositionAttribute, 2, GL_FLOAT, 0, 0, vertices2);
                        
                    }else
                    {
                        glVertexAttribPointer(splitePositionAttribute, 2, GL_FLOAT, 0, 0, vertices22);
                    }
                    
                }else{
                    
                    //录制页
                    GLfloat vertices23[] =
                    {
                        -1.0f,-0.5f,
                        0.0f,-0.5f,
                        -1.0f,0.5f,
                        0.0f,0.5f
                    };
                    
                    glVertexAttribPointer(splitePositionAttribute, 2, GL_FLOAT, 0, 0, vertices23);
                }
                
            }else if(self.displayModel == HAVFullScreen)
            {
                glVertexAttribPointer(splitePositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
            }
            
            glVertexAttribPointer(spliteTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
            
            
            // glEnable(GL_DEPTH_TEST);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            //glDisable(GL_DEPTH_TEST);
        }
    }
    
    //右
    {
        if(self.displayModel == HAVSpliteScreen)
        {
            //            NSLog(@"xxxxxxx田老师:%d textureId:%d", self.preview, textureId);
            glActiveTexture(GL_TEXTURE3);
            glBindTexture(GL_TEXTURE_2D, self.preview ?[firstInputFramebuffer texture] :textureId);
            glUniform1i(spliteInputTextureUniform, 3);
            
            glUniform1i(isLeft, 0);
            
            GLfloat vertices3 [] =
            {
                0.0f, -0.5f,
                1.0f, -0.5f,
                0.0f, 0.5f,
                1.0f, 0.5f
            };
            
            
            float ratio = [self.dataSource getRatio] *  [[self framebufferForOutput] size].width / [[self framebufferForOutput] size].height;
            
            float y1 = -0.5f * ratio;
            float y2 =  0.5f * ratio;
            
            GLfloat vertices4[] =
            {
                0.0f, y1,
                1.0f, y1,
                0.0f, y2,
                1.0f, y2
            };
            
            
            if (ratio == 0 || self.preview)
            {
                glVertexAttribPointer(splitePositionAttribute, 2, GL_FLOAT, 0, 0, vertices3);
                
            }else
            {
                glVertexAttribPointer(splitePositionAttribute, 2, GL_FLOAT, 0, 0, vertices4);
            }
            
            
            //针对纹理旋转
            if(self.dataSource != nil)
            {
                glVertexAttribPointer(spliteTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [[self class] textureCoordinatesForRotation:[self.dataSource rotation]]);
            }
            
            //混合解决白边
            glBlendEquation(GL_FUNC_ADD);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_BLEND);
            
            //glEnable(GL_DEPTH_TEST);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            //glDisable(GL_DEPTH_TEST);
            glDisable(GL_BLEND);
        }
    }
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}


-(void) dealloc
{
    if(textureId != 0)
    {
        glDeleteTextures(1, &textureId);
        textureId = 0;
    }
    
    if(backGroundTextureId != 0)
    {
        glDeleteTextures(1, &backGroundTextureId);
    }
    
    if (leftGhostTexture != 0)
    {
        glDeleteTextures(1, &leftGhostTexture);
    }
    
    
    if (lastEffectiveFBO != nil)
    {
        [lastEffectiveFBO unlock];
        lastEffectiveFBO = nil;
    }
}

- (void) reset
{
    if ([self.dataSource isKindOfClass:[HAVMovieFileReader class]])
    {
        HAVMovieFileReader *fileReader = (HAVMovieFileReader *)self.dataSource;
        [fileReader seekToTime:0.0];
        [fileReader setHasExport:YES];
    }
    isEndProcessing = NO;
    
}

- (void)endProcessing
{
    [super endProcessing];
    isEndProcessing = NO;
}

@end

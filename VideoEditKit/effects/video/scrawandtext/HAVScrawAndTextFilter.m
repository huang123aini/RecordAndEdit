//
//  HAVScrawAndTextFilter.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVScrawAndTextFilter.h"

#import <UIKit/UIKit.h>

#define KISIphoneX (CGSizeEqualToSize(CGSizeMake(375.f, 812.f), [UIScreen mainScreen].bounds.size) || CGSizeEqualToSize(CGSizeMake(812.f, 375.f), [UIScreen mainScreen].bounds.size))

@interface HAVScrawlAndTextFilter ()
{
    GLuint updatedTextureId;
    BOOL initilized;
    BOOL localSave;
    GPUImageFramebuffer *tempFrameBuffer;
    CVPixelBufferRef newPixelBuffer;
}
@property (atomic, assign) BOOL needUpdate;
@end

@implementation HAVScrawlAndTextFilter
- (id)init
{
    self = [super init];
    if (self)
    {
        
        [self initDefault];
    }
    return self;
}

-(void)toReset
{
    @synchronized(self)
    {
        
        isEndProcessing = NO;
        self.needUpdate = NO;
        localSave = NO;
        if (_updatedImage)
        {
            _updatedImage = nil;
        }
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageContext useImageProcessingContext];
            if (self->updatedTextureId)
            {
                glDeleteTextures(1, &self->updatedTextureId);
                self->updatedTextureId = 0;
            }
        });
    }
}

- (void)initDefault
{
    self.needUpdate = NO;
    localSave = NO;
    [self createTextureID];
    
    glBindTexture(GL_TEXTURE_2D, 0); //解绑
    newPixelBuffer = nil;
}

-(void)createTextureID
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        glEnable(GL_TEXTURE_2D);
        glGenTextures(1, &self->updatedTextureId);
        glBindTexture(GL_TEXTURE_2D, self->updatedTextureId);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    });
}

- (void)setUpdatedImage:(UIImage *)updatedImage
{
    initilized = YES;
    _updatedImage = updatedImage;
    
    if (!updatedTextureId)
    {
        [self createTextureID];
    }
    self.needUpdate = YES;
}

- (void)setRotationMode:(GPUImageRotationMode)rotationMode{
    _rotationMode = rotationMode;
    localSave = YES;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    static const GLfloat imageVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    if (localSave) {
        [self renderToTextureWithRotate:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];
    }
    else {
        [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];
    }
    //    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];
    
    [self informTargetsAboutNewFrameAtTime:frameTime];
}

- (void)renderToTextureWithRotate:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    
    GPUImageRotationMode srcRotate = kGPUImageNoRotation;
    
    if (self.rotationMode == kGPUImageRotateRight)
    {
        srcRotate = kGPUImageRotateLeft;
        
    }
    else if (self.rotationMode == kGPUImageRotateLeft)
    {
        srcRotate = kGPUImageRotateRight;
    }
    
    const GLfloat* texCoords = [GPUImageFilter textureCoordinatesForRotation:srcRotate];
    
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates];
    if (!initilized)
    {
        return ;
    }
    
    if (updatedTextureId == 0)
    {
        return;
    }
    
    if (self.needUpdate)
    {
        [self setupTexture:self.updatedImage];
        self.needUpdate = NO;
    }
    
    [self setUniformsForProgramAtIndex:0];
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, updatedTextureId);
    glUniform1i(filterInputTextureUniform, 5);
    
    float xScale = 1.;
    if (KISIphoneX)
    {
        xScale = 1334. / 1468.;
    }
    const GLfloat imageVertices[] =
    {
        -xScale, -1.0f,
        xScale, -1.0f,
        -xScale,  1.0f,
        xScale,  1.0f,
    };
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, texCoords);
    
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisable(GL_BLEND);
    return;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates];
    if (!initilized)
    {
        return ;
    }
    if (updatedTextureId == 0)
    {
        return;
    }
    if (self.needUpdate)
    {
        [self setupTexture:self.updatedImage];
        self.needUpdate = NO;
    }
    
    [self setUniformsForProgramAtIndex:0];
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, updatedTextureId);
    glUniform1i(filterInputTextureUniform, 5);
    static const GLfloat imageVertices[] =
    {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisable(GL_BLEND);
    
    glFlush();
    
    return;
}

- (void)setupTexture:(UIImage *)image
{
    
    if (!image)
    {
        return ;
    }
    
    CGImageRef cgImageRef = [image CGImage];
    
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);
    
    glBindTexture(GL_TEXTURE_2D, updatedTextureId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    CGContextRelease(context);
    free(imageData);
    
}
-(void)dealloc
{
    if(newPixelBuffer != nil)
    {
        CFRelease(newPixelBuffer);
    }
    if (updatedTextureId)
    {
        glDeleteTextures(1, &updatedTextureId);
        updatedTextureId = 0;
    }
}
@end

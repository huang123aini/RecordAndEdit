//
//  HAVGifFilter.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVGifFilter.h"

#include <sys/time.h>
#import <GLKit/GLKit.h>
#import "HAVTools.h"

#define USE_FBO

NSString *const kGPUImageVertexShaderStringWithTransform = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 uniform mat4 transform;
 
 void main()
 {
     gl_Position = transform * position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

@interface NormalFBO: NSObject

@property(nonatomic,assign)GLuint fbo;
@property(nonatomic,assign)GLuint fboTexture;
@property(nonatomic,assign)CGSize fboSize;
-(instancetype)initWithSize:(CGSize)size;
-(void)bindFBO;
-(void)unbindFBO;

@end

@implementation NormalFBO
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

@interface HAVGifFilter()
{
    GLuint transformSlot;
    GLint filterPositionAttribute2, filterTextureCoordinateAttribute2;
    GLint filterInputTextureUniform2;
    GPUImageFramebuffer *tempFramebuffer;
    NormalFBO* gifResultFBO;
    GLuint textureID;
}
@property (nonatomic, strong) NSMutableArray *modelArray;
@property (nonatomic, strong) NSArray *pathArray;
@property (nonatomic, strong) NSArray *gifArray;
@property (assign, nonatomic) GLKMatrix4 transformMatrix;
@property (strong, nonatomic) GLProgram *transformProgram;
@property(nonatomic,assign)CGFloat  totalTime;
@property(nonatomic,assign)BOOL hasRotate90;

@end

@implementation HAVGifFilter

- (id)initWithGifPath:(NSArray <NSString *> *)pathArr;
{
    self = [super init];
    if (self)
    {
        self.pathArray = [NSArray arrayWithArray:pathArr];
        [self initDefault];
        [self loadGif];
        
        for (GifModel* model in self.modelArray)
        {
            [model initTexture];
        }
    }
    return self;
}

- (id)initWithGif:(NSArray <NSDictionary *> *)arr;
{
    self = [super init];
    if (self)
    {
        self.gifArray = [NSArray arrayWithArray:arr];
        [self initDefault];
        [self loadGif];
        
        for (GifModel* model in self.modelArray)
        {
            [model initTexture];
            model.curFrameTime = 0.f;
        }
        self.totalTime = 0.f;
        textureID = 0;
        self.hasRotate90 = NO;
        self.transformProgram = nil;
        gifResultFBO = nil;
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageContext useImageProcessingContext];
            if (!self.transformProgram)
            {
                self.transformProgram = [self createProgram];//初始化Program
                if (!self->gifResultFBO)//屏幕大小FBO
                {
                    CGFloat scale = [UIScreen mainScreen].scale;
                    CGFloat width = [UIScreen mainScreen].bounds.size.width * scale;
                    CGFloat height = [UIScreen mainScreen].bounds.size.height * scale;
                    self->gifResultFBO = [[NormalFBO alloc] initWithSize:CGSizeMake(width, height)];
                }
            }
        });
    }
    return self;
}

-(instancetype)init
{
    if (self = [super init])
    {
        self.modelArray = [NSMutableArray array];
        self.isPreView = YES;
        self.totalTime = 0.f;
        textureID = 0;
        self.hasRotate90 = NO;
        self.transformProgram = nil;
        gifResultFBO = nil;
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageContext useImageProcessingContext];
            if (!self.transformProgram)
            {
                self.transformProgram = [self createProgram];//初始化Program
                if (!self->gifResultFBO)//屏幕大小FBO
                {
                    CGFloat scale = [UIScreen mainScreen].scale;
                    CGFloat width = [UIScreen mainScreen].bounds.size.width * scale;
                    CGFloat height = [UIScreen mainScreen].bounds.size.height * scale;
                    self->gifResultFBO = [[NormalFBO alloc] initWithSize:CGSizeMake(width, height)];
                    //  self->gifResultFBO = [[NormalFBO alloc] initWithSize:CGSizeMake(720, 1280)];
                }
            }
        });
    }
    return self;
}

- (GLProgram *)createProgram
{
    GLProgram *program = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderStringWithTransform fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
    
    if (!program.initialized)
    {
        [program addAttribute:@"position"];
        [program addAttribute:@"inputTextureCoordinate"];
        [program link];
    }
    
    filterPositionAttribute2 = [program attributeIndex:@"position"];
    filterTextureCoordinateAttribute2 = [program attributeIndex:@"inputTextureCoordinate"];
    filterInputTextureUniform2 = [program uniformIndex:@"inputImageTexture"];
    transformSlot = [program uniformIndex:@"transform"];
    return program;
}
- (void)initDefault
{
    self.modelArray = [NSMutableArray array];
    self.fillMode = kGPUImageFillModePreserveAspectRatio;
}

/*添加Gif对象*/
-(void)addGifObj:(NSDictionary*)dic
{
    [self loadGif:dic];
    NSLog(@"当前gif个数:%ld",self.modelArray.count);
}

/*移除Gif对象*/
-(void)removeGifObj:(NSDictionary*)dic
{
    int tag = [self dicTagInfo:dic];
    for (GifModel* model in self.modelArray)
    {
        if (model.tag == tag)
        {
            @synchronized(self.modelArray)
            {
                [model releaseTextureID]; //移除纹理
                [self.modelArray removeObject:model];
            }
            break;
        }
    }
    NSLog(@"当前gif个数:%ld",self.modelArray.count);
}


- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    static const GLfloat imageVertices[] =
    {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f
    };
    self.totalTime = CMTimeGetSeconds(frameTime);
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];
    [self informTargetsAboutNewFrameAtTime:frameTime];
}

-(void)rendModels
{
    [GPUImageContext setActiveShaderProgram:self.transformProgram];
    
    @synchronized(self.modelArray)
    {
        for (GifModel *model in self.modelArray)
        {
            
            if (model.startTime <= 0.0)
            {
                model.startTime = getCurrentTime();
            }
            
            self.enableGifRepeat = YES;
            
            if (self.enableGifRepeat)
            {
                if (model.curIndex > model.mArray.count - 1)
                {
                    model.curIndex = 0;
                    // model.startTime = getCurrentTime();
                    model.curFrameTime = getCurrentTime();
                }
                NSDictionary *dic = model.mArray[model.curIndex];
                CGFloat ts = [dic[@"ts"] floatValue];
                
                if (model.curFrameTime + ts > getCurrentTime())
                {
                    UIImage *img = [UIImage imageWithCGImage:(__bridge CGImageRef _Nonnull)(dic[@"ref"])];
                    [self setupTexture:img model:model];
                    [self render:model];
                    continue ;
                }else
                {
                    model.curIndex ++;
                    model.curFrameTime = getCurrentTime();
                    if (self.isPreView)
                    {
                        model.curFrameTime += ts * 500;
                        
                    }else
                    {
                        model.curFrameTime += ts * 100;
                    }
                    
                    UIImage *img = [UIImage imageWithCGImage:(__bridge CGImageRef _Nonnull)(dic[@"ref"])];
                    [self setupTexture:img model:model];
                    [self render:model];
                }
                
            }else
            {
                for (NSDictionary *dic in model.mArray)
                {
                    
                    CGFloat ts = [dic[@"ts"] floatValue];
                    if (model.startTime + ts > getCurrentTime())
                    {
                        [self render:model];
                        break ;
                    }
                    UIImage *img = [UIImage imageWithCGImage:(__bridge CGImageRef _Nonnull)(dic[@"ref"])];
                    [self setupTexture:img model:model];
                    [self render:model];
                    [model.mArray removeObject:dic];
                    break ;
                }
            }
        }
    }
    
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    if (!textureID)
    {
        textureID = [HAVTools createTextureWithImage:[UIImage imageNamed:@"a.png"]];
    }
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    if (self.gifRotationMode == kGPUImageRotateRight)
    {
        self.hasRotate90 = YES;
    }
    
#ifdef USE_FBO
    //绘制gif到gifResultFBO
    [gifResultFBO bindFBO];
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self rendModels];
    
    [gifResultFBO unbindFBO];
    
#endif
    
    //绘制到outputFramebuffer
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    [outputFramebuffer activateFramebuffer];
    [GPUImageContext setActiveShaderProgram:filterProgram];
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //视频帧
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(filterInputTextureUniform, 5);
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    
#ifdef USE_FBO
    //draw gifResultFBO
    const GLfloat imageVertices1[] =
    {
        -1., -1.,
        1., -1.,
        -1., 1.,
        1.,  1.,
    };
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D,  [gifResultFBO fboTexture]);
    glUniform1i(filterInputTextureUniform, 3);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices1);
    
    CGFloat sWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat sHeight = [UIScreen mainScreen].bounds.size.height;
    
    if (!self.hasRotate90)
    {
        
        CGSize size = [self sizeOfFBO];
        CGSize firstSize = [firstInputFramebuffer size];
        if (firstSize.width < firstSize.height)//竖屏
        {
            glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
            
        }else if (firstSize.width > firstSize.height)//横屏
        {
            float xSacle = (firstSize.height / firstSize.width) * (sWidth / sHeight);
            float yStart = (1. - xSacle) / 2;
            float yEnd = yStart + xSacle;
            
            const GLfloat texCoords[] =
            {
                0.0f, yStart,
                1.0f, yStart,
                0.0f, yEnd,
                1.0f, yEnd,
            };
            glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, texCoords);
        }else //1:1
        {
            float xSacle = sWidth / sHeight;
            float yStart = (1. - xSacle) / 2;
            float yEnd = yStart + xSacle;
            const GLfloat texCoords[] =
            {
                0.0f, yStart,
                1.0f, yStart,
                0.0f, yEnd,
                1.0f, yEnd,
            };
            glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, texCoords);
        }
        
    }else
    {
        const GLfloat *roatateTexCoords = [GPUImageFilter textureCoordinatesForRotation:kGPUImageRotateLeft];
        glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, roatateTexCoords);
    }
    
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisable(GL_BLEND);
    
    
#endif
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
    
}

- (void)render:(GifModel*)model
{
    [GPUImageContext setActiveShaderProgram:self.transformProgram];
    glActiveTexture(GL_TEXTURE6);
    glBindTexture(GL_TEXTURE_2D, model.gifModelTextureID);
    glUniform1i(filterInputTextureUniform2, 6);
    CGFloat x = 1;
    CGFloat y = 1;
    
    const GLfloat imageVertices[] =
    {
        -x, -y,
        x, -y,
        -x,  y,
        x,  y,
    };
    const GLfloat textureCoordinates[] =
    {
        0, 0,
        1, 0,
        0, 1,
        1, 1
    };
    
    [self setupGif:model];
    glUniformMatrix4fv(transformSlot, 1, 0, self.transformMatrix.m);
    glVertexAttribPointer(filterPositionAttribute2, 2, GL_FLOAT, 0, 0, imageVertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute2, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisable(GL_BLEND);
}

- (void)setupGif:(GifModel *)model
{
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    CGFloat radian = 0.0;
    GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(model.rect.origin.x, model.rect.origin.y-[self modeSize].origin.y*scale, 0);
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(model.radian+radian, 0, 0, 1);
    
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(model.rect.size.width/2, model.rect.size.width/2, 0);
    GLKMatrix4 orthMatrix = GLKMatrix4MakeOrtho(0,
                                                [self modeSize].size.width*scale,
                                                0,
                                                [self modeSize].size.height*scale,
                                                -10,
                                                10);
    
    GLKMatrix4 tmp = GLKMatrix4Multiply(translateMatrix, rotateMatrix);
    tmp = GLKMatrix4Multiply(tmp, scaleMatrix);
    self.transformMatrix = GLKMatrix4Multiply(orthMatrix, tmp);
}

- (CGRect)modeSize
{
    CGRect bounds = [UIScreen mainScreen].bounds;
    if (_fillMode == kGPUImageFillModeStretch)
    {
        return bounds;
    }
    else if (_fillMode == kGPUImageFillModePreserveAspectRatio)
    {
        
        self.isPreView = NO;
        CGRect insetRect;
        if(self.isPreView)
        {
            insetRect  = AVMakeRectWithAspectRatioInsideRect(inputTextureSize, bounds);
        }else
        {
#ifdef USE_FBO
            CGFloat scale = [UIScreen mainScreen].scale;
            CGFloat width = [UIScreen mainScreen].bounds.size.width * scale;
            CGFloat height = [UIScreen mainScreen].bounds.size.height * scale;
            inputTextureSize = CGSizeMake(width, height);
            insetRect = AVMakeRectWithAspectRatioInsideRect(inputTextureSize, bounds);
#else
            insetRect = AVMakeRectWithAspectRatioInsideRect(inputTextureSize, bounds);
#endif
        }
        
        return insetRect;
    }
    else
    {
        CGRect rect = CGRectMake(0, 0, inputTextureSize.width*bounds.size.height/inputTextureSize.height, bounds.size.height);
        return rect;
    }
}

- (CGPoint)convert:(CGPoint)origin
{
    return CGPointMake(0, 0);
}
//
- (void)setupTexture:(UIImage *)image model:(GifModel*)model
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
    //    CGContextTranslateCTM(context, 0, height);
    //    CGContextScaleCTM(context, 1.0f, -1.0f);
    
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);
    
    glBindTexture(GL_TEXTURE_2D, model.gifModelTextureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    CGContextRelease(context);
    free(imageData);
    
}

///毫秒
long long getCurrentTime()
{
    struct timeval val;
    gettimeofday(&val, NULL);
    return (val.tv_sec * 1000 + val.tv_usec / 1000);
}

- (void)dealloc
{
    NSLog(@"------%s------", __FUNCTION__);
    if (self.modelArray)
    {
        for (GifModel* model in self.modelArray)
        {
            [model releaseTextureID];
        }
    }
    [self releaseGifSource];
}
//
//#pragma mark - Gif

- (void)loadGif
{
    for (NSDictionary *dic in self.gifArray)
    {
        
        GifModel *model = [self decodeGif:dic];
        [self.modelArray addObject:model];
    }
}

-(void)loadGif:(NSDictionary*)dic
{
    GifModel *model = [self decodeGif:dic];
    [model initTexture];
    model.curFrameTime = 0.f;
    
    @synchronized(self.modelArray)
    {
        [self.modelArray addObject:model];
        
    }
}
- (void)releaseGifSource{
    for (GifModel *model in self.modelArray) {
        
        [model.mArray removeAllObjects];
        model.mArray = nil;
        
    }
    [self.modelArray removeAllObjects];
}

-(int)dicTagInfo:(NSDictionary*)dic
{
    GifModel *model = [GifModel new];
    model.tag = [dic[kTag] intValue];
    return model.tag;
}

- (GifModel *)decodeGif:(NSDictionary *)dic{
    
    // Update numberOfFrames and frameDurationArray
    const CFStringRef optionKeys[1]   = {kCGImageSourceShouldCache};
    const CFStringRef optionValues[1] = {(CFTypeRef)kCFBooleanFalse};
    CFDictionaryRef options = CFDictionaryCreate(NULL, (const void **)optionKeys, (const void **)optionValues, 1, &kCFTypeDictionaryKeyCallBacks, & kCFTypeDictionaryValueCallBacks);
    CGImageSourceRef _imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:dic[kGifPath]], options);
    CFRelease(options);
    
    GifModel *model = [GifModel new];
    if ([dic[kGifRect] isKindOfClass:[NSString class]])
    {
        model.rect = CGRectFromString(dic[kGifRect]);
    }else
    {
        model.rect = [dic[kGifRect] CGRectValue];
    }
    model.radian = [dic[kGifRadian] floatValue];
    model.tag = [dic[kTag] intValue];
    
    if (_imageSource)
    {
        model.frameCount = CGImageSourceGetCount(_imageSource);
        model.repeatCount = CGImageSourceGetGifLoopCount(_imageSource);
        CGFloat tscount = 0;
        
        NSDictionary *gifProperty = [NSDictionary dictionaryWithObject:@{@0:(NSString *)kCGImagePropertyGIFLoopCount} forKey:(NSString *)kCGImagePropertyGIFDictionary];
        for (NSUInteger i = 0; i < model.frameCount; i++)
        {
            
            model.frameDuration = CGImageSourceGetGifFrameDelay(_imageSource, i) * 1000;
            CGImageRef ref = [self copyImageAtFrameIndex:i imageSource:_imageSource];
            if (ref)
            {
                if (!model.mArray)
                {
                    model.mArray = [NSMutableArray array];
                }
                model.width = CGImageGetWidth(ref);
                model.height = CGImageGetHeight(ref);
                
                NSDictionary *dict = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(_imageSource, i, (CFDictionaryRef)gifProperty));
                NSDictionary *tmp = [dict valueForKey:(NSString *)kCGImagePropertyGIFDictionary];
                tscount += [[tmp valueForKey:(NSString *)kCGImagePropertyGIFDelayTime] floatValue];
                //tscount += model.frameDuration;
                NSDictionary *dic = @{@"ref":(__bridge id _Nonnull)(ref), @"ts":[NSNumber numberWithFloat:tscount]};
                //                 NSLog(@"=========tscount:%f====",tscount);
                [model.mArray addObject:dic];
            }
        }
        CFRelease(_imageSource);
        
    }
    return model;
}

- (CGImageRef)copyImageAtFrameIndex:(NSUInteger)index imageSource:(CGImageSourceRef)imageSource
{
    CGImageRef theImage = CGImageSourceCreateImageAtIndex(imageSource, index, NULL);
    
    return theImage;
}

inline static double CGImageSourceGetGifFrameDelay(CGImageSourceRef imageSource, NSUInteger index)
{
    double frameDuration = 0.0f;
    CFDictionaryRef theImageProperties;
    if ((theImageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, NULL)))
    {
        CFDictionaryRef gifProperties;
        if (CFDictionaryGetValueIfPresent(theImageProperties, kCGImagePropertyGIFDictionary, (const void **)&gifProperties))
        {
            const void *frameDurationValue;
            if (CFDictionaryGetValueIfPresent(gifProperties, kCGImagePropertyGIFUnclampedDelayTime, &frameDurationValue))
            {
                frameDuration = [(__bridge NSNumber *)frameDurationValue floatValue];
                if (frameDuration <= 0)
                {
                    if (CFDictionaryGetValueIfPresent(gifProperties, kCGImagePropertyGIFDelayTime, &frameDurationValue))
                    {
                        frameDuration = [(__bridge NSNumber *)frameDurationValue floatValue];
                    }
                }
            }
        }
        CFRelease(theImageProperties);
    }
    
    //    NSLog(@"Gif frameDuration: %f", frameDuration);
    
    return frameDuration;
}

inline static NSUInteger CGImageSourceGetGifLoopCount(CGImageSourceRef imageSource)
{
    NSUInteger loopCount = 0;
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    if (properties)
    {
        NSNumber *loopCountValue =  (__bridge NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyGIFLoopCount);
        loopCount = [loopCountValue unsignedIntegerValue];
        CFRelease(properties);
    }
    
    return loopCount;
}

@end

@implementation GifModel

- (void)initTexture
{
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &_gifModelTextureID);
    glBindTexture(GL_TEXTURE_2D, _gifModelTextureID);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, 0); //解绑
    
}
-(void)releaseTextureID
{
    glDeleteTextures(1, &_gifModelTextureID);
    _gifModelTextureID = 0;
}

@end

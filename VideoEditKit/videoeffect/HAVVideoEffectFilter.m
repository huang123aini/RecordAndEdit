//
//  HAVVideoEffectFilter.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVVideoEffectFilter.h"
#import "HAVVideoEffectManager.h"
#import "HAVVideoEffectProgramManager.h"
#define kEffect07   7   //凌波微步
#define kEffect15   15  //灵魂出窍

NSString *const kGPUVideoEffectShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
 );

@interface HAVVideoEffectFilter()
{
    GLuint soulTexture;
}
@property (nonatomic, assign) int effectId;
@property (nonatomic, assign) GLint mEnableEffect;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, assign) Float64 frameTime;

@property (nonatomic, strong) HAVVideoEffectManager *effectManager;
@property (nonatomic, strong) HAVVideoEffectProgramManager *manager;
@property (nonatomic, strong) HAVVideoEffect *currentVideoEffect;
@property (nonatomic, assign) BOOL reverse;
@property (nonatomic, assign) CGFloat videoDuration;
@property (nonatomic, strong) GPUImageFramebuffer*frameBuffer;
@property (nonatomic, assign) Float64 lastUpdateTime;
@property (nonatomic, assign) Float64 frameDuration;

@property(nonatomic,strong)NSArray* soulInfos;

@end

@implementation HAVVideoEffectFilter

- (instancetype) init{
    
    self = [super initWithFragmentShaderFromString:kGPUVideoEffectShaderString];
    if (self){
        self.interval = 0.0f;
        self.frameTime = 0.0f;
        self.effectId = 0;
        self.manager = [[HAVVideoEffectProgramManager alloc] init];
        self.effectManager = [[HAVVideoEffectManager alloc] init];
        self.currentVideoEffect = nil;
        self.reverse = NO;
        self.videoDuration = 0.0f;
        self.frameDuration = 0.0f;
        self.lastUpdateTime = 0.0f;
        
        soulTexture = 0;
        self.soulInfos = nil;
    }
    return self;
}

-(void) setSoulInfoss:(NSArray*)array
{
    self.soulInfos = array;
}

-(void)setSoulImage:(UIImage*)soulImage
{
    runSynchronouslyOnVideoProcessingQueue(^{
        
        if(soulTexture)
        {
            glDeleteTextures(1, &soulTexture);
        }
        
        soulTexture = [self createTextureWithImage:soulImage textureId:soulTexture];
    });
}

- (GLuint)createTextureWithImage:(UIImage *)image textureId :(GLuint) textureId;
{
    //    if (image == nil)
    //    {
    //        return 0;
    //    }
    //
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


- (void) reset{
    
    if(self.currentVideoEffect.reversed){
        self.currentVideoEffect.startFrameTime = self.videoDuration - self.frameTime;
    }else{
        self.currentVideoEffect.endFrameTime = self.frameTime;
    }
    self.currentVideoEffect = nil;
    self.frameTime = 0.0f;
    isEndProcessing = NO;
    [self.effectManager resetTimeInterval];
}

- (void) clearVideoEffects{
    [self reset];
    self.currentVideoEffect = nil;
    [self.effectManager removeAllVideoEffect];
}

- (Float64) currentFrameTime{
    return self.frameTime;
}


- (void) newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
    self.frameTime = CMTimeGetSeconds(frameTime);
    
    if(self.lastUpdateTime <= 0.0f)
    {
        self.lastUpdateTime = self.frameTime;
    }
    self.frameDuration = self.frameTime - self.lastUpdateTime;
    self.lastUpdateTime = self.frameTime;
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    GLuint inputTextureUniform =  filterInputTextureUniform ;
    GLuint positionAttribute =  filterPositionAttribute ;
    GLuint textureCoordinateAttribute = filterTextureCoordinateAttribute ;
    HAVVideoEffect *currentEffect = nil;
    if(self.currentVideoEffect != nil){
        currentEffect = self.currentVideoEffect;
    }else{
        Float64 currentTime = self.frameTime;
        if(self.reverse){
            currentTime = _videoDuration - self.frameTime;
            
        }
        currentEffect = [self.effectManager getCurrentEffect:currentTime];
    }
    if (self.preventRendering){
        [firstInputFramebuffer unlock];
        return;
    }
    BOOL isProgram = NO;
    if((currentEffect != nil) && (currentEffect.program != nil)){
        [GPUImageContext setActiveShaderProgram:currentEffect.program];
        inputTextureUniform =  currentEffect.filterInputTextureUniform ;
        positionAttribute =  currentEffect.filterPositionAttribute ;
        textureCoordinateAttribute = currentEffect.filterTextureCoordinateAttribute;
        isProgram = YES;
    }
    
    if(!isProgram){
        [GPUImageContext setActiveShaderProgram:filterProgram];
    }
    
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    if (currentEffect.videoEffectId == kEffect15)
    {
        if (soulTexture)
        {
            glUniform1i(currentEffect.uHasSoulTexture, 1);
            
            glActiveTexture(GL_TEXTURE5);
            glBindTexture(GL_TEXTURE_2D, soulTexture);
            glUniform1i(currentEffect.filterInputTextureUniform2, 5);  //直接绘制到outPutFrameBuffer
        }else
        {
            glUniform1i(currentEffect.uHasSoulTexture, 0);
        }
        
    }
    
    
    //    if (soulTexture)
    //    {
    //        glActiveTexture(GL_TEXTURE5);
    //        glBindTexture(GL_TEXTURE_2D, soulTexture);
    //        glUniform1i(currentEffect.filterInputTextureUniform2, 5);  //直接绘制到outPutFrameBuffer
    //    }
    
    if (self.frameBuffer != nil)
    {
        glActiveTexture(GL_TEXTURE5);
        glBindTexture(GL_TEXTURE_2D, [self.frameBuffer texture]);
        glUniform1i(currentEffect.filterInputTextureUniform2, 5);
        
    }
    
    ////////
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    
    glUniform1i(inputTextureUniform, 2);
    
    if(currentEffect != nil){
        currentEffect.timeInterval += self.frameDuration;
        glUniform1f(currentEffect.mGlobalTime, currentEffect.timeInterval);
        CGSize size = [self sizeOfFBO];
        glUniform2f(currentEffect.iResolution, size.width, size.height);
    }
    
    
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    if(currentEffect.filterInputTextureUniform2 > 0 && currentEffect.videoEffectId == kEffect07)
    {
        if(self.frameBuffer != nil){
            [self.frameBuffer unlock];
        }
        self.frameBuffer = outputFramebuffer;
        [self.frameBuffer lock];
    }else if(currentEffect.filterInputTextureUniform2 > 0 && currentEffect.videoEffectId == kEffect15)
    {
        if (self.frameBuffer != nil)
        {
            [self.frameBuffer unlock];
        }
        self.frameBuffer = nil;
    }
    
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
    
}

- (void) seek2:(Float64)frameTime{
    //    if(self.currentVideoEffect.startFrameIndex == self.frameIndex){
    //        [self.effectManager removeLastVideoEffect];
    //    }else{
    //    self.currentVideoEffect.endFrameIndex = self.frameIndex;
    //    }
    if(self.reverse){
        self.currentVideoEffect.startFrameTime = self.videoDuration- self.frameTime;
    }else{
        self.currentVideoEffect.endFrameTime = self.frameTime;
    }
    self.frameTime = frameTime;
    self.currentVideoEffect = [[HAVVideoEffect alloc] init];
    [self.effectManager addVideoEffect:self.currentVideoEffect];
    self.currentVideoEffect.startFrameTime = self.frameTime;
    self.currentVideoEffect.videoEffectId = self.effectId;
    [self.manager bindProgram:self.currentVideoEffect withSharedId:self.effectId];
}

- (void) seekToTime:(Float64)frameTime{
    self.currentVideoEffect = nil;
    self.frameTime = frameTime;
}

- (void) endProcessing{
    [super endProcessing];
    if(self.currentVideoEffect.reversed){
        self.currentVideoEffect.startFrameTime = self.videoDuration - self.frameTime;
    }else{
        self.currentVideoEffect.endFrameTime = self.frameTime;
    }
    self.currentVideoEffect = nil;
}

- (void) stopCurrentEffect{
    if(self.currentVideoEffect.reversed){
        self.currentVideoEffect.startFrameTime = self.videoDuration - self.frameTime;
    }else{
        self.currentVideoEffect.endFrameTime = self.frameTime;
    }
    self.currentVideoEffect = nil;
}

//- (void) setVideoEffectID:(int) effectId{
//    _effectId = effectId;
//    if(self.currentVideoEffect.startFrameTime == self.frameTime){
//        [self.effectManager removeLastVideoEffect];
//    }else{
//        self.currentVideoEffect.endFrameTime = self.frameTime;
//    }
//    self.currentVideoEffect = [[QAVVideoEffect alloc] init];
//    [self.effectManager addVideoEffect:self.currentVideoEffect];
//    self.currentVideoEffect.startFrameTime = self.frameTime;
//    self.currentVideoEffect.videoEffectId = effectId;
//    [self.manager bindProgram:self.currentVideoEffect withSharedId:effectId];
//}
- (void) setVideoEffectID:(int) effectId{
    _effectId = effectId;
    if(self.currentVideoEffect.startFrameTime == self.frameTime){
        [self.effectManager removeLastVideoEffect];
    }else{
        if(self.currentVideoEffect.reversed){
            self.currentVideoEffect.startFrameTime = self.videoDuration - self.frameTime;
            //            NSLog(@"uuu startFrameTime:%f", self.currentVideoEffect.startFrameTime);
        }else{
            self.currentVideoEffect.endFrameTime =  self.frameTime;
        }
    }
    self.currentVideoEffect = [[HAVVideoEffect alloc] init];
    [self.effectManager addVideoEffect:self.currentVideoEffect];
    self.currentVideoEffect.reversed = self.reverse;
    if(self.reverse){
        self.currentVideoEffect.endFrameTime = self.videoDuration - self.frameTime;
    }else{
        self.currentVideoEffect.startFrameTime = self.frameTime;
    }
    self.currentVideoEffect.videoEffectId = effectId;
    [self.manager bindProgram:self.currentVideoEffect withSharedId:effectId];
}

- (void) changeVideoEffectID:(int) effectId{
    _effectId = effectId;
    self.currentVideoEffect = [[HAVVideoEffect alloc] init];
    self.currentVideoEffect.videoEffectId = effectId;
    [self.manager bindProgram:self.currentVideoEffect withSharedId:effectId];
}

-(void) remove{
    self.currentVideoEffect = nil;
}

- (void) back{
    self.currentVideoEffect = nil;
    HAVVideoEffect *effect = [[self.effectManager allVideoEffect] lastObject];
    self.frameTime = effect.startFrameTime;
    [self.effectManager removeLastVideoEffect];
}

- (NSArray *) archiver{
    return [self.effectManager archiver];
}

- (void) unArchiver:(NSArray *) array{
    for (NSData *data in array){
        HAVVideoEffect *effect = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [self.manager bindProgram:effect withSharedId:effect.videoEffectId];
        [self.effectManager addVideoEffect:effect];
    }
}

- (void) setReverse:(BOOL) reverse{
    _reverse = reverse;
}

- (void) setDuration:(CGFloat)duration{
    _videoDuration = duration;
}

- (void)dealloc
{
    if(self.frameBuffer != nil){
        [self.frameBuffer unlock];
        self.frameBuffer = nil;
    }
    
    if (soulTexture)
    {
        glDeleteTextures(1, &soulTexture);
    }
    
}
@end

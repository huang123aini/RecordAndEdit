//
//  HAVLutImageFilter.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVLutImageFilter.h"
#import <GPUKit/GPUKit.h>
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUAuxImageFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2; // TODO: This is not used
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; // lookup texture
 
 uniform lowp float intensity ;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     highp float blueColor = textureColor.b * 15.0;
     
     highp vec2 quad1;
     quad1.y = floor(floor(blueColor) / 4.0);
     quad1.x = floor(blueColor) - (quad1.y * 4.0);
     
     highp vec2 quad2;
     quad2.y = floor(ceil(blueColor) / 4.0);
     quad2.x = ceil(blueColor) - (quad2.y * 4.0);
     
     highp vec2 texPos1;
     texPos1.x = (quad1.x * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.r);
     texPos1.y = (quad1.y * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.g);
     
     highp vec2 texPos2;
     texPos2.x = (quad2.x * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.r);
     texPos2.y = (quad2.y * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.g);
     
     lowp vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
     lowp vec4 newColor2 = texture2D(inputImageTexture2, texPos2);
     
     lowp vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
     gl_FragColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), intensity);
 }
 );
#else
NSString *const kGPUImageLookupFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2; // TODO: This is not used
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; // lookup texture
 
 uniform float intensity ;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     highp float blueColor = textureColor.b * 15.0;
     
     highp vec2 quad1;
     quad1.y = floor(floor(blueColor) / 4.0);
     quad1.x = floor(blueColor) - (quad1.y * 4.0);
     
     highp vec2 quad2;
     quad2.y = floor(ceil(blueColor) / 4.0);
     quad2.x = ceil(blueColor) - (quad2.y * 4.0);
     
     highp vec2 texPos1;
     texPos1.x = (quad1.x * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.r);
     texPos1.y = (quad1.y * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.g);
     
     highp vec2 texPos2;
     texPos2.x = (quad2.x * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.r);
     texPos2.y = (quad2.y * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.g);
     
     lowp vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
     lowp vec4 newColor2 = texture2D(inputImageTexture2, texPos2);
     
     lowp vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
     gl_FragColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), intensity);
 }
 );
#endif

@interface HAVLutImageFilter()
{
    GLint intensityUniform;
}

@property (nonatomic, strong) GPUImagePicture* auxPicture;
- (id)initWithPrepareBlock:(prepare_block_t)prepareBlock;

@end

@implementation HAVLutImageFilter

@synthesize intensity = _intensity;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithPrepareBlock:(prepare_block_t)prepareBlock;
{
    
    
    if (!(self = [super initWithFragmentShaderFromString:kGPUAuxImageFragmentShaderString withPrepareBlock:prepareBlock]))
    {
        return nil;
    }
    intensityUniform = [filterProgram uniformIndex:@"intensity"];
    self.intensity = 0.5f;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setIntensity:(CGFloat)intensity
{
    _intensity = intensity;
    
    [self setFloat:_intensity forUniform:intensityUniform program:filterProgram];
}


- (instancetype)init
{
    return [self initWithImageName:@""];
}

- (instancetype)initWithImageName:(NSString *)imageName
{
    if ([imageName length] == 0) {
        return nil;
    }
    
    self = [self initWithPrepareBlock:^(id obj) {
        [((HAVLutImageFilter *)obj).auxPicture addTarget:obj];
    }];
    
    if (self) {
        self.auxPicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:imageName]];
        [self.auxPicture processImage];
    }
    
    return self;
}


- (void) releaseFilter{
    [self.auxPicture removeAllTargets];
    self.auxPicture = nil;
}
@end

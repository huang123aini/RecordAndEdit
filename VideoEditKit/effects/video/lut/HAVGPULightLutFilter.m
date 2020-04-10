//
//  HAVGPULightLutFilter.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVGPULightLutFilter.h"

NSString *const kGPUImageLightFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; // lookup texture
 
 void main() {
     highp vec4 color1 = texture2D(inputImageTexture, textureCoordinate);
     highp vec4 color2 = texture2D(inputImageTexture2, textureCoordinate);
     gl_FragColor = mix(color1, max(color1,  color2), 0.3);
 }
 );

@interface HAVGPULightLutFilter()

@property (nonatomic, strong) GPUImagePicture* auxPicture;

@end

@implementation HAVGPULightLutFilter

- (instancetype)init
{
    return [self initWithImageName:@""];
}

- (instancetype)initWithPrepareBlock:(prepare_block_t)prepareBlock
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageLightFragmentShaderString withPrepareBlock:prepareBlock]))
    {
        return nil;
    }
    
    return self;
}

- (instancetype)initWithImageName:(NSString *)imageName
{
    if ([imageName length] == 0) {
        return nil;
    }
    self = [self initWithPrepareBlock:^(id obj) {
        [((HAVGPULightLutFilter *)obj).auxPicture addTarget:obj];
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

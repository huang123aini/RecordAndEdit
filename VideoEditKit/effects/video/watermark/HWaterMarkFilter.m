//
//  HWaterMarkFilter.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/9.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HWaterMarkFilter.h"
#import <GLKit/GLKit.h>

@interface HWaterMarkFilter()
@property (nonatomic, strong) HWaterMark *waterMark;
@property (nonatomic, assign) CMTime currentFrameTime;
@property (nonatomic, assign) GPUImageRotationMode rotationMode;
@end

@implementation HWaterMarkFilter

- (instancetype) initWithWaterMark:(HWaterMark*)waterMark
{
    self = [super init];
    if(self)
    {
        self.waterMark = waterMark;
    }
    return self;
}

-(instancetype)initWithImages:(NSArray*)array pictureSize:(CGSize) size postion:(CGPoint ) point
{
    self = [super init];
    if(self)
    {
        self.waterMark = [[HWaterMark alloc] initWithImageArray:array pictureSize:size postion:point];
    }
    return self;
}

-(instancetype)initWithImages:(NSArray*)array pictureSize:(CGSize) picSize fboSize:(CGSize)fboSize  postionOffset:(CGPoint) offsetPoint  orientation:(UIInterfaceOrientation)orientation;
{
    self = [super init];
    if (self)
    {
        
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        {
            fboSize = CGSizeMake(fboSize.height, fboSize.width);
        }
        
        CGPoint position = CGPointZero;
        switch (orientation)
        {
            case 1:
            {
                position = CGPointMake(fboSize.width - picSize.width / 2.0f, picSize.height / 2.0 + offsetPoint.y);
                break;
            }
            case 2:
            {
                
                position = CGPointMake(picSize.width / 2.0 + offsetPoint.y,fboSize.height - picSize.height / 2.0f);
                break;
            }
            case 3:
            {
                position = CGPointMake(fboSize.width -  (fboSize.width - picSize.width / 2.0f), picSize.height / 2.0 + offsetPoint.y);
                break;
            }
            case 4:
            {
                position = CGPointMake(fboSize.width - picSize.width / 2.0f,  fboSize.height -  (picSize.height / 2.0 + offsetPoint.y));
                break;
            }
            default:
                break;
        }
        //调整position
        self.waterMark = [[HWaterMark alloc] initWithImageArray:array pictureSize:picSize postion:position];
    }
    return self;
}

-(void)setFps:(int)fps
{
    if (self.waterMark)
    {
        self.waterMark.fps = fps;
    }
}

-(void)setRotation:(int)mode
{
    [self.waterMark setRotation:mode];
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
    self.currentFrameTime = frameTime;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates];
    /////inputRotation
    self.waterMark.inputTextureUniform = filterInputTextureUniform;
    self.waterMark.textureCoordinateAttribute = filterTextureCoordinateAttribute;
    self.waterMark.positionAttribute = filterPositionAttribute;
    self.waterMark.frameBufferSize = [self sizeOfFBO];
    [self.waterMark drawFrameAtTime:self.currentFrameTime];
}

@end

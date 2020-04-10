//
//  HAVGPUImageMovie.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVGPUImageMovie.h"

@interface HAVGPUImageMovie()
{
    GPUImageRotationMode outputRotation;
}
@property (nonatomic , weak) id<GPUImageInput> targetFilter;
@end

@implementation HAVGPUImageMovie

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    self.targetFilter = newTarget;
    [super addTarget:newTarget atTextureLocation:textureLocation];
    [newTarget setInputRotation:outputRotation atIndex:textureLocation];
}


- (void) setOutputRotation:(GPUImageRotationMode) rotation
{
    outputRotation = rotation;
    [self.targetFilter setInputRotation:outputRotation atIndex:0];
}

- (void) initOutputRotation:(AVAsset *) asset
{
    outputRotation = kGPUImageNoRotation;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0)
    {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;//这里的矩阵有旋转角度，转换一下即可
        // NSUInteger degress = 0;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
        {
            // Portrait
            // degress = 90;
            outputRotation = kGPUImageRotateRight;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)
        {
            // PortraitUpsideDown
            outputRotation = kGPUImageRotateLeft;
            
            //degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
        {
            // LandscapeRight
            outputRotation = kGPUImageNoRotation;
            //            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
        {
            // LandscapeLeft
            outputRotation = kGPUImageRotate180;
            //degress = 180;
        }
    }
}

- (id)initWithURL:(NSURL *)url;
{
    self = [super initWithURL:url];
    if(self)
    {
        AVAsset *asset = [AVAsset assetWithURL:url];
        [self initOutputRotation:asset];
    }
    return self;
}

- (id)initWithAsset:(AVAsset *)asset;
{
    self = [super initWithAsset:asset];
    if(self)
    {
        [self initOutputRotation:asset];
    }
    return self;
}

- (id)initWithPlayerItem:(AVPlayerItem *)playerItem;
{
    
    self = [super initWithPlayerItem:playerItem];
    if(self)
    {
        [self initOutputRotation:playerItem.asset];
    }
    return self;
}
@end

//
//  AVAssetTrack+GPUImageRotation.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "AVAssetTrack+GPUImageRotation.h"

@implementation AVAssetTrack (GPUImageRotation)

- (GPUImageRotationMode) transform2GPUImageRoation
{
    GPUImageRotationMode outputRotation = kGPUImageNoRotation;
    CGAffineTransform t = self.preferredTransform;//这里的矩阵有旋转角度，转换一下即可
    //NSUInteger degress = 0;
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
        // degress = 0;
    }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
    {
        // LandscapeLeft
        outputRotation = kGPUImageRotate180;
        // degress = 180;
    }
    return outputRotation;
}

@end

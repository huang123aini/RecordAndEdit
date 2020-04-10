//
//  HAVDataSourceDelegate.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

@protocol HAVDataSourceDelegate <NSObject>

- (float) getRatio;
- (GPUImageRotationMode) rotation;
- (CVPixelBufferRef) copyFrameAtTime:(CMTime) time;

@end

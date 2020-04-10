//
//  AVAssetTrack+GPUImageRotation.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AVAssetTrack (GPUImageRotation)

- (GPUImageRotationMode) transform2GPUImageRoation;

@end

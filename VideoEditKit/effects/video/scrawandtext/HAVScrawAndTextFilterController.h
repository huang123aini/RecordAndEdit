//
//  HAVScrawAndTextFilterController.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUKit/GPUKit.h>
#import "HAVGPUImageFilterProtocol.h"

@interface HAVScrawAndTextFilterController : NSObject <HAVGPUImageFaceTrackProtocol>

@property (nonatomic, strong) UIImage *updatedImage;
@property (nonatomic, assign) GPUImageRotationMode rotationMode;

-(void)toReset;

-(void)disableShow:(BOOL)isShow;

@end

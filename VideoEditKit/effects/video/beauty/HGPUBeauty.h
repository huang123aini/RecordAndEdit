//
//  HGPUBeauty.h
//  HAVKit
//
//  Created by 黄世平 on 2019/1/20.
//  Copyright © 2019 黄世平. All rights reserved.
//

#import <GPUKit/GPUKit.h>
#import "HNormalFBO.h"
@interface HGPUBeauty : GPUImageFilter

@property(nonatomic,assign)float smoothing;
@property(nonatomic,assign)float reddening;
@property(nonatomic,assign)float whitening;

@end

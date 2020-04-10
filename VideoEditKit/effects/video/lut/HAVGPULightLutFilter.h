//
//  HAVGPULightLutFilter.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>

@interface HAVGPULightLutFilter : GPUImageLookupFilter

- (instancetype)initWithImageName:(NSString *)imageName;

- (void) releaseFilter;

@end

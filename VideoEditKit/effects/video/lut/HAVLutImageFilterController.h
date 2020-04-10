//
//  HAVLutImageFilterController.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVGPUImageFilterProtocol.h"


typedef NS_ENUM(NSInteger,FILTERTYPE)
{
    FILTERTYPE_4X4,
    FILTERTYPE_8X8,
    FILTERTYPE_Light,
};

@interface HAVLutImageFilterController : NSObject<HAVGPUImageFaceTrackProtocol>

- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithAuxImageName:(NSString *)imageName withType:(FILTERTYPE)type ;

@end

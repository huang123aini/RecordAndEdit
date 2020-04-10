//
//  HGPUBeautyFilterController.h
//  QAVKit
//
//  Created by 黄世平 on 2019/1/22.
//  Copyright © 2019 guowei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVGPUImageFilterProtocol.h"

@interface HGPUBeautyFilterController : NSObject <HAVGPUImageFaceTrackProtocol>

-(void)setSmoothValue:(float)value;
-(void)setRedValue:(float)value;
-(void)setWhitenValue:(float)value;

@end

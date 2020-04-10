//
//  AVURLAsset+MetalData.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "AVAsset+MetalData.h"

@interface AVURLAsset (MetalData)

- (CGSize) videoNaturalSize;
- (CGSize) videoSize:(HAVVideoSize) videosize;

@end

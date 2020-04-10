//
//  AVAsset+MetalData.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "HAVVideoSize.h"

@interface AVAsset (MetalData)

- (CGSize) videoNaturalSize;

- (CGSize) videoSize:(HAVVideoSize) size;

- (NSString *) presetFromVideoSize:(HAVVideoSize) videoSize;

@end

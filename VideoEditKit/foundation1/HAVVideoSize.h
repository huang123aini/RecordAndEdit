//
//  HAVVideoSize.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HAVVideoSize)
{
    HAVVideoSizeNature ,//// 与原视频相同
    HAVVideoSize360p, ///分辨率640x360
    HAVVideoSize480p, ///分辨率640x480
    HAVVideoSize540p, ///分辨率960x540
    HAVVideoSize720p, ///分辨率1280x720
    HAVVideoSize1080p, ///分辨率1920x1080
    HAVVideoSize4K, ///分辨率3840x2160
    HAVVideoSizeCustom540
};

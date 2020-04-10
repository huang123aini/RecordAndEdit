//
//  HAVAlignment.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 当音视频的长度不一致的时候合并或者截取文件的对齐规则
 **/
typedef NS_ENUM(NSInteger, HAVAlignment)
{
    HAVAlignmentShort, // 以较短的内容为对齐原则
    HAVAlignmentLong, //// 以较长的内容为对齐原则
    HAVAlignmentVideo, //// 以视频内容为对齐原则
    HAVAlignmentAudio, ///以音频内容为对齐原则
};

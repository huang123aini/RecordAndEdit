//
//  HAVGifFilterController.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HAVGPUImageFilterProtocol.h"

#define kGifPath    @"kGifPath"
#define kGifRect    @"kGifRect"
#define kGifRadian  @"kGifRadian"

@interface HAVGifFilterController : NSObject <HAVGPUImageFaceTrackProtocol>

/**
 允许重复播放gif
 */
@property (nonatomic, assign) BOOL enableGifRepeat;

/**
 加载gif
 
 @param arr kGifPath:gif路径, kGifRect:gif位置和大小，按点传, kGifRadian:弧度
 @return 返回实例
 */
- (id)initWithGif:(NSArray <NSDictionary *> *)arr;


/*添加Gif对象*/
-(void)addGifObj:(NSDictionary*)dic;

/*移除Gif对象*/
-(void)removeGifObj:(NSDictionary*)dic;

@end

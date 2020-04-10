//
//  HAVGPUImageFilterProtocol.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/*
 *人脸识别在单独Queue里
 *回调处理切勿阻塞Face Track Queue
 */

#ifndef HJGPUImageFilterProtocol_h
#define HJGPUImageFilterProtocol_h
@class AIFaceTrackObject;

@protocol HAVGPUImageFaceTrackProtocol <NSObject>

@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, assign) BOOL enableFaceTrack;
@property (nonatomic, strong) NSMutableArray * __nullable filters;

@optional
/*
 *人脸识别回调
 */
- (void) simpleBufferWillStartFaceTrack;
- (void) simpleBufferDidEndFaceTrack;
- (void) simpleBufferHasFaceTrack:(AIFaceTrackObject * __nullable)trackResult;

@end


/*
 *  StreamPicker的Filter数据源
 */
@protocol HAVGPUImageFilterDataSource <NSObject>

/*
 *获取所有要添加的filter
 */
- (NSMutableArray * __nullable)filterListForGPUImage;

@end


#endif /* HJGPUImageFilterProtocol_h */

//
//  HAVGPUImageFilterManager.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVGPUImageFilterProtocol.h"
/*
 *人脸识别代理
 */
@protocol HAVStreamPickerFaceTrackDelegate <NSObject>
/*
 *回调数据用于人脸识别
 */
- (void)succToPickWithStreamBufferForFaceTrack:(CMSampleBufferRef)sampleBuffer position:(AVCaptureDevicePosition)position;

@end

@protocol FaceTrackDelegate <NSObject>

@required

- (void) faceDetectOnPoint:(CGPoint) point;
- (void) faceDetectInRect:(CGRect) rect WithFaceCount:(int)count;

@end

@interface HAVGPUImageFilterManager : NSObject <HAVGPUImageFilterDataSource, HAVStreamPickerFaceTrackDelegate>
{
    
}
@property (nonatomic, assign) id<FaceTrackDelegate> faceDetectDelegate;
@property (nonatomic, assign) NSTimeInterval focusTimeInterval;
/*
 *当前所有生效的Controller
 */
@property (nonatomic, strong) NSMutableArray <HAVGPUImageFaceTrackProtocol> *filterControllers;

@property (nonatomic, assign) BOOL enableCpuFabby;
@property (nonatomic, assign) BOOL enableGpuFabby;

/*
 *清空当前Controller
 */

- (void) resetAllFilterController;

/*
 *添加一个Controller
 */
- (BOOL)addFilterController:(id <HAVGPUImageFaceTrackProtocol> )filterController;
/*
 *删除一个Controller
 */
- (BOOL)removeFilterController:(id <HAVGPUImageFaceTrackProtocol> )filterController;
/*
 *替换一个Controller
 */
- (BOOL)replaceFilterController:(id <HAVGPUImageFaceTrackProtocol> )oldFilterController withFilterController:(id <HAVGPUImageFaceTrackProtocol> )newFilterController;

@end

//
//  HAVGPUImageFilterManager.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVGPUImageFilterManager.h"
//#import <AIFaceTrack/AIFaceTrack.h>

@interface HAVGPUImageFilterManager ()
{
    //人脸识别队列
    dispatch_queue_t  _faceTrackQueue;
    //是否正在进行人脸识别
   // AIFaceTracker  *_faceTrack;
    BOOL  _faceThinking;
    //是否人脸识别
    BOOL  _shouldTrackFace;
    BOOL  _changing;
}

/*
 *所有需要加入GPUImagePipeline的Filter
 */
@property (nonatomic, strong) NSMutableArray *filterList;
@property (nonatomic, assign) NSTimeInterval lastFoucsTimeInterval;

@end

@implementation HAVGPUImageFilterManager

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.filterList = [NSMutableArray array];
        self.filterControllers = (NSMutableArray <HAVGPUImageFaceTrackProtocol> *) [NSMutableArray array];
        self.focusTimeInterval = 15;
        self.lastFoucsTimeInterval = 0;
        [self initFaceTrack];
    }
    return self;
}

- (BOOL)initFaceTrack
{
    [self destoryFaceTrack];
//    _faceTrack = [AIFaceTracker getInstance];
//    [_faceTrack reset];
//    if (_faceTrack != nil)
//    {
//        if (!_faceTrackQueue)
//        {
//            _faceTrackQueue = dispatch_queue_create("Faceu Queue", DISPATCH_QUEUE_SERIAL);
//        }
//        _faceThinking = NO;
//        return YES;
//    }
    return NO;
}


- (void)destoryFaceTrack
{
    //    if (_hTracker_qihoo) {
    //        qh_face_destroy_tracker(_hTracker_qihoo);
    //        _hTracker_qihoo = NULL;
    //    }
}

- (void)resetAllFilterController
{
    @synchronized (self.filterControllers) {
        _changing = YES;
        [self.filterList removeAllObjects];
        [self.filterControllers removeAllObjects];
        _changing = NO;
    }
}

#pragma mark --- HJGPUImageFilterDataSource
- (NSMutableArray *)filterListForGPUImage
{
    return self.filterList;
}

#pragma mark --- FilterController Operation
- (BOOL)addFilterController:(id)filterController
{
    @synchronized (self.filterControllers) {
        if (filterController && [filterController conformsToProtocol:@protocol(HAVGPUImageFaceTrackProtocol)]) {
            if (![self.filterControllers containsObject:filterController]) {
                _changing = YES;
                [self.filterControllers addObject:filterController];
                NSArray *filterControllers = [self.filterControllers sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    id <HAVGPUImageFaceTrackProtocol> filterController1 = obj1;
                    id <HAVGPUImageFaceTrackProtocol> filterController2 = obj2;
                    if(filterController1.priority > filterController2.priority){
                        return NSOrderedDescending ;
                    }else if(filterController1.priority == filterController2.priority){
                        return NSOrderedSame;
                    }else{
                        return NSOrderedAscending;
                    }
                }];
                [self.filterControllers removeAllObjects];
                [self.filterControllers addObjectsFromArray:filterControllers];
                [self removeAllFilters];
                NSMutableArray *filtersArray = [NSMutableArray array];
                for (id<HAVGPUImageFaceTrackProtocol> filterController in self.filterControllers){
                    [filtersArray addObjectsFromArray:[filterController filters]];
                }
                [self addFilters:filtersArray];
                [self updateShouldTrackFace];
                _changing = NO;
                return YES;
            }
        }
        return NO;
    }
    
    
}

- (BOOL)removeFilterController:(id)filterController
{
    @synchronized (self.filterControllers) {
        if (filterController && [self.filterControllers containsObject:filterController]) {
            _changing = YES;
            [self removeFilters:[filterController filters]];
            [self.filterControllers removeObject:filterController];
            [self updateShouldTrackFace];
            _changing = NO;
            return YES;
        }
        return NO;
    }
}

- (BOOL)replaceFilterController:(id <HAVGPUImageFaceTrackProtocol> )oldFilterController withFilterController:(id <HAVGPUImageFaceTrackProtocol> )newFilterController
{
    @synchronized (self.filterControllers) {
        if (oldFilterController || newFilterController) {
            _changing = YES;
            [self removeFilterController:oldFilterController];
            BOOL succ = [self addFilterController:newFilterController];
            _changing = NO;
            return succ;
        }
        return NO;
    }
}

- (void)updateShouldTrackFace
{
    BOOL faceTrack = NO;
    for (id <HAVGPUImageFaceTrackProtocol> controller in self.filterControllers) {
        if (controller.enableFaceTrack) {
            faceTrack = YES;
            break;
        }
    }
    _shouldTrackFace = YES;
}

#pragma mark --- Filter Operation
- (BOOL)addFilter:(GPUImageOutput <GPUImageInput>*)filter
{
    @synchronized (self.filterList) {
        if (filter && [filter isKindOfClass:[GPUImageOutput class]]) {
            [self.filterList addObject:filter];
            return YES;
        }
        return NO;
    }
}

- (BOOL)addFilters:(NSArray *)filters
{
    @synchronized (self.filterList) {
        for (GPUImageOutput <GPUImageInput> *filter in filters) {
            if ([filter isKindOfClass:[GPUImageOutput class]]) {
                [self.filterList addObject:filter];
            } else {
                return NO;
            }
        }
        return YES;
    }
}

- (BOOL)removeFilter:(GPUImageOutput<GPUImageInput>*)filter
{
    if (filter == nil) {
        return NO;
    }
    @synchronized (self.filterList) {
        if ([self.filterList containsObject:filter]) {
            [self.filterList removeObject:filter];
            return YES;
        }
        return NO;
    }
}

- (void) removeAllFilters{
    @synchronized (self.filterList) {
        [self.filterList removeAllObjects];
    }
}

- (BOOL)removeFilters:(NSArray *)filters
{
    if ([filters count] == 0) {
        return NO;
    }
    @synchronized (self.filterList) {
        for (GPUImageOutput <GPUImageInput> *filter in filters) {
            [self.filterList removeObject:filter];
        }
        return YES;
    }
}


#pragma mark --- HAVGPUImageFilterDataSource
- (void)succToPickWithStreamBufferForFaceTrack:(CMSampleBufferRef)sampleBuffer position:(AVCaptureDevicePosition)position
{
  
    if (!_faceThinking)
    {
        if (_faceTrackQueue)
        {
            CFRetain(sampleBuffer);
            dispatch_async(_faceTrackQueue, ^{
                [self faceTrackForSampleBuffer:sampleBuffer position:position];
                CFRelease(sampleBuffer);
            });
        }
    }
   
}

- (void)faceTrackForSampleBuffer:(CMSampleBufferRef)sampleBuffer position:(AVCaptureDevicePosition)position
{
    _faceThinking = YES;
//    if (_faceTrack != nil)
//    {
//
//        CFRetain(sampleBuffer);
//
//        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//        CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
//
//        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
//        int iWidth = (int)CVPixelBufferGetWidth(imageBuffer);
//        int iHeight = (int)CVPixelBufferGetHeight(imageBuffer);
//
//
//        //        NSLog(@"_faceTrack:%@,iWidth:%d,iHeight:%d",_faceTrack,iWidth,iHeight);
//
//        AIFaceTrackObject *trackObject = [_faceTrack getFaceTackObject:CGSizeMake(iWidth, iHeight) withPixelBuffer:baseAddress position:position];
//
//        [self sendFaceTrackResultToObservers:trackObject];
//        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//        CFRelease(sampleBuffer);
//    }
    
    _faceThinking = NO;
}

- (void) updateFaceDetectedInfo:(AIFaceTrackObject *)trackObject
{
    CGPoint ptNose = CGPointZero;
    CGRect faceRect = CGRectZero;
//    if(trackObject.faceInfos.count > 0)
//    {
//        AIFaceInfo *info=  [trackObject.faceInfos firstObject];
//        if(info.points_5.count > 3){
//            ptNose = [info.points_5[2] CGPointValue];
//        }
//
//        if(info.points_95.count >= 90){
//            CGPoint leftPoint = [self leftPoint:info.points_95 from:0 count:9];
//            CGPoint rightPoint = [self rightPoint:info.points_95 from: 10 count:9];
//            CGPoint topPoint = [self topPoint:info.points_95 from:0 count:19];
//            CGPoint bottomPoint = [self bottomPoint:info.points_95 from:0 count:19];
//            CGPoint nosePoint = [info.points_95[65] CGPointValue]; ///取 65或者64
//            CGFloat distanceX = (rightPoint.x - leftPoint.x) * 0.2;
//            //CGPoint nosePoint =  CGPointZero;
//            CGFloat x = leftPoint.x - distanceX;
//            x = x > 0.0f ?x :0.0f;
//            CGFloat width = rightPoint.x - leftPoint.x + 2 * distanceX;
//            //CGFloat distanceY = (bottomPoint.y - topPoint.y + (bottomPoint.y - nosePoint.y)) * 0.05;
//            CGFloat distanceY = 0.0f;///(bottomPoint.y - topPoint.y + (bottomPoint.y - nosePoint.y)) * 0.05;
//            CGFloat y = topPoint.y  - distanceY -  (bottomPoint.y - nosePoint.y) ;
//            y = y > 0.0f?y:0.0f;
//            CGFloat height = bottomPoint.y - topPoint.y +  2 * distanceY + (bottomPoint.y - nosePoint.y);
//            faceRect = CGRectMake(x, y, width, height);
//        }
//    }
    
    NSTimeInterval currentTimeIntrval = [[NSDate date] timeIntervalSince1970];
    if(currentTimeIntrval - self.lastFoucsTimeInterval > self.focusTimeInterval){
        self.lastFoucsTimeInterval = currentTimeIntrval;
        if([self.faceDetectDelegate respondsToSelector:@selector(faceDetectOnPoint:)]){
            [self.faceDetectDelegate faceDetectOnPoint:ptNose];
        }
    }
    
    if([self.faceDetectDelegate respondsToSelector:@selector(faceDetectInRect:WithFaceCount:)]){
       // [self.faceDetectDelegate faceDetectInRect:faceRect WithFaceCount:trackObject.iCount];
    }
}

- (CGPoint) leftPoint:(NSArray *) array from:(int )from count:(int) count{
    CGPoint returnPoint = CGPointZero;
    if(array.count > from+count){
        returnPoint = [[array objectAtIndex:from] CGPointValue];
        for (int i = from; i< from +count; i ++){
            CGPoint point = [[array objectAtIndex:i] CGPointValue];
            if(point.x < returnPoint.x){
                returnPoint = point;
            }
        }
    }
    return returnPoint;
}


- (CGPoint) rightPoint:(NSArray *) array from:(int )from count:(int) count{
    CGPoint returnPoint = CGPointZero;
    if(array.count > from+count){
        returnPoint = [[array objectAtIndex:from] CGPointValue];
        for (int i = from; i < from +count; i ++){
            CGPoint point = [[array objectAtIndex:i] CGPointValue];
            if(point.x > returnPoint.x){
                returnPoint = point;
            }
        }
    }
    return returnPoint;
}

- (CGPoint) bottomPoint:(NSArray *) array from:(int )from count:(int) count{
    CGPoint returnPoint = CGPointZero;
    if(array.count > from+count){
        returnPoint = [[array objectAtIndex:from] CGPointValue];
        for (int i = from; i< from + count; i ++){
            CGPoint point = [[array objectAtIndex:i] CGPointValue];
            if(point.y > returnPoint.y){
                returnPoint = point;
            }
        }
    }
    return returnPoint;
}
- (CGPoint) topPoint:(NSArray *) array from:(int )from count:(int) count{
    CGPoint returnPoint = CGPointZero;
    if(array.count > from+count){
        returnPoint = [[array objectAtIndex:from] CGPointValue];
        for (int i = from; i< from +count; i ++){
            CGPoint point = [[array objectAtIndex:i] CGPointValue];
            if(point.y < returnPoint.y){
                returnPoint = point;
            }
        }
    }
    return returnPoint;
}

#pragma mark --- Face Track Notification
- (void)sendFaceTrackResultToObservers:(AIFaceTrackObject *)object
{
    
    [self updateFaceDetectedInfo:object];
    if (!_changing) {
        @synchronized (self.filterControllers) {
            for (id target in self.filterControllers) {
                if ([target respondsToSelector:@selector(simpleBufferHasFaceTrack:)]) {
                    
                    [target simpleBufferHasFaceTrack:object];
                    
                }
            }
        }
    }
}

- (void)dealloc
{
    //    [self destoryFaceTrack];
}

@end

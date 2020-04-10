//
//  DCMovieAssetExport.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HAVVideoSize.h"
#import "HAVMoviePlayer.h"

#define CodecConstant_VIDEO_HEIGHT 640
#define CodecConstant_VIDEO_WIDTH 360

@interface HAVMovieAssetExport : NSObject

@property (nonatomic, assign) NSInteger bitRate;
@property (nonatomic, assign) HAVVideoSize videSize;
@property (nonatomic, strong) NSString *outputPath;
@property (nonatomic, strong) NSString *metaData;
@property (nonatomic, assign) BOOL onlyKeyFrame;
@property (nonatomic, assign) HAVVideoRotation currentRotation;
@property (nonatomic, readonly) CMTime exportDuration;
@property (nonatomic, readonly) CGFloat exportProgress;

- (instancetype) initWithAsset:(AVAsset*) asset;

- (instancetype) initWitHAVAsset:(HAVAsset*) asset;

- (instancetype) initWithAssetItem:(HAVAssetItem *) item audioAssetItem:(HAVAssetItem *) audioAssetItem;

- (instancetype) initWithAssetItems:(NSArray<HAVAssetItem *>*) assetItems audioAssetItem:(HAVAssetItem *) audioAssetItem;

- (void) exportAsynchronouslyWithFilters:(NSArray *) filters withCompletionHandler:(void (^)(BOOL status, NSString *path ,NSError * error))handler;

- (void) cancelExport;

/*
 * sourceKey: 1表示源文件是全I帧文件
 */
- (void) reverseVideo:(NSString *)sourceUrl outputURL:(NSString *)outputUrl videoSize:(HAVVideoSize)videoSize sourceKey:(BOOL)sourceKey cancel:(BOOL *)cancel progressHandle:(void (^)(CGFloat progress))progressHandle finishHandle:(void (^)(NSError *error))finishHandle;

/**
 把分段视频合成一个视频
 
 @param sourcePathArray 源视频地址
 @param audioUrl nil表示无替换音频，超过视频长度则截取，不足则循环补齐
 @param totalTimeRange 取所有文件时长的范围
 @param storePath 存储路径
 @param filters 滤镜数组
 @param stprocessing 需要使用st过滤，不需要时传nil
 @param finished 导出完成回调
 */

/*调整输出size*/
-(CGSize)adjustOutSize:(CGSize)size need720p:(BOOL)need720p;

- (void)exportAsynVideo:(NSArray <NSURL *> *)sourcePathArray
               audioUrl:(NSURL *)audioUrl totalTimeRange:(CMTimeRange)totalTimeRange storePath:(NSString *)storePath filters:(NSArray *)filters STProcessing:(NSDictionary *)stprocessing bitRate:(int)bitrate need720P:(BOOL)need720P finished:(void (^)(NSError *error))finished;

- (void)exportAsynVideoWithSetting:(NSArray <NSURL *> *)sourcePathArray
                          audioUrl:(NSURL *)audioUrl totalTimeRange:(CMTimeRange)totalTimeRange storePath:(NSString *)storePath filters:(NSArray *)filters STProcessing:(NSDictionary *)stprocessing settings:(NSDictionary *)settings finished:(void (^)(NSError *error))finished;

-(void)undoExport2;
-(void)reStartExport:(void (^)(NSError *error))finished;

@end

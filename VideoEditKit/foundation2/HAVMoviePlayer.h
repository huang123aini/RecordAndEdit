//
//  HAVMoviePlayer.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>
#import "HAVAssetItem.h"
#import "HAVAsset.h"

typedef NS_ENUM(NSInteger, HAVVideoRotation)
{
    HAVRotationInvalid = -1,
    HAVRotationDegress0 = 0,
    HAVRotationDegress90 = 1,
    HAVRotationDegress180 = 2,
    HAVRotationDegress270 = 3,
};

@interface HAVMoviePlayer : GPUImageMovie

@property (nonatomic, readonly) BOOL finished;

@property (nonatomic, assign) BOOL enableRepeat;

- (instancetype) initWithURL:(NSURL *) videoUrl audioAssetItem:(HAVAssetItem *) audioAssetItem;

- (instancetype) initWithFilePath:(NSString *) videoPath audioAssetItem:(HAVAssetItem *) audioAssetItem;

- (instancetype) initWithAssetItem:(HAVAssetItem *) item audioAssetItem:(HAVAssetItem *) audioAssetItem;

- (instancetype) initWithAssetItems:(NSArray<HAVAssetItem *> *) items audioAssetItem:(HAVAssetItem *) audioAssetItem;

- (instancetype) initWitHAVAsset:(HAVAsset *) asset;

- (instancetype) initWithHAVAssetSTPlayer:(HAVAsset *) asset;
/**
 * 设置视频静音
 **/
- (void) muted:(BOOL) mute;
/**
 * 设置背景音静音
 **/
- (void) backgroundMuted:(BOOL) mute;
/**
 * 当前播放器的时间戳 CMTime格式
 **/
- (CMTime) currentTime;
/**
 * 当前播放器的时间戳
 **/
- (CGFloat) currentTimeSeconds;
/**
 * 最后帧播放的时间戳
 **/
- (CGFloat) currentPlayTime;
/**
 * 视频的总时长
 **/
- (CGFloat) duration;

/**
 普通seek，会有精度误差，速度快
 
 @param time 毫秒
 @param completionHandler 完成回调
 */
- (void) seekTo:(NSTimeInterval) time completionHandler:(void (^)(BOOL finished))completionHandler;

/**
 高精度seek，严格按照传入时间，返回速度较慢
 
 @param time 毫秒
 @param completionHandler 完成回调
 */
- (void) seekToWithAccuracy:(NSTimeInterval) time completionHandler:(void (^)(BOOL finished))completionHandler;

/**
 获取player的原始音视频资源信息
 **/
- (AVAsset *) getAsset;
/**
 获取当前状态下的player的音视频资源信息
 **/
- (AVAsset *) getCurrentAsset;

/**
 获取用于封面截取的音视频资源信息
 **/
-(AVAsset*)getCoverAsset;

/**
 * 视频背景音的地址
 **/
- (void) setAudioURL:(NSURL *) audioUrl;
/**
 * 视频背景音的地址
 **/
- (void) setAudioFilePath:(NSString *) filePath;
/**
 * 视频背景音的音量
 **/
- (void) setAudioVolume:(CGFloat) volume;
/**
 * 视频的音量
 **/
- (void) setVideoVolume:(CGFloat) volume;
/**
 * 视频背景音播放
 **/
- (void) audioPlay;
/**
 * 视频背景音暂停
 **/
- (void) audioPause;
/**
 * 开始所有的播放行为
 **/
- (void) play;
/**
 * 停止所有的播放行为
 **/
- (void) stop;
/**
 * 暂停所有的播放行为
 **/
- (void) pause;
/**
 * 重新开始所有的播放行为
 **/
- (void) restart;
/**
 * 获取视频播放时候的长宽信息
 **/
- (CGSize) getVideoSize;
/**
 * 获取视频最小帧间隔时间
 **/
- (CMTime) frameDuration;
/**
 * 设置视频旋转信息
 **/
- (void) setVideoRotation:(HAVVideoRotation) rotation;
/**
 * 获取视频旋转信息
 **/
- (HAVVideoRotation) videoRotation;
/**
 设置播放的速率
 **/
- (void) setPlayRate:(CGFloat) rate;
/**
 设置播放的范围
 **/
- (void) setPlayTimeRange:(CMTimeRange) timeRange;
/**
 频繁调用seek接口
 **/
- (void)seekSmoothlyToTime:(CMTime)newChaseTime;

/**
 仅STPlayer支持
 
 @param pitch (-12...12)
 */
#ifdef USE_SOUND_TOUCH
- (void)setPitch:(NSInteger)pitch;
#else
- (void)setPitch:(float)pitch;
#endif
@end

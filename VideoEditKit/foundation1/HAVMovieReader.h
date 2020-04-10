//
//  HAVMovieReader.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>
#import "HAVVideoSize.h"
#import "HAVVideoExport.h"
#import "HAVPlayer.h"

typedef NS_ENUM(NSInteger, VideoRotation)
{
    Rotation0 = 0,
    Rotation90 = 1,
    Rotation180 = 2,
    Rotation270 = 3,
};

@interface HAVMovieReader : GPUImageMovie

@property (nonatomic, assign) BOOL showFirstFrame;
@property (nonatomic, assign) CGFloat rate;
@property (nonatomic, strong) AVMutableComposition *outComposition;

- (instancetype) initWithVideoItems:(NSArray *) videoItems withAudioUrl:(HAVAudioItem *) audioItem;

- (instancetype) initWithVideoItems:(NSArray <HAVVideoItem *> *) videoItems withAudioUrl:(HAVAudioItem *) audioItem timeRange:(CMTimeRange)range;

- (instancetype) initWithVideURLs:(NSArray *)urls withAudioURL:(NSURL *) url;

- (instancetype) initWithExport:(HAVVideoExport *) avexport;

//设置完速度后使用此接口调整范围
- (instancetype) initAfterSpeedWithRange:(CMTimeRange)range instance:(id)instance;

////设置完速度后使用此接口调整范围
- (instancetype) initAfterSpeedWithRange:(CMTimeRange)range instance:(id)instance handler:(void (^)(void)) handler;


- (instancetype) initWithTimeRangeSlow:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl timeRange:(CMTimeRange)range slowRatio:(NSInteger)slowRatio;

- (instancetype) initWithTimeRangeRepeat:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl timeRange:(CMTimeRange)range repeatTimes:(NSInteger)times;

- (instancetype) initWithFileTimeRange:(NSURL *)url audioUrl:(NSURL *)url withAudioTimeRange:(CMTimeRange)range;

- (instancetype) initWithPlaySpeed:(NSURL *)url speed:(CGFloat)speed;

- (instancetype) initWithRateControlAsset:(NSURL *)url;


- (AVAsset *) getAsset;

- (BOOL) finished;

- (void) setPlayLoopDelegate:(id<HAVPlayerPlayBackDelegate>) delegate;

- (void) setAudioURL:(NSURL *) audioUrl;

- (void) setAudioFilePath:(NSString *) filePath;

- (void) setAudioVolume:(CGFloat) volume;

- (void) setVideoVolume:(CGFloat) volume;

- (void) audioPlay;

- (void) audioPause;

- (void) stop;

- (void) pause;

- (void) restart;

- (CMTime) currentTime;

- (CGSize) getVideoSize;

- (CGSize) getFixedVideoSize;

- (CMTime) frameDuration;

- (void) seek:(NSTimeInterval) time;

- (void) seekToTime:(NSTimeInterval) time;

- (void) seekPause:(NSTimeInterval) time;

- (void) showFrameAtTime:(NSTimeInterval) time;

- (void) setLoopEnable:(BOOL) loop;

- (void) saveVideoToPath:(NSString *) path withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler;

- (void) saveVideoToPath:(NSString *) path videoSize:(HAVVideoSize) videoSize withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler;

- (void) saveVideoToPath:(NSString *) path bitRate:(NSInteger) bitRate withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler;

- (void) saveVideoToPathWithIFrame:(NSString *) outPath bitRate:(NSInteger) bitRate withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler;

- (void) saveVideoToPathWithIFrame:(NSString *) outPath bitRate:(NSInteger) bitRate videoSize:(HAVVideoSize) videoSize withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler;

- (void) saveVideoToPathWithIFrame:(NSString *) outPath withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler;

- (void) saveVideoToPath:(NSString *) outPath bitRate:(NSInteger) bitRate videoSize:(HAVVideoSize) videoSize withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler;


//频繁调用seek接口
- (void)seekSmoothlyToTime:(CMTime)newChaseTime;

//时间范围
- (void)saveFileAfterTimeEffect:(NSURL *)savePath withVideoSize:(HAVVideoSize)vsize completion:(void (^)(NSError *err))completion;

//- (void) saveFileAfterTimeEffect2:(NSURL *)savePath withVideoSize:(HAVVideoSize)vsize bitRate:(NSUInteger)bitRate forceFramerate:(BOOL)flag completion:(void (^)(NSError *err))completion;

- (void) saveFileAfterTimeEffect:(NSURL *)savePath withVideoSize:(HAVVideoSize)vsize bitRate:(NSUInteger)bitRate metaData:(NSString*) metaData forceFramerate:(BOOL)flag completion:(void (^)(NSError *err))completion;

//滤镜+时间范围
- (void) saveVideoWithTimeEffect:(NSString *) outPath bitRate:(NSInteger) bitRate withFilters:(NSArray *) filters withHandler:(void (^) (BOOL status,NSString *path, NSError *error)) handler;

- (void) muted:(BOOL) mute;

- (CGFloat) currentTimeSeconds;

- (CGFloat) currentPlayTime;

- (CGFloat) duration;

- (void) setVideoRotation:(VideoRotation) rotation;

- (VideoRotation) videoRotation;

- (void) showFrameAtTime:(NSTimeInterval) time completionHandler:(void (^)(BOOL finished))completionHandler;

//优化特效页面非关键帧拖动精准度
- (void)showSampleAtTime:(NSTimeInterval)time;

- (void)seekAudioSampleAtTime:(NSTimeInterval)time;

@end

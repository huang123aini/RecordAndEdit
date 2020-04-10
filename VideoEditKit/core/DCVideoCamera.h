//
//  DCVideoCamera.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>

@protocol BackgroundPlayStatusDelegate <NSObject>

- (void) backgroundPlayEnd;
- (void) backgroundDecodeError;

@end

@interface DCVideoCamera : GPUImageStillCamera

@property (nonatomic, assign) CGFloat cameraZoom;

@property (nonatomic, weak) id<BackgroundPlayStatusDelegate> playStatusDelegate;

- (instancetype) initWithAudioUrl:(NSURL *) url;

- (instancetype) initWithAudioLocalPath:(NSString *) localPath;

- (instancetype) initWithPreset:(NSString *)sessionPreset;

- (void) stopCapture;

- (void) startCapture;

- (void) setAduioUrl:(NSURL *) url;

- (void) setAduioLocalPath:(NSString *) localPath;

- (void) setFrameRate:(int32_t)frameRate;

- (void) turnFlashOn: (bool) on ;

- (void) frontCamera:(BOOL) isFront;

- (void) stopBackground;

- (void) pauseBackground;

- (void) playBackground;

- (void) playPreviousBackground;

- (NSTimeInterval) currentTime;

- (NSTimeInterval) currentPlayTime;

- (void) setAudioLoopCount:(NSInteger) loopCount;

- (void) playBackgroundAtTime:(NSTimeInterval) time;

- (void) setPlayRate:(CGFloat) rate;

- (void) setFocusAtPoint:(CGPoint) point previewSize:(CGSize)size;

- (void) faceFocusAtPoint:(CGPoint) point previewSize:(CGSize)size;

- (BOOL)canSupportFlashOn;

@end

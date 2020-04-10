//
//  HAVMovieFileReader.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HAVDataSourceDelegate.h"

@protocol HAVMoviePlayFinishDelegate <NSObject>

@required

- (void) HAVMoviePlayFinish;

@end

@interface HAVMovieFileReader:NSObject<HAVDataSourceDelegate>

@property (nonatomic, assign) BOOL loopEnable;
@property (nonatomic, assign) BOOL isInPreview;
@property (nonatomic, assign) BOOL isInCountDown;
@property (nonatomic, assign) id<HAVMoviePlayFinishDelegate> delegate;

- (void) pause;

- (void) start;

- (void) playMute;

- (NSTimeInterval) duration;

- (void) startWithAudio:(BOOL)flag;

- (void) startWithAudio:(BOOL)flag  duration:(CMTime)duration;

- (void) replay;

- (void) replayWithAudio:(BOOL)flag;

- (void) playWithRate:(CGFloat) rate;

- (void) seekToTime:(NSTimeInterval) time;

- (void) seekToTime:(NSTimeInterval) time withBlock:(void(^)(NSTimeInterval time)) block;

- (instancetype) initWithUrl:(NSURL *) path;
- (instancetype) initWithPath:(NSString *) path;
- (instancetype) initWithAsset:(AVAsset *)asset;

- (NSTimeInterval) currentTime;

- (void) setWriteFile:(BOOL) writeFile;

- (CVPixelBufferRef) copyFrameAt3XSpeed:(CMTime)itemTime;

-(void)setHasExport:(BOOL)hasExport;

@end

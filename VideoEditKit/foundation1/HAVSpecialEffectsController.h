//
//  HAVSpecialEffectsController.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUKit/GPUKit.h>
#import "HAVGPUImageFilterManager.h"
#import "HAVVideoSize.h"

@class HAVSpecialEffectsView;

@interface HAVSpecialEffectsController : NSObject

@property (nonatomic, assign) BOOL supportGhost;

@property (nonatomic, strong, readonly) HAVGPUImageFilterManager *filterManager;

- (void) setSpecialEffectsView:(HAVSpecialEffectsView *)view;

- (void) setPreViewDataSource:(GPUImageOutput*) previewDataSource;

- (void) changeGPUPipeline;

- (void) setPlayRate:(CGFloat) rate;

- (void) setFps:(int) fps;

- (void) startGhost;
- (void) clearGhost;

- (void) stopGhost;

- (void) setIsBattle:(BOOL)isBattle;
- (void) setGhostImage:(UIImage *) image;
- (UIImage *) getCurrentGhostImage;

- (void) getCurrentGhostImage:(void (^) (UIImage *)) hander;

-(double)getCurrentSectionTime;



- (void) saveVideoToFile:(NSString *) localPath bitRate:(NSInteger) bitRate warterMark:(GPUImageWritterWaterMark *) waterMark;

- (void) saveVideoToFileWithOutAudio:(NSString *) localPath bitRate:(NSInteger) bitRate warterMark:(GPUImageWritterWaterMark *) waterMark;

- (void) stopSaveFile;

- (void) saveVideoToPath:(NSString *)outPath withHandler:(void (^) (BOOL status, NSString *outPath, NSError *error))handler;

- (void) saveVideoToPath:(NSString *)outPath videoSize:(HAVVideoSize) avVideoSize withHandler:(void (^) (BOOL status, NSString *outPath, NSError *error))handler;

- (void) exportVideo:(NSString *)outPath bitRate:(NSInteger) bitRate videoRequestSize:(HAVVideoSize)videoRequestSize metaData:(NSString *) metaData withHandler:(void (^) (BOOL status, NSString *outPath, NSError *error))handler;

- (void) saveVideoTo2File:(NSString *) nonKeyPath keyPath:(NSString *)keyPath nonKeyRate:(NSInteger) bitRate keyRate:(NSInteger)bitrate2 warterMark:(GPUImageWritterWaterMark *)waterMark useOriginalAudio:(BOOL)use;

- (void)stopSave2File;

@end


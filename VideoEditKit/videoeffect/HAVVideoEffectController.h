//
//  HAVVideoEffectController.h
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVSpliteFilterController.h"
#import "DCSpecialEffectsView.h"
#import "HAVVideoEffectFilterController.h"
#import "HAVParticleFilterController.h"
#import "HAVMovieReader.h"

@interface HAVVideoEffectController : NSObject

@property (nonatomic, strong) HAVMovieReader *movieReader;
@property (nonatomic, strong) HAVMovieFileReader *fileReader;

- (instancetype) init;

- (void) createVideoEffect;

- (void) destoryVideoEffect;

- (void) reset;

- (void) clear;

- (void) back;

- (void) play;

- (void) stop;

- (CGFloat) currentTime;

- (void) changeGPUPipeline;

- (void) seek:(NSTimeInterval) time;

- (void) seekToTime:(NSTimeInterval) time ;

- (void) showFrameAtTime:(NSTimeInterval) time;

- (void) showFrameAtTime2:(NSTimeInterval) time;

- (void) setEffectId:(int)effectId;

- (NSData*) getSoulImage;

-(void)setSoulImage:(NSData*)imageData;

-(void)setSoulInfoss:(NSArray*)array;

- (NSArray *) archiver;

- (void) unArchiver:(NSArray *) array;

- (void) setSpecialEffectsView:(DCSpecialEffectsView *)view;

- (void) setPreViewDataSource:(GPUImageOutput*) previewDataSource ;

- (void) setPreViewDataSource:(GPUImageOutput*) previewDataSource showFirstFrame:(BOOL) showFirstFrame;

- (void) exportEffectVideo:(NSString *) outPath bitRate:(NSInteger) bitRate withHandler:(void(^)(BOOL status , NSString *path, NSError * error))handler;

- (void) exportEffectVideo2:(NSString *)outPath bitRate:(NSInteger) bitRate videoRequestSize:(HAVVideoSize)videoRequestSize metaData:(NSString *) metaData useSpliteFilter:(BOOL)use withHandler:(void (^) (BOOL status, NSString *outPath, NSError *error))handler;

- (void) exportEffectVideoWithSpliteFilter:(NSString *) outPath bitRate:(NSInteger) bitRate withHandler:(void(^)(BOOL status , NSString *path, NSError * error))handler;

- (void) setReverse:(BOOL) reverse;

- (void) addSpliteFilterController:(HAVSpliteFilterController *)controller;

- (void) resetFileReader;

- (void) saveFileAfterTimeEffect:(NSURL *)savePath withVideoSize:(HAVVideoSize)vsize bitRate:(NSUInteger)bitRate metaData:(NSString*) metaData forceFramerate:(BOOL)flag completion:(void (^)(NSError *err))completion;


- (void) createMagicFinger;

- (void) destoryMagicFinger;

- (void) magicStop;

- (void) magicBack;

- (void) magicReset;

- (NSArray *) magicArchiver;

- (void) removeAllMagic;

- (void) magicUnarchiver:(NSArray *) array;

/**
 ** position 范围 0.0 ~ 1.0
 **/

- (void) changeSourcePosition:(CGPoint) position;

/**
 ** position 范围 0.0 ~ 1.0
 **/

- (void) addParticle:(NSString *) file atPosition:(CGPoint) point;

/**
 ** position 范围 0.0 ~ 1.0
 **/

- (void) addParticles:(NSArray *) files atPosition:(CGPoint) point;

- (HAVParticleFilterController*) currentParticleFilterController;

@end

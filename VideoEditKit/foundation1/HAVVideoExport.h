//
//  HAVVideoExport.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVAudioItem.h"
#import "HAVVideoItem.h"

#import "HAVVideoSize.h"
#import <Foundation/Foundation.h>

typedef enum ExportAudioFileType{
    ExportAudioFileNormal,
    ExportAudioFileMultiple
}ExportAudioFileType;

@interface ExportHandler : NSObject

-(void) cancel;

@end

@interface HAVVideoExport : NSObject

@property (nonatomic, strong, readonly) AVAsset *asset;
@property (nonatomic, assign, readonly) HAVVideoSize videoSize;

- (CGSize) getVideoSize;

+ (void) exportVideo:(NSString *)outpath videoSize:(HAVVideoSize) avVideoSize withVideoItems:(NSArray *) videoItems withAudioUrl:(HAVAudioItem *) assetItem withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler;

+ (HAVVideoExport *) createVideoAssetWithSize:(HAVVideoSize) avVideoSize withVideoItems:(NSArray *) videoItems withAudioUrl:(HAVAudioItem *) assetItem;

+ (ExportHandler *) exportiFrameVideo:(NSString *)outpath videoSize:(HAVVideoSize)  avVideoSize bitRate:(NSInteger) bitRate withVideoItems:(NSArray *) videoItems withAudioUrl:(HAVAudioItem *) assetItem withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler;


+ (ExportHandler *) exportVideo:(NSString *)outpath videoSize:(HAVVideoSize)  avVideoSize bitRate:(NSInteger) bitRate withVideoItems:(NSArray *) videoItems withAudioUrl:(HAVAudioItem *) assetItem withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler;


+ (ExportHandler *) exportKeyFrameVideo:(NSString *) outPath videoSize:(HAVVideoSize) avVideoSize withVideoPath:(NSString *) localpath withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler;

+ (ExportHandler *) exportKeyFrameVideo2:(NSString *) outPath videoSize:(HAVVideoSize) avVideoSize withVideoPath:(NSString *) localpath bitRate:(NSInteger) bitRate withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler;

+ (ExportHandler *) exportVideo:(NSString *)outpath videoSize:(HAVVideoSize)  avVideoSize bitRate:(NSInteger) bitRate withVideoItems:(NSArray *) videoItems  withMovieFile:(HAVVideoItem *) audioSource isBattlePreview:(BOOL)isPreview withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler;

+ (ExportHandler *) exportiFrameVideo:(NSString *)outpath videoSize:(HAVVideoSize)  avVideoSize bitRate:(NSInteger) bitRate withVideoItems:(NSArray *) videoItems  withMovieFile:(HAVVideoItem *) audioSource isBattlePreview:(BOOL)isPreview withHandler:(void (^) (BOOL status, NSString *path, NSError *error)) handler;

+ (void) exportIReversedFile:(NSURL *)url outPath:(NSURL *)outPath completion:(void (^)(NSError *error))completion;

+ (void) exportAudioFileWithNeededTime:(NSURL *)audioUrl output:(NSString *)outputPath dstDuration:(CMTime)dstDuration type:(ExportAudioFileType)type completion:(void (^)(NSError *error))completion;

+ (void)reverseAnyVideo:(NSString *)sourceUrl outputURL:(NSString *)outputURL videoSize:(HAVVideoSize)avVideoSize progressHandle:(void (^)(CGFloat progress))progressHandle cancle:(BOOL *)cancle finishHandle:(void (^)(BOOL flag, NSError *error))finishHandle;
@end

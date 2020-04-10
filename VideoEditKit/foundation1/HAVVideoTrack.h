//
//  HAVVideoTrack.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "HAVVideoSize.h"

@interface HAVVideoTrack : NSObject

@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, assign) CGFloat rate;

- (CMTime) duration;
- (CGSize) naturalSize;
- (void) addVideoAsset:(NSURL *) assetUrl;
- (void) addVideoLocalPath:(NSString *) videoPath;
- (NSString *) videoSizePreset;
- (NSArray *) getAudioMixInputParameters;
- (NSString *) videoSizeToPreset:(HAVVideoSize) videoSize;
/** 把多分段的视频加入到一个视频轨道和多个音频轨道中去**/
- (void) setVolume:(CGFloat)volume atIndex:(NSInteger) index;
- (void) addToComposition:(AVMutableComposition *)composition ;

@end

//
//  HAVAudioTrack.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface HAVAudioTrack : NSObject

@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, assign) CGFloat rate;

- (CMTime) duration;
- (void) setAudioLocalPath:(NSString *) path;
- (void) setAudioAssetUrl:(NSURL *) audioAsset;

/** 新建一个音轨并把音频数据填充到音轨里面，并设定一下混音的声音大小参数**/

- (AVMutableAudioMixInputParameters *) createAudioMixInputParameters:(AVMutableComposition *)composition;

- (AVMutableAudioMixInputParameters *) createAudioMixInputParameters:(AVMutableComposition *)composition atOffsetTime:(CMTime) offset ;

+ (AVMutableAudioMixInputParameters *) createAudioMixInputParameters:(AVMutableComposition *)composition audioAsset:(AVURLAsset *) audioAsset volume :(CGFloat) volume atOffsetTime:(CMTime) offset;

@end

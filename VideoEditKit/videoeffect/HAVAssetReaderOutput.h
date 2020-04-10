//
//  HAVAssetReaderOutput.h
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HAVAssetReaderOutput : AVAssetReaderTrackOutput

- (CVPixelBufferRef) copyPixelBufferForItemTime:(CMTime) time;

@end

NS_ASSUME_NONNULL_END

//
//  HAVPlayerItem.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface HAVPlayerItem : AVPlayerItem

- (instancetype) initWithAsset:(AVAsset *)asset;

- (instancetype) initWithVideoURL:(NSArray *)videoURLs;

- (instancetype) initWithVideoItem:(NSArray *)videoItem audioUrl:(NSURL *) url;

- (AVAsset *) getAsset;

@end

//
//  HAVMutiTracksPlayerItem.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface HAVMutiTracksPlayerItem : AVPlayerItem

- (instancetype) initWithVideoURL:(NSArray *)videoURLs WithAudioURL:(NSArray *) audioURLs;

- (void) setAudioVolume:(CGFloat) volume atIndex:(NSInteger) index;

- (void) setVideoVolume:(CGFloat) volume atIndex:(NSInteger) index;


@end

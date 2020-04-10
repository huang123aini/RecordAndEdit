//
//  HAVSynthesis.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVVideoTrack.h"
#import "HAVAudioTrack.h"

@interface HAVSynthesis : NSObject

@property (nonatomic, assign) NSInteger videoSize;
@property (nonatomic, assign) NSInteger avAlignment;

- (void) addAudioTrack:(HAVAudioTrack*)audioTrack;

- (void) setVideoTrack:(HAVVideoTrack*)audioTrack;

- (void) exportVideo:(NSString *) outpath handler:(void (^) (BOOL status,NSString *path, NSError *error)) handler;


@end

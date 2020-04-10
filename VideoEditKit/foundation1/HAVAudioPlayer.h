//
//  HAVAudioPlayer.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HAVAudioPlayer : NSObject

- (instancetype) initWithUrl:(NSURL *) url;

- (instancetype) initWithLocalPath:(NSString *) localPath;

- (void) setUrl:(NSURL *) url;

- (BOOL) play;

- (void) pause;

- (void) reset;

- (void) replay;

- (void) seek:(NSTimeInterval) time;

- (void) stop;


@end

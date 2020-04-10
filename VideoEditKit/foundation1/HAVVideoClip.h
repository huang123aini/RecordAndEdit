//
//  HAVVideoClip.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface HAVVideoClip : NSObject

@property (nonatomic, assign) BOOL isMute;
@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, assign) CGFloat startTime; // 单位为秒
@property (nonatomic, assign) CGFloat duration; // 单位为秒
@property (nonatomic, assign) NSInteger videoSize;
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, assign) CGFloat rate;
@property (nonatomic, assign) NSInteger avAlignment;

- (void) clipVideo:(NSString *) outpath handler:(void (^) (BOOL status ,NSString *path, NSError *error)) handler;

@end

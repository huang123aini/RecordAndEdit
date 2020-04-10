//
//  HAVVideoTrackItem.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface HAVVideoTrackItem : NSObject

@property (nonatomic, assign) CMTime repeatStarttime;
@property (nonatomic, assign) CMTime repeatEndTime;
@property (nonatomic, assign) NSInteger repeatCount;

- (CMTimeRange) getRepeatTimeRange;

@end

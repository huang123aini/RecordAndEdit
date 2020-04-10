//
//  HAVVideoTrackItem.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVVideoTrackItem.h"

@interface  HAVVideoTrackItem()

@property (nonatomic, strong) AVURLAsset *videoAsset;

@end

@implementation HAVVideoTrackItem


- (CMTimeRange) getRepeatTimeRange
{
    return  CMTimeRangeMake(self.repeatStarttime, self.repeatEndTime);
}

@end

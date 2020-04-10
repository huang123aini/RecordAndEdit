//
//  HAVVideoItem.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface HAVVideoItem : NSObject

- (instancetype) initWithPath:(NSString*) path;
- (instancetype) initWithUrl:(NSURL *) videoUrl;

- (void) setDuration:(NSTimeInterval) timeInterval;

- (AVAsset *) getVideoAsset;

@property (nonatomic ,readonly) CGFloat rate;
@property (nonatomic ,assign) CGFloat volume;
@property (nonatomic ,assign) CMTime scaledDuration;

@end

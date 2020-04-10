//
//  HAVAssetItem.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HAVAssetItem : NSObject

@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, assign) CMTime scaledDuration;
@property (nonatomic, assign) CMTimeRange timeRange;
@property (nonatomic, readonly) CGFloat rate;

- (instancetype) initWithURL:(NSURL *) url;

- (instancetype) initWithPath:(NSString *) path;

- (void) setRate:(CGFloat) rate;

- (void) setDuration:(NSTimeInterval) timeInterval;

- (AVAsset *) getAsset;
- (AVAsset *) getCurrentAsset;

@end

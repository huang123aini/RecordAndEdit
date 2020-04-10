//
//  HAVAsset.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "HAVAssetItem.h"

@interface HAVAsset : NSObject

@property (nonatomic, strong) NSString *url;

- (instancetype) initWithAssetItem:(HAVAssetItem *) item audioAssetItem:(HAVAssetItem *) audioAssetItem;

- (instancetype) initWithAssetItems:(NSArray<HAVAssetItem *>*) items audioAssetItem:(HAVAssetItem *) audioAssetItem;

- (void) reset;

- (AVAsset *) asset;

- (AVAsset *) currentAsset;

-(AVAsset*)coverAsset;
- (void) setRate:(CGFloat) rate;

- (void) setTimeRange:(CMTimeRange) timeRange;

@end

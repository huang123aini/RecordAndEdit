//
//  HAVVideoEffectManager.h
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVVideoEffect.h"
@interface HAVVideoEffectManager : NSObject

@property (nonatomic, assign) int  frameCount;

- (instancetype) init;

- (void) removeLastVideoEffect;

- (NSArray*) allVideoEffect;

- (void) resetTimeInterval;

- (void) addVideoEffect:(HAVVideoEffect *) effect;

- (void) removeVideoEffect:(HAVVideoEffect *) effect;

- (void) removeAllVideoEffect;

- (HAVVideoEffect*) getCurrentEffect:(Float64) frameIndex;

- (NSArray *) archiver;

@end

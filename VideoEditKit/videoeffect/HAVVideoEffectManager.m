//
//  HAVVideoEffectManager.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVVideoEffectManager.h"
@interface HAVVideoEffectManager()

@property (nonatomic, strong) NSMutableArray *videoEffects;

@end

@implementation HAVVideoEffectManager

- (instancetype) init{
    self = [super init];
    if(self){
        self.videoEffects = [NSMutableArray array];
        self.frameCount = 0;
    }
    return self;
}

- (void) addVideoEffect:(HAVVideoEffect *) effect{
    [self.videoEffects addObject:effect];
}

- (void) removeVideoEffect:(HAVVideoEffect *) effect{
     [self.videoEffects removeObject:effect];
}

- (void) removeLastVideoEffect{
    [self.videoEffects removeLastObject];
}

- (void) removeAllVideoEffect{
    [self.videoEffects removeAllObjects];
}

- (HAVVideoEffect*) getCurrentEffect:(Float64) frameTime{
    if(self.videoEffects.count > 0){
        for (NSInteger i = self.videoEffects.count - 1; i>=0 ;i--){
            HAVVideoEffect * videoEffect = [self.videoEffects objectAtIndex:i];
            if((videoEffect.startFrameTime <= frameTime )&&(videoEffect.endFrameTime >= frameTime)){
                return videoEffect;
            }
        }
    }
    return nil;
}

- (NSArray*) allVideoEffect{
    return self.videoEffects;
}

- (void) resetTimeInterval{
    for (HAVVideoEffect * videoEffect in self.videoEffects){
        videoEffect.timeInterval = 0.0f;
    }
}

- (NSArray *) archiver{
    NSMutableArray *array = [NSMutableArray array];
    for (HAVVideoEffect * videoEffect in self.videoEffects){
        NSData  *data = [NSKeyedArchiver archivedDataWithRootObject:videoEffect];
        [array addObject:data];
    }
    return array;
}

@end

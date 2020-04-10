//
//  HAVVideoEffectFilterController.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVVideoEffectFilterController.h"
#import "HAVVideoEffectFilter.h"
@interface HAVVideoEffectFilterController()

@end

@implementation HAVVideoEffectFilterController

@synthesize enableFaceTrack = _enableFaceTrack;
@synthesize filters = _filters;
@synthesize priority = _priority;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.filters = [NSMutableArray array];
        [self addFilter];
    }
    return self;
}

-(void)setSoulImage:(UIImage*)soulImage
{
    for (HAVVideoEffectFilter *effectFilter in self.filters)
    {
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]])
        {
            [effectFilter setSoulImage:soulImage];
        }
    }
}

-(void) setSoulInfoss:(NSArray*)array
{
    for (HAVVideoEffectFilter *effectFilter in self.filters)
    {
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]])
        {
            [effectFilter setSoulInfoss:array];
        }
    }
}


- (HAVVideoEffectFilter *)addFilter
{
    HAVVideoEffectFilter *effectFilter = [[HAVVideoEffectFilter alloc] init];
    self.enableFaceTrack = NO;
    if (effectFilter != nil) {
        [self.filters addObject:effectFilter];
    }
    return effectFilter;
}

- (void)dealloc{
    
}

- (Float64) currentFrameTime{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            return [effectFilter currentFrameTime];
        }
    }
    return 0;
}

- (void) reset{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            [effectFilter reset];
        }
    }
}

- (void) clear {
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            [effectFilter clearVideoEffects];
        }
    }
}

- (void) setVideoEffectID:(int) effectId{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            [effectFilter setVideoEffectID:effectId];
        }
    }
}


- (void) changeVideoEffectID:(int) effectId{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            [effectFilter changeVideoEffectID:effectId];
        }
    }
}

- (void) remove{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            [effectFilter remove];
        }
    }
}

- (void) seekToTime:(Float64) frameTime{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            [effectFilter seekToTime:frameTime];
        }
    }
}

- (void) back{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            [effectFilter back];
        }
    }
}

- (NSArray *) archiver{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            return [effectFilter archiver];
        }
    }
    return nil;
}

- (void) unArchiver:(NSArray *) array{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            return [effectFilter unArchiver: array];
        }
    }
}

- (void) setReverse:(BOOL) reverse{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            return [effectFilter setReverse: reverse];
        }
    }
}

- (void) setDuration:(CGFloat)duration{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            return [effectFilter setDuration:duration];
        }
    }
}

- (void) stopCurrentEffect{
    for (HAVVideoEffectFilter *effectFilter in self.filters){
        if([effectFilter isKindOfClass:[HAVVideoEffectFilter class]]){
            return [effectFilter stopCurrentEffect];
        }
    }
}

@end

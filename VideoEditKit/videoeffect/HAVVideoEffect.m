//
//  HAVVideoEffect.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVVideoEffect.h"

@implementation HAVVideoEffect

- (instancetype) init
{
    self = [super init];
    if(self){
        _videoEffectId = 0.0f;
        _startFrameTime = 0.0f;
        _endFrameTime = 0.0f;
        _program = nil;
        _timeInterval = 0.0f;
        _reversed = NO;
    }
    return self;
}

- (void) setProgram:(GLProgram *)program
{
    _program = program;
    self.mGlobalTime = [_program uniformIndex:@"iGlobalTime"];
    self.iResolution = [_program uniformIndex:@"iResolution"];
}

-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:self.videoEffectId forKey:@"videoEffectId"];
    [aCoder encodeFloat:self.startFrameTime forKey:@"startFrameTime"];
    [aCoder encodeFloat:self.endFrameTime forKey:@"endFrameTime"];
    [aCoder encodeFloat:self.timeInterval forKey:@"timeInterval"];
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    if (self=[super init]){
        self.videoEffectId = [aDecoder decodeIntForKey:@"videoEffectId"];
        self.startFrameTime = [aDecoder decodeFloatForKey:@"startFrameTime"];
        self.endFrameTime = [aDecoder decodeFloatForKey:@"endFrameTime"];
        self.timeInterval = [aDecoder decodeFloatForKey:@"timeInterval"];
    }
    return self;
}

@end

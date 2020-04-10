//
//  HAVParticleFilterController.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVParticleFilterController.h"
#import "HAVParticleFilter.h"

@implementation HAVParticleFilterController
@synthesize enableFaceTrack = _enableFaceTrack;
@synthesize filters = _filters;
@synthesize priority = _priority;

- (instancetype) init{
    self = [super init];
    if(self){
        self.filters = [NSMutableArray array];
        self.enableFaceTrack = NO;
        HAVParticleFilter *particleFilter = [[HAVParticleFilter alloc] init];
        if (particleFilter) {
            [self.filters addObject:particleFilter];
        }
    }
    return self;
}

- (void) changeSourcePosition:(CGPoint) position{
    for (HAVParticleFilter *paritcleFilter in self.filters){
        if([paritcleFilter isKindOfClass:[HAVParticleFilter class]]){
            [paritcleFilter changeSourcePosition:position];
        }
    }
}

- (void) addParticle:(NSString *) file atPosition:(CGPoint) point{
    for (HAVParticleFilter *paritcleFilter in self.filters){
        if([paritcleFilter isKindOfClass:[HAVParticleFilter class]]){
            [paritcleFilter addParticle:file atPosition:point];
        }
    }
}

- (void) addParticles:(NSArray *) files atPosition:(CGPoint) point{
    for (HAVParticleFilter *paritcleFilter in self.filters){
        if([paritcleFilter isKindOfClass:[HAVParticleFilter class]]){
            [paritcleFilter addParticles:files atPosition:point];
        }
    }
}

- (void) stop{
    for (HAVParticleFilter *paritcleFilter in self.filters){
        if([paritcleFilter isKindOfClass:[HAVParticleFilter class]]){
            [paritcleFilter stop];
        }
    }
}

- (void) back {
    for (HAVParticleFilter *paritcleFilter in self.filters){
        if([paritcleFilter isKindOfClass:[HAVParticleFilter class]]){
            [paritcleFilter back];
        }
    }
}

- (void) removeAllMagic{
    for (HAVParticleFilter *paritcleFilter in self.filters){
        if([paritcleFilter isKindOfClass:[HAVParticleFilter class]]){
            [paritcleFilter removeAllMagic];
        }
    }
}

- (NSArray *) archiver{
    for (HAVParticleFilter *paritcleFilter in self.filters){
        if([paritcleFilter isKindOfClass:[HAVParticleFilter class]]){
            //  return [paritcleFilter archiver];
        }
    }
    return nil;
}

- (void) unarchiver:(NSArray *) array{
    for (HAVParticleFilter *paritcleFilter in self.filters){
        if([paritcleFilter isKindOfClass:[HAVParticleFilter class]]){
            //    [paritcleFilter unarchiver: array];
        }
    }
}

- (void) reset{
    for (HAVParticleFilter *paritcleFilter in self.filters){
        if([paritcleFilter isKindOfClass:[HAVParticleFilter class]]){
            [paritcleFilter reset];
        }
    }
}
@end

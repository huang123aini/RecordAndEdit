//
//  HGPUBeautyFilterController.m
//  QAVKit
//
//  Created by 黄世平 on 2019/1/22.
//  Copyright © 2019 guowei. All rights reserved.
//

#import "HGPUBeautyFilterController.h"
#import "HGPUBeauty.h"

@interface HGPUBeautyFilterController ()

@property (nonatomic, strong) HGPUBeauty* beautyFilter;

@end

@implementation HGPUBeautyFilterController

@synthesize enableFaceTrack = _enableFaceTrack;
@synthesize filters = _filters;
@synthesize priority = _priority;

-(instancetype)init
{
    if (self = [super init])
    {
        self.enableFaceTrack = YES;
        
        self.beautyFilter = [[HGPUBeauty alloc] init];
        self.filters = [NSMutableArray array];
        if (self.beautyFilter)
        {
            [self.filters addObject:self.beautyFilter];
        }
    }
    return self;
}


-(void)setSmoothValue:(float)value
{
    if (value > 1.f || value < 0.f)
    {
        return;
    }
    [self.beautyFilter setSmoothing:value];
}
-(void)setRedValue:(float)value
{
    if (value > 1.f || value < 0.f)
    {
        return;
    }
    [self.beautyFilter setReddening:value];
}
-(void)setWhitenValue:(float)value
{
    if (value > 1.f || value < 0.f)
    {
        return;
    }
    [self.beautyFilter setWhitening:value];
}

@end

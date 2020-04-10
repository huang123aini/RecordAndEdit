//
//  HAVLutImageFilterController.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVLutImageFilterController.h"
#import "HAVLutImageFilter.h"
#import "HAVGPUImageLutFilter.h"
#import "HAVGPULightLutFilter.h"

@interface HAVLutImageFilterController ()

@property (nonatomic, copy) NSString *auxImageName;

@end

@implementation HAVLutImageFilterController

@synthesize enableFaceTrack = _enableFaceTrack;
@synthesize filters = _filters;
@synthesize priority = _priority;

- (instancetype)initWithAuxImageName:(NSString *)imageName withType:(FILTERTYPE)type
{
    self = [super init];
    if (self) {
        self.auxImageName = imageName;
        self.filters = [NSMutableArray array];
        self.enableFaceTrack = NO;
        [self addAuxFilter:type];
    }
    return self;
}

- (GPUImageFilter *)addAuxFilter:(FILTERTYPE) type
{
    GPUImageFilter *auxFilter = nil;
    if(type == FILTERTYPE_4X4)
    {
        auxFilter = [[HAVLutImageFilter alloc] initWithImageName:self.auxImageName];
    }else if(type == FILTERTYPE_8X8)
    {
        auxFilter = [[HAVGPUImageLutFilter alloc] initWithImageName:self.auxImageName];
    }else if(type == FILTERTYPE_Light)
    {
        auxFilter = [[HAVGPULightLutFilter alloc] initWithImageName:self.auxImageName];
    }
    if (auxFilter) {
        [self.filters addObject:auxFilter];
    }
    return auxFilter;
}

- (void)dealloc{
    for (HAVLutImageFilter *auxFilter in self.filters){
        if([auxFilter isKindOfClass:[HAVLutImageFilter class]]){
            [auxFilter releaseFilter];
        }
        if([auxFilter isKindOfClass:[HAVGPUImageLutFilter class]]){
            HAVGPUImageLutFilter *filter = (HAVGPUImageLutFilter*)auxFilter;
            [filter releaseFilter];
        }
        if([auxFilter isKindOfClass:[HAVGPULightLutFilter class]]){
            HAVGPULightLutFilter *filter = (HAVGPULightLutFilter*)auxFilter;
            [filter releaseFilter];
        }
    }
}

@end

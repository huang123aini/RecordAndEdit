//
//  HCutOutFilterController.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/13.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HCutOutFilterController.h"
#import "HCutOutFilter.h"
@interface HCutOutFilterController ()

@property (nonatomic, strong) HCutOutFilter* cutoutFilter;

@end

@implementation HCutOutFilterController

@synthesize enableFaceTrack = _enableFaceTrack;
@synthesize filters = _filters;
@synthesize priority = _priority;

-(instancetype)init
{
    if (self = [super init])
    {
        self.enableFaceTrack = YES;
        self.cutoutFilter = [[HCutOutFilter alloc] init];
        self.filters = [NSMutableArray array];
        if (self.cutoutFilter) {
            [self.filters addObject:self.cutoutFilter];
        }
    }
    return self;
}
@end

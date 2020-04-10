//
//  HAVSpliteFilterController.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.

#import "HAVSpliteFilterController.h"

@interface HAVSpliteFilterController ()
{
    id ds;
}

@end

@implementation HAVSpliteFilterController

@synthesize enableFaceTrack = _enableFaceTrack;
@synthesize filters = _filters;
@synthesize priority = _priority;
- (instancetype) initWithDataSource:(id<HAVDataSourceDelegate>) dataSource
{
    self = [super init];
    if (self)
    {
        ds = dataSource;
        self.filters = [NSMutableArray array];
        [self addFilter:dataSource];
    }
    return self;
}

- (void) setShowOnly:(BOOL)showOnly
{
    for (GPUImageFilter *filter in self.filters)
    {
        filter.showOnly = showOnly;
    }
}

- (HAVSpliteFilter *)addFilter:(id<HAVDataSourceDelegate>) dataSource
{
    HAVSpliteFilter *spliteFilter = [[HAVSpliteFilter alloc] initWithDataSource:dataSource];
    
    self.spliteFilter = spliteFilter;
    self.enableFaceTrack = NO;
    if (spliteFilter != nil)
    {
        [self.filters addObject:spliteFilter];
    }
    return spliteFilter;
}

- (void) setDisplayModel:(HAVDisplayModel ) displayModel
{
    self.spliteFilter.displayModel = displayModel;
}

- (void) reset
{
    [self.spliteFilter reset];
}

- (void) setPreview:(BOOL) preview
{
    self.spliteFilter.preview = preview;
}

-(void)dealloc
{
    self.spliteFilter = nil;
}

- (HAVMovieFileReader *)fileReader
{
    return (HAVMovieFileReader *)ds;
}
@end

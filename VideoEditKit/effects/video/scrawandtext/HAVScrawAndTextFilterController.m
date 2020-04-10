//
//  HAVScrawAndTextFilterController.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVScrawAndTextFilterController.h"
#import "HAVScrawAndTextFilter.h"

@interface HAVScrawAndTextFilterController ()

@property (nonatomic, strong)HAVScrawlAndTextFilter *scrawlFilter;

@end

@implementation HAVScrawAndTextFilterController

@synthesize enableFaceTrack = _enableFaceTrack;
@synthesize filters = _filters;
@synthesize priority = _priority;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.enableFaceTrack = YES;
        self.scrawlFilter = [[HAVScrawlAndTextFilter alloc] init];
        self.scrawlFilter.disableShow = YES;
        self.filters = [NSMutableArray array];
        if (self.scrawlFilter)
        {
            [self.filters addObject:self.scrawlFilter];
        }
    }
    return self;
}
-(void)disableShow:(BOOL)isShow
{
    if (self.scrawlFilter)
    {
        self.scrawlFilter.disableShow = isShow;
    }
}

- (void)setUpdatedImage:(UIImage *)updatedImage
{
    _updatedImage = updatedImage;
    self.scrawlFilter.updatedImage = updatedImage;
}

-(void)toReset
{
    [self.scrawlFilter toReset];
}

- (void)setRotationMode:(GPUImageRotationMode)rotationMode
{
    _rotationMode = rotationMode;
    self.scrawlFilter.rotationMode = rotationMode;
}

@end

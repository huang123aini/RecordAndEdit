//
//  HAVGifFilterController.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVGifFilterController.h"
#import "HAVGifFilter.h"

@interface HAVGifFilterController ()

@property (nonatomic, strong) HAVGifFilter* gifFilter;

@end

@implementation HAVGifFilterController

@synthesize enableFaceTrack = _enableFaceTrack;
@synthesize filters = _filters;
@synthesize priority = _priority;

- (id)initWithGif:(NSArray <NSDictionary *> *)arr;{
    self = [super init];
    if (self) {
        self.enableFaceTrack = YES;
        // self.gifFilter = [[HAVLoadGifFilter alloc] initWithGif:arr];
        self.gifFilter = [[HAVGifFilter alloc] initWithGif:arr];
        //self.gifFilter.disableShow = YES;
        self.filters = [NSMutableArray array];
        if (self.gifFilter) {
            [self.filters addObject:self.gifFilter];
        }
    }
    return self;
}

-(instancetype)init
{
    if (self = [super init])
    {
        self.enableFaceTrack = YES;
        self.gifFilter = [[HAVGifFilter alloc] init];
        self.filters = [NSMutableArray array];
        if (self.gifFilter) {
            [self.filters addObject:self.gifFilter];
        }
    }
    return self;
}

/*添加Gif对象*/
-(void)addGifObj:(NSDictionary*)dic
{
    [self.gifFilter addGifObj:dic];
}

/*移除Gif对象*/
-(void)removeGifObj:(NSDictionary*)dic
{
    [self.gifFilter removeGifObj:dic];
}

- (void)setEnableGifRepeat:(BOOL)enableGifRepeat{
    _enableGifRepeat = enableGifRepeat;
    //  self.gifFilter.enableGifRepeat = enableGifRepeat;
}
@end

//
//  AVURLAsset+MetalData.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "AVURLAsset+MetalData.h"

@implementation AVURLAsset (MetalData)

-(CGSize) videoNaturalSize
{
    return [super videoNaturalSize];
}

- (CGSize) videoSize:(HAVVideoSize) videosize
{
    return [super videoSize:videosize];
}

@end

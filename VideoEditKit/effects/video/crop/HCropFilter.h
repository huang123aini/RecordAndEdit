//
//  HCropFilter.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/28.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>


@interface HCropFilter : GPUImageFilter
{
    GLfloat cropTextureCoordinates[8];
}

@property(readwrite, nonatomic) CGRect cropRegion;

- (id)initWithCropRegion:(CGRect)newCropRegion;


@end

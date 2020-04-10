//
//  HWaterMarkFilter.h
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/9.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>
#import "HWaterMark.h"
@interface HWaterMarkFilter : GPUImageFilter

- (instancetype) initWithWaterMark:(HWaterMark*)waterMark;
-(instancetype)initWithImages:(NSArray*)array pictureSize:(CGSize) size postion:(CGPoint ) point;
-(instancetype)initWithImages:(NSArray*)array pictureSize:(CGSize) size fboSize:(CGSize)fboSize  postionOffset:(CGPoint) point  orientation:(UIInterfaceOrientation)orientation;

-(void)setFps:(int)fps;

-(void)setRotation:(int)mode;

@end

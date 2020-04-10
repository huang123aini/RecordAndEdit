//
//  HWaterMark.h
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/9.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUKit/GPUKit.h>

@interface HWaterMark : NSObject

@property (nonatomic, assign) int fps;
@property (nonatomic, assign) GLint positionAttribute;
@property (nonatomic, assign) GLint textureCoordinateAttribute;
@property (nonatomic, assign) GLint inputTextureUniform;
@property (nonatomic, assign) CGSize frameBufferSize;

- (instancetype) initWithImageArray:(NSArray *) array pictureSize:(CGSize) size postion:(CGPoint ) point;

- (void) displayImage:(UIImage*)image pictureSize:(CGSize)size position:(CGPoint)point;

- (void) drawFrameAtTime:(CMTime) frameTime;

- (void) setRotation:(int)mode;

@end

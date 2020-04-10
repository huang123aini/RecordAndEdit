//
//  HWatermarkExport.h
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/9.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import "HWaterMarkFilter.h"

@interface HWatermarkExport : NSObject

@property (nonatomic, assign) float progress;

- (instancetype) initWithWaterMark:(HWaterMark *) waterMark videoUrl:(NSURL *)url;

- (instancetype) initWithWaterMarkImageFilter:(HWaterMarkFilter*)waterFilter videoUrl:(NSURL*)url;

- (void)exportWaterMarkVideo:(NSString *) outPath bitRate:(NSInteger) bitRate withHandler:(void(^)(BOOL status , NSString *path, NSError * error))handler;

-(void)cancelExport;

@end

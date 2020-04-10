//
//  HAVImageGenerator.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface HAVImageGenerator : NSObject

- (instancetype) initWithUrl:(NSURL *) url;
- (instancetype) initWithLocalPath:(NSString *) path;
- (instancetype) initWithLocalPaths:(NSArray <NSString *> *)urlArray;
- (UIImage *) generatorImage;
- (UIImage *) generatorImageAtTime:(Float64) time;

@end

//
//  HAVAudioItem.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HAVAudioItem : NSObject

@property (nonatomic, assign) CGFloat volume;

- (instancetype) initWithUrl:(NSURL *) videoUrl;
- (instancetype) initWithPath:(NSString*) path;

- (AVAsset *)getVideoAsset;

@end

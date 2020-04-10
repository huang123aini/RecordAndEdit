//
//  HAVMetadataRetreiver.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVMetadata.h"

@interface HAVMetadataRetreiver : NSObject

+ (HAVMetadata*) metadataRetreiverUrl:(NSURL *) url;
+ (HAVMetadata*) metadataRetreiver:(NSString *) path;

+ (BOOL) vaildVideo:(NSURL *) url;

+ (NSTimeInterval) audioDurationWithUrl:(NSURL *) url;
+ (NSTimeInterval) audioDurationWithPath:(NSString *) path;

@end

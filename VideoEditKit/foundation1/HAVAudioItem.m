//
//  HAVAudioItem.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVAudioItem.h"

@interface HAVAudioItem()

@property (nonatomic, strong) AVURLAsset *asset;

@end

@implementation HAVAudioItem

- (instancetype) initWithPath:(NSString*) path
{
    
    if(path.length > 0)
    {
        NSURL *url = [NSURL fileURLWithPath:path];
        return [self initWithUrl:url];
    }
    return [self init];
}

- (instancetype) initWithUrl:(NSURL *) videoUrl{
    self = [super init];
    if((self != nil) && (videoUrl != nil) ){
        self.asset = [AVURLAsset assetWithURL:videoUrl];
        self.volume = 1.0f;
    }
    return self;
}

- (AVAsset*)getVideoAsset{
    return self.asset;
}

@end

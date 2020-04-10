//
//  HAVVideoItem.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVVideoItem.h"
@interface HAVVideoItem ()

@property (nonatomic, strong) AVURLAsset *asset;

@end

@implementation HAVVideoItem

- (instancetype) initWithPath:(NSString*) path{
    
    if(path != nil){
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
        _rate = 1.0f;
        _scaledDuration = self.asset.duration;
    }
    return self;
}

- (AVAsset*)getVideoAsset{
    return self.asset;
}

- (void) setDuration:(NSTimeInterval) timeInterval{
    if((timeInterval < 61) && (timeInterval > 0)){
        CGFloat duration = CMTimeGetSeconds([self.asset duration]);
        _scaledDuration = CMTimeMake(timeInterval*1000, 1000);
        _rate = (duration / timeInterval);
    }
}

@end

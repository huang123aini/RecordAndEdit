//
//  HAVGPUImageMovieMix.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>

@interface HAVGPUImageMovieMix : GPUImageMovieComposition

- (id) initWithVideoFile:(NSString *) videoFile AudioFile:(NSString *) audioFile;

@end

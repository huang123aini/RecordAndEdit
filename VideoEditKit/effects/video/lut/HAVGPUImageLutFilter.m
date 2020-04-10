//
//  HAVGPUImageLutFilter.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVGPUImageLutFilter.h"
#import <GPUKit/GPUKit.h>

@interface HAVGPUImageLutFilter ()

@property (nonatomic, strong) GPUImagePicture* auxPicture;

@end

@implementation HAVGPUImageLutFilter

- (instancetype)init
{
    return [self initWithImageName:@""];
}

- (instancetype)initWithImageName:(NSString *)imageName
{
    if ([imageName length] == 0) {
        return nil;
    }
    
    self = [super initWithPrepareBlock:^(id obj) {
        [((HAVGPUImageLutFilter *)obj).auxPicture addTarget:obj];
    }];
    
    if (self) {
        self.auxPicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:imageName]];
        [self.auxPicture processImage];
    }
    
    return self;
}

- (void) releaseFilter{
    [self.auxPicture removeAllTargets];
    self.auxPicture = nil;
}
@end

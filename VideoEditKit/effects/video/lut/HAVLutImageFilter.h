//
//  HAVLutImageFilter.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>

@interface HAVLutImageFilter : GPUImageTwoInputFilter

@property (readwrite, nonatomic) CGFloat intensity;

- (void) releaseFilter;

- (instancetype) initWithImageName:(NSString *)imageName ;//NS_DESIGNATED_INITIALIZER;

@end

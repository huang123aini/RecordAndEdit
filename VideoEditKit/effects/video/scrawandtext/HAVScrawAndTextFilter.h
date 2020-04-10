//
//  HAVScrawAndTextFilter.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>

@interface HAVScrawlAndTextFilter : GPUImageFilter

@property (nonatomic, strong) UIImage *updatedImage;
@property (nonatomic, assign) BOOL disableShow;
@property (nonatomic, assign) GPUImageRotationMode rotationMode;
-(void)toReset;

@end

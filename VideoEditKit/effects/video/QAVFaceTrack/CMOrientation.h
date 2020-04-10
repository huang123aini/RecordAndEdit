//
//  CMOrientation.h
//  QHIVideoSDK
//
//  Created by 郭伟 on 7/2/17.
//  Copyright © 2017年 Tide. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface CMOrientation : NSObject

+ (instancetype) getInstance;

- (void) setEnable:(BOOL) enable;

- (UIInterfaceOrientation) getOrientation;

@end

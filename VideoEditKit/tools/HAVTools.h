//
//  HAVTools.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface HAVTools : NSObject

#pragma mark  ---------UI METHOD-----------
/**图片旋转方向*/
+ (UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation;


#pragma mark  ------DEBUG METHOD--------
/*获取当前时间戳*/
+(NSString*)currentTimeStamp;

/*保存日志*/
+(void)saveLogToFile;

#pragma mark  -------OPENGL ES----
/*图片生成纹理*/
+(GLuint)createTextureWithImage:(UIImage*)image;

@end

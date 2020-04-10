//
//  HAVFileManager.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HAVFileManager : NSObject

+ (NSString *) createTmpFile;
+ (NSString *) createTmpFileWithFile:(NSString *) fileName;
+ (void) removeTmpFile:(NSString*) filename;

@end

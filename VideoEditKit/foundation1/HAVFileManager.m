//
//  HAVFileManager.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVFileManager.h"

@implementation HAVFileManager

+ (NSString *) createTmpFile
{
    NSString *tmpDir = NSTemporaryDirectory();
    [NSDate timeIntervalSinceReferenceDate];
    return [tmpDir stringByAppendingPathComponent:@""];
}

+ (NSString *) createTmpFileWithFile:(NSString *) fileName
{
    if(fileName != nil)
    {
        NSString *tmpDir = NSTemporaryDirectory();
        NSString *filename = [fileName lastPathComponent];
        return [tmpDir stringByAppendingPathComponent:filename];
    }
    return nil;
}

+ (void) removeTmpFile:(NSString*) filename
{
    if(filename != nil)
    {
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        if([defaultManager fileExistsAtPath:filename])
        {
            NSError *error;
            [defaultManager removeItemAtPath:filename error:&error];
        }
    }
}

@end

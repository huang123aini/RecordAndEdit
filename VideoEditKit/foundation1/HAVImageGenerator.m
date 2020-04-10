//
//  HAVImageGenerator.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVImageGenerator.h"
@interface HAVImageGenerator ()

@property (nonatomic ,strong) AVAsset *assetUrl;
@property (nonatomic ,strong) AVAssetImageGenerator *imageGenerator;

- (UIImage *)imageAtTime:(CMTime) time;

@end

@implementation HAVImageGenerator

- (id) initWithUrl:(NSURL *) url
{
    self = [super init];
    if(self)
    {
        self.assetUrl = [AVURLAsset assetWithURL:url];
        if(self.assetUrl != nil)
        {
            self.imageGenerator=[AVAssetImageGenerator assetImageGeneratorWithAsset:self.assetUrl];
        }
    }
    return self;
}

- (id) initWithLocalPath:(NSString *) path
{
    NSURL *videoUrl = [NSURL fileURLWithPath:path];
    if(videoUrl != nil)
    {
        self = [self initWithUrl:videoUrl];
    }
    return self;
}

- (id)initWithLocalPaths:(NSArray <NSString *> *)urlArray
{
    self = [super init];
    if (self)
    {
        self.assetUrl = [self genAsset:urlArray];
        self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.assetUrl];
    }
    
    return self;
}

- (UIImage *) generatorImage
{
    CMTime assetDuration = [self.assetUrl duration];
    CMTime time = kCMTimeZero;//CMTime是表示电影时间信息的结构体，第一个参数表示是视频第几秒，第二
    if(assetDuration.value > 200)
    {
        time = CMTimeMake(60, assetDuration.timescale);
    }else
    {
        time = CMTimeMake((assetDuration.value/3), assetDuration.timescale);
    }
    return [self imageAtTime:time];
}

- (UIImage *)generatorImageAtTime:(Float64) time
{
    
    CMTime assetDuration = [self.assetUrl duration];
    if(time < CMTimeGetSeconds(assetDuration))
    {
        CMTime duration = CMTimeMakeWithSeconds((Float64)time, assetDuration.timescale);
        return [self imageAtTime:duration];
    }
    return nil;
}

- (UIImage *)imageAtTime:(CMTime) time
{
    NSError *error=nil;
    CMTime actualTime;
    
    self.imageGenerator.appliesPreferredTrackTransform = YES;
    
    CGImageRef cgImage = [self.imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    
    if(error != nil)
    {
        return nil;
    }
    
    UIImage* image;
    if (CGImageGetWidth(cgImage) > CGImageGetHeight(cgImage)) //横屏
    {
        image =  [self landScapeImage:cgImage];
    }else
    {
        image = [UIImage imageWithCGImage:cgImage];
    }
    
    //保存到相册
    CGImageRelease(cgImage);
    return image;
}

-(UIImage*)landScapeImage:(CGImageRef)image
{
    
    size_t w = CGImageGetWidth(image);
    size_t h = CGImageGetHeight(image);
    CGSize size = CGSizeMake(w, h);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.height, size.width), NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    float hh = size.height * size.height / size.width;
    float hStart = (size.width - hh) / 2;
    
    CGContextSetTextMatrix(context,   CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, size.width);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(0, hStart, size.height, hh), image);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
    
}

- (AVAsset *)genAsset:(NSArray <NSString *> *)urlArray{
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    CMTime tmpCu = kCMTimeZero;
    AVMutableCompositionTrack *vCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    for (NSString *url in urlArray)
    {
        AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:url]];
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        if (videoTrack)
        {
            [vCompositionTrack insertTimeRange:videoTrack.timeRange ofTrack:videoTrack atTime:tmpCu error:nil];
            tmpCu = CMTimeAdd(tmpCu, videoTrack.timeRange.duration);
        }
    }
    return composition;
}

@end

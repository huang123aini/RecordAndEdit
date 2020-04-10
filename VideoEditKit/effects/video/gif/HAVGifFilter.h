//
//  HAVGifFilter.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>

#define kGifPath    @"kGifPath"
#define kGifRect    @"kGifRect"
#define kGifRadian  @"kGifRadian"
#define kTag        @"kTag"

@interface HAVGifFilter : GPUImageFilter

@property (nonatomic, assign) BOOL enableGifRepeat;
@property (nonatomic, assign) BOOL disableShow;
@property (nonatomic, assign) GPUImageRotationMode gifRotationMode;
@property (readwrite, nonatomic) GPUImageFillModeType fillMode;
@property(nonatomic,assign)BOOL isPreView;
- (id)initWithGifPath:(NSArray <NSString *> *)pathArr;
- (id)initWithGif:(NSArray <NSDictionary *> *)arr;

-(instancetype)init;


/*添加Gif对象*/
-(void)addGifObj:(NSDictionary*)dic;
/*移除Gif对象*/
-(void)removeGifObj:(NSDictionary*)dic;
@end

@interface GifModel : NSObject

@property(nonatomic,assign)GLuint gifModelTextureID;
@property (nonatomic, assign) CGFloat startTime;
@property(nonatomic,assign)CGFloat curFrameTime;
@property (nonatomic, assign) CGFloat frameDuration; ///ms deprecated
@property (nonatomic, assign) CGFloat frameCount;
@property (nonatomic, assign) CGFloat totalDuration; ///ms
@property (nonatomic, strong) NSMutableArray *mArray;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) NSUInteger repeatCount;
@property (nonatomic, assign) NSUInteger curIndex;
@property (nonatomic, assign) CGRect rect;
@property (nonatomic, assign) CGFloat radian;
@property (nonatomic, assign) int tag;

- (void)initTexture;
-(void)releaseTextureID;

@end

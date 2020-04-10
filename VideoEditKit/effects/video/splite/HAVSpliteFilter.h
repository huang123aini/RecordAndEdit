//
//  HAVSpliteFilter.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVDataSourceDelegate.h"

typedef NS_ENUM(NSInteger, HAVDisplayModel)
{
    HAVSpliteScreen, // 分屏模式
    HAVFullScreen, // 全屏模式
};

@interface HAVSpliteFilter : GPUImageFilter
@property (nonatomic, assign) HAVDisplayModel displayModel;
@property (nonatomic, assign) BOOL preview;

- (void) reset;
- (void)addBackground:(UIImage*)image;
- (instancetype) initWithDataSource:(id<HAVDataSourceDelegate>) dataSource;

//关于虚帧
-(UIImage*)getBattleGhostImage;
-(void)setGhostImage:(UIImage*)image;
-(void)openGhost;
-(void)shutDownGhost;

@end

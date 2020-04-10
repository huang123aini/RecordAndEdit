//
//  HAVSpliteFilterController.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVDataSourceDelegate.h"
#import "HAVSpliteFilter.h"
#import "HAVMovieFileReader.h"
#import "HAVGPUImageFilterProtocol.h"

@interface HAVSpliteFilterController : NSObject <HAVGPUImageFaceTrackProtocol>

@property (nonatomic, assign) BOOL showOnly;
@property (nonatomic, strong) HAVSpliteFilter* spliteFilter;
@property (nonatomic, strong) HAVMovieFileReader *fileReader;

- (void) setDisplayModel:(HAVDisplayModel) displayModel;
- (instancetype) initWithDataSource:(id<HAVDataSourceDelegate>) dataSource;
- (void) reset;
- (void) setPreview:(BOOL) preview;

@end

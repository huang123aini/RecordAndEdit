//
//  DCVideoPreview.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "DCSpecialEffectsView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DCPreviewFoucsDelegate <NSObject>

@required

- (void) onFoucsAtPoint:(CGPoint) point previewSize:(CGSize) size;

@end

@interface DCVideoPreview : DCSpecialEffectsView

@property (nonatomic, weak) id<DCPreviewFoucsDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

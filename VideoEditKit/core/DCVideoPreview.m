//
//  DCVideoPreview.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "DCVideoPreview.h"

@interface DCVideoPreview()

@property (nonatomic ,strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation DCVideoPreview


-(void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
};


- (void) setDelegate:(id<DCPreviewFoucsDelegate>)delegate
{
    _delegate = delegate;
    if(self.tapGestureRecognizer != nil)
    {
        if([self.gestureRecognizers containsObject:self.tapGestureRecognizer])
        {
            [self removeGestureRecognizer:self.tapGestureRecognizer];
        }
        self.tapGestureRecognizer = nil;
    }
    if (delegate != nil)
    {
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:self.tapGestureRecognizer];
    }
}

-(void) handleSingleTap:(UITapGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:sender.view];
    if( [self.delegate respondsToSelector:@selector(onFoucsAtPoint:previewSize:)])
    {
        [self.delegate onFoucsAtPoint:CGPointMake(point.x , point.y) previewSize :self.bounds.size];
    }
}

-(void)dealloc
{
    if(self.tapGestureRecognizer != nil)
    {
        if([self.gestureRecognizers containsObject:self.tapGestureRecognizer])
        {
            [self removeGestureRecognizer:self.tapGestureRecognizer];
        }
        self.tapGestureRecognizer = nil;
    }
    NSLog(@"dealloc %s, %s",__FILE__ ,__FUNCTION__);
    
}

@end

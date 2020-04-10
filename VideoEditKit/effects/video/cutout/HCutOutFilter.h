//
//  HCutOutFilter.h
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/13.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <GPUKit/GPUKit.h>
@interface HCutOutFilter : GPUImageFilter
{
    // location
    GLint targetColorUniform;
    GLint widthStepUniform;
    GLint heightStepUniform;
    GLint diffUniform;
    GLint smoothModeUniform;
    GLint blackValueMaxUniform;
    GLint graySaturationMaxUniform;
    GLint grayValueMaxUniform;
    GLint redHueMinUniform;
    GLint redHueMaxUniform;
    GLint orangeHueMinUniform;
    GLint orangeHueMaxUniform;
    GLint yellowHueMinUniform;
    GLint yellowHueMaxUniform;
    GLint greenHueMinUniform;
    GLint greenHueMaxUniform;
    GLint cyanHueMinUniform;
    GLint cyanHueMaxUniform;
    GLint blueHueMinUniform;
    GLint blueHueMaxUniform;
    GLint purpleHueMinUniform;
    GLint purpleHueMaxUniform;
    GLint array3x3Uniform;
    GLint weight3x3Uniform;
    GLint array5x5Uniform;
    GLint weight5x5Uniform;
    
    float targetColor[4];
    float widthStep;
    float heightStep;
    float diff;
    int smoothMode;
    float blackValueMax;
    float graySaturationMax;
    float grayValueMax;
    float redHueMin;
    float redHueMax;
    float orangeHueMin;
    float orangeHueMax;
    float yellowHueMin;
    float yellowHueMax;
    float greenHueMin;
    float greenHueMax;
    float cyanHueMin;
    float cyanHueMax;
    float blueHueMin;
    float blueHueMax;
    float purpleHueMin;
    float purpleHueMax;
    float array3x3[18];
    float weight3x3[9];
    float array5x5[50];
    float weight5x5[25];
    int width;
    int height;
}

- (void)setSmoothMode:(int)mode; //抠图精细度（0:1x1,超快速，1：3x3中速，2:5x5慢速,慢速处理时间是快速的2.5倍，安卓测试值为40～60ms->120～160ms）
- (void)setDiff:(float)df; //微调，和绿色的差别（0-1，固定都传1.0就好）
- (void)setTargetColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;

@end

//
//  HGPUBeauty.m
//  HAVKit
//
//  Created by 黄世平 on 2019/1/20.
//  Copyright © 2019 黄世平. All rights reserved.
//

#import "HGPUBeauty.h"

#import "HAVTools.h"
#undef exp
#undef sin
#undef pow
#undef floor
#undef ceil
#undef sqrt
#undef cos
#undef sqrt

NSString* const kVertexShaderString = SHADER_STRING
(
 precision highp float;
 attribute vec4 aPosition;
 attribute vec4 aTexCoord;
 varying vec2 vTexCoord;
 
 void main()
 {
     gl_Position = aPosition;
     vTexCoord = aTexCoord.xy;
 }
 );

#pragma mark -- 美白shader
NSString* const kBeautyVertexShader = SHADER_STRING
(
 attribute vec2 aPosition;
 attribute vec2 aTexCoord;
 
 varying highp vec2 vTexCoord;
 void main()
 {
     vTexCoord = aTexCoord;
     gl_Position = vec4(aPosition, 0.0, 1.0);
 }
 );

NSString* kBeautyFragmentShader = SHADER_STRING
(
 precision highp float;
 varying vec2 vTexCoord;
 
 uniform sampler2D uInputTex;
 uniform sampler2D uReddenTable;
 uniform sampler2D uWhitenTable;
 uniform float uReddenDegree;
 uniform float uWhitenDegree;
 
 float sigmoid(float x, float t, float s)
 {
     return 1.0 / (1.0 + exp(-(x - t) / s));
 }
 
 vec3 RGB2YCrCb(vec3 rgb)
 {
     vec3 ycrcb;
     
     ycrcb.x = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
     ycrcb.y = (rgb.r - ycrcb.x) * 0.718 + 0.5;
     ycrcb.z = (rgb.b - ycrcb.x) * 0.564 + 0.5;
     
     return ycrcb;
 }
 
 vec3 YCrCb2RGB(vec3 ycrcb)
 {
     vec3 rgb;
     
     rgb.r = ycrcb.x + 1.403 * (ycrcb.y - 0.5);
     rgb.g = ycrcb.x - 0.714 * (ycrcb.y - 0.5) - 0.344 * (ycrcb.z - 0.5);
     rgb.b = ycrcb.x + 1.733 * (ycrcb.z - 0.5);
     
     return rgb;
 }
 
 vec3 filterColor(vec3 src, sampler2D table, float factor)
 {
     highp float blue = src.b * 63.0;
     
     highp vec2 q1;
     float fb = floor(blue);
     q1.y = floor(fb * 0.125);
     q1.x = fb - (q1.y * 8.0);
     
     highp vec2 q2;
     float cb = ceil(blue);
     q2.y = floor(cb * 0.125);
     q2.x = cb - (q2.y * 8.0);
     
     vec2 t = 0.123 * src.rg + vec2(0.000976563);
     vec2 t1 = q1 * 0.125 + t;
     vec3 p1 = texture2D(table, t1).rgb;
     
     vec2 t2 = q2 * 0.125 + t;
     vec3 p2 = texture2D(table, t2).rgb;
     
     vec3 filtered = mix(p1, p2, fract(blue));
     return mix(src, filtered, factor);
 }
 
 // RGB <-> YCrCb conversion: opencv specification
 // http://docs.opencv.org/2.4/modules/imgproc/doc/miscellaneous_transformations.html
 void main()
{
    vec4 src = texture2D(uInputTex, vTexCoord);
    
    // redden.
    vec3 ycrcb = RGB2YCrCb(src.rgb);
    float sg = sigmoid(ycrcb.y, ycrcb.z, 0.0392157);
    vec3 whitten = filterColor(src.rgb, uWhitenTable, uWhitenDegree);
    vec3 dst = mix(src.rgb, whitten, sg);
    vec3 redden = filterColor(dst, uReddenTable, uReddenDegree);
    gl_FragColor = vec4(redden, src.a);
}
 );

#pragma mark ---磨皮shader

NSString* const kSmoothVertexShader = SHADER_STRING
(
 attribute vec2 aPosition;
 attribute vec2 aTexCoord;
 
 varying highp vec2 vTexCoord;
 void main()
 {
     vTexCoord = aTexCoord;
     gl_Position = vec4(aPosition, 0.0, 1.0);
 }
 );

NSString *kSmoothFragmentShader = SHADER_STRING
(
 precision highp float;
 varying vec2 vTexCoord;
 
 uniform sampler2D uInputTex;
 uniform sampler2D uContrast;
 
 uniform float uImageWidth;
 uniform float uImageHeight;
 uniform float uSmoothDegree;
 
 float sigmoid(float x, float t, float s)
 {
     return 1.0 / (1.0 + exp(-(x - t) / s));
 }
 
 vec3 RGB2YCrCb(vec3 rgb)
 {
     vec3 ycrcb;
     
     ycrcb.x = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
     ycrcb.y = (rgb.r - ycrcb.x) * 0.718 + 0.5;
     ycrcb.z = (rgb.b - ycrcb.x) * 0.564 + 0.5;
     
     return ycrcb;
 }
 
 vec3 YCrCb2RGB(vec3 ycrcb)
 {
     vec3 rgb;
     
     rgb.r = ycrcb.x + 1.403 * (ycrcb.y - 0.5);
     rgb.g = ycrcb.x - 0.714 * (ycrcb.y - 0.5) - 0.344 * (ycrcb.z - 0.5);
     rgb.b = ycrcb.x + 1.733 * (ycrcb.z - 0.5);
     
     return rgb;
 }
 
 vec3 filterColor(vec3 src, sampler2D table, float factor)
 {
     highp float blue = src.b * 63.0;
     
     highp vec2 q1;
     float fb = floor(blue);
     q1.y = floor(fb * 0.125);
     q1.x = fb - (q1.y * 8.0);
     
     highp vec2 q2;
     float cb = ceil(blue);
     q2.y = floor(cb * 0.125);
     q2.x = cb - (q2.y * 8.0);
     
     vec2 t = 0.123 * src.rg + vec2(0.000976563);
     vec2 t1 = q1 * 0.125 + t;
     vec3 p1 = texture2D(table, t1).rgb;
     
     vec2 t2 = q2 * 0.125 + t;
     vec3 p2 = texture2D(table, t2).rgb;
     
     vec3 filtered = mix(p1, p2, fract(blue));
     return mix(src, filtered, factor);
 }
 
 // RGB <-> YCrCb conversion: opencv specification
 // http://docs.opencv.org/2.4/modules/imgproc/doc/miscellaneous_transformations.html
 vec4 adjustContrast(vec4 src)
 {
     float uContrastDegree = 0.051;
     vec3 cont = filterColor(src.rgb, uContrast, uContrastDegree);
     vec3 ycrcb = RGB2YCrCb(src.rgb);
     float sg = sigmoid(ycrcb.y, ycrcb.z, 0.0392157);
     // http://jira.in.zhihu.com/browse/COMB-1150
     // 修复拍摄显示器时，画面中会出现黑色阴影的问题
     sg = clamp(sg, 0.0, 1.0);
     return vec4(mix(src.rgb, cont, sg), src.a);
 }
 
 vec4 adjustSaturation(vec4 srcColor)
{
     float saturationDegree = 0.1;
     float maxrg = max(srcColor.r, srcColor.g);
     float maxC = max(maxrg, srcColor.b);
     float minrg = min(srcColor.r, srcColor.g);
     float minC = min(minrg, srcColor.b);
     float delta = (maxC - minC);
     float value = (maxC + minC);
     
     float L = value / 2.0;
     float mask_1 = 0.0;
     if (L < 0.5)
     {
         mask_1 = 1.0;
     }
     float s1 = delta / (value + 0.001);
     float s2 = delta / (2.0 - value + 0.001);
     float s = s1 * mask_1 + s2 * (1.0 - mask_1);
     if (saturationDegree >= 0.0)
     {
         float temp = saturationDegree + s;
         float mask_2 = 0.0;
         if (temp > 1.0)
         {
             mask_2 = 1.0;
         }
         float alpha_1 = s;
         float alpha_2 = s * 0.0 + 1.0 - saturationDegree;
         float degree = alpha_1 * mask_2 + alpha_2 * (1.0 - mask_2);
         degree = 1.0 / (degree + 0.001) - 1.0;
         vec3 color = vec3(srcColor.r + (srcColor.r - L) * degree, srcColor.g + (srcColor.g - L) * degree, srcColor.b + (srcColor.b - L) * degree);
         return vec4(color, srcColor.a);
     } else
     {
         vec3 color = vec3(L + (srcColor.r - L) * (1.0 + saturationDegree), L + (srcColor.g - L) * (1.0 + saturationDegree), L + (srcColor.b - L) * (1.0 + saturationDegree));
         return vec4(color, srcColor.a);
     }
 }
 
 void main()
{
     // 这里使用固定值效果更好，而不是 uImageWidth 和 uImageHeight
     float da = 1280.0;
     float db = 720.0;
     vec3 centerColor;
     vec2 coordinate = vTexCoord;
     
     float dx = 2.0 / db;
     float dy = 2.0 / da;
     
     vec2 gausCoord0 = coordinate + vec2(10.0 * dx, 0.0 * dy);
     vec2 gausCoord1 = coordinate + vec2(8.0 * dx, 6.0 * dy);
     vec2 gausCoord2 = coordinate + vec2(6.0 * dx, 8.0 * dy);
     vec2 gausCoord3 = coordinate + vec2(0.0 * dx, 10.0 * dy);
     vec2 gausCoord4 = coordinate + vec2(-6.0 * dx, 8.0 * dy);
     vec2 gausCoord5 = coordinate + vec2(-8.0 * dx, 6.0 * dy);
     vec2 gausCoord6 = coordinate + vec2(-10.0 * dx, 0.0 * dy);
     vec2 gausCoord7 = coordinate + vec2(-8.0 * dx, -6.0 * dy);
     vec2 gausCoord8 = coordinate + vec2(-6.0 * dx, -8.0 * dy);
     vec2 gausCoord9 = coordinate + vec2(0.0, -10.0 * dy);
     vec2 gausCoord10 = coordinate + vec2(6.0 * dx, -8.0 * dy);
     vec2 gausCoord11 = coordinate + vec2(8.0 * dx, -6.0 * dy);
     
     dx = 1.6 / db;
     dy = 1.6 / da;
     
     vec2 gausCoord12 = coordinate + vec2(0.0, 6.0 * dy);
     vec2 gausCoord13 = coordinate + vec2(4.0 * dx, 4.0 * dy);
     vec2 gausCoord14 = coordinate + vec2(6.0 * dx, 0.0 * dy);
     vec2 gausCoord15 = coordinate + vec2(4.0 * dx, -4.0 * dy);
     vec2 gausCoord16 = coordinate + vec2(0.0, -6.0 * dy);
     vec2 gausCoord17 = coordinate + vec2(-4.0 * dx, -4.0 * dy);
     vec2 gausCoord18 = coordinate + vec2(-6.0 * dx, 0.0);
     vec2 gausCoord19 = coordinate + vec2(-4.0 * dx, 4.0 * dy);
     float centerG = texture2D(uInputTex, coordinate).g;
     float weightSum;
     float gSum;
     float prob;
     float diffCenterG;
     float weight;
     float norFactor = 3.6;
     weightSum = 0.2;
     gSum = centerG * 0.2;
     
     prob = texture2D(uInputTex, gausCoord0).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord1).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord2).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord3).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord4).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord5).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord6).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord7).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord8).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord9).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord10).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord11).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.08 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord12).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.1 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord13).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.1 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord14).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.1 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord15).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.1 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord16).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.1 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord17).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.1 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord18).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.1 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     prob = texture2D(uInputTex, gausCoord19).g;
     diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
     weight = 0.2 * (1.0 - diffCenterG);
     weightSum += weight;
     gSum += prob * weight;
     
     gSum = gSum / weightSum;
     
     centerColor = texture2D(uInputTex, coordinate).rgb;
     prob = centerColor.g - gSum + 0.5;
     
     for (int i = 0; i < 5; i++)
     {
         if (prob <= 0.5)
         {
             prob = prob * prob * 2.0;
         } else
         {
             prob = 1.0 - ((1.0 - prob) * (1.0 - prob) * 2.0);
         }
     }
     float param = 1.0 + pow(gSum, 0.3) * 0.09;
     
     vec3 smoothResult = centerColor * param - vec3(prob) * (param - 1.0);
     smoothResult = mix(centerColor, smoothResult, pow(centerColor.g, 0.33));
     smoothResult = mix(centerColor, smoothResult, pow(centerColor.g, 0.39));
     smoothResult = mix(centerColor, smoothResult, uSmoothDegree);
     
     vec4 result = vec4(pow(smoothResult, vec3(0.96)), 1.0);
     result = adjustSaturation(result);
     result = adjustContrast(result);
     gl_FragColor = result;
 }
);



@interface HGPUBeauty()
{
    
    GLProgram* _smoothProgram;
    GLProgram* _whitenProgram;
    
    //关于美白
    GLuint _aPosition_Whiten;
    GLuint _aTexCoord_Whiten;
    GLuint _uReddenLevel;
    GLuint _uWhitenLevel;
    GLuint _uTextureID_Whiten;
    GLuint _uRedTextureID_Whiten;
    GLuint _uWhitenTextureID_Whiten;
    
    //关于磨皮
    GLuint _aPosition_Smooth;
    GLuint _aTexCoord_Smooth;
    GLuint _uDegree_Smooth;
    GLuint _uTextureID_Smooth;
    GLuint _uContrastTextureID_Smooth;
    
    //关于纹理
    GLuint _redTextureID;
    GLuint _whitenTextureID;
    GLuint _constrastTextureID;
    
    GLuint _testTextureID;
}

//关于FBO
@property(nonatomic,strong)HNormalFBO* smoothFBO;
@property(nonatomic,strong)HNormalFBO* whitenFBO;

@end


@implementation HGPUBeauty

-(instancetype)init
{
    if (self = [super init])
    {
        [self initParams];
        
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageContext useImageProcessingContext];
            
            [self initTableTexture];
            [self setupPrograms];
        });
       
    }
    return self;
}

#pragma mark ---一些公共对象的初始化
-(void)initParams
{
    self.smoothFBO = nil;
    self.whitenFBO = nil;
    self.smoothing = 0.74f;
    self.reddening = 0.36f;
    self.whitening = 0.3f;
    
    //纹理
    _redTextureID = 0;
    _whitenTextureID = 0;
    _constrastTextureID = 0;
    _testTextureID = 0;
}

#pragma mark ---设置绘制FBO

-(void)setupFbos:(CGSize)size
{
    if (!self.smoothFBO)
    {
        self.smoothFBO = [[HNormalFBO alloc] initWithSize:size];
    }
    if (!self.whitenFBO)
    {
        self.whitenFBO = [[HNormalFBO alloc] initWithSize:size];
    }
}

#pragma mark  ---设置绘制Program
-(void)setupPrograms
{
    
    //美白
    _aPosition_Whiten = 0;
    _aTexCoord_Whiten = 0;
    _uReddenLevel = 0;
    _uWhitenLevel = 0;
    _uTextureID_Whiten = 0;
    _uRedTextureID_Whiten = 0;
    _uWhitenTextureID_Whiten = 0;
    
    //磨皮
    _aPosition_Smooth = 0;
    _aTexCoord_Smooth = 0;
    _uDegree_Smooth = 0;
    _uTextureID_Smooth = 0;
    _uContrastTextureID_Smooth = 0;
    
   
    if (_whitenProgram == nil)
    {
        _whitenProgram = [[GLProgram alloc] initWithVertexShaderString:kBeautyVertexShader fragmentShaderString:kBeautyFragmentShader];
        if (!_whitenProgram.initialized)
        {
            [_whitenProgram addAttribute:@"aPosition"];
            [_whitenProgram addAttribute:@"aTexCoord"];
        }
        if (![_whitenProgram link])
        {
            NSAssert(NO, @"Filter shader link failed");
        }

        _aPosition_Whiten        = [_whitenProgram attributeIndex:@"aPosition"];
        _aTexCoord_Whiten        = [_whitenProgram attributeIndex:@"aTexCoord"];
        _uReddenLevel            = [_whitenProgram uniformIndex:@"uReddenDegree"];
        _uWhitenLevel            = [_whitenProgram uniformIndex:@"uWhitenDegree"];

        _uTextureID_Whiten       = [_whitenProgram uniformIndex:@"uInputTex"];
        _uRedTextureID_Whiten    = [_whitenProgram uniformIndex:@"uReddenTable"];
        _uWhitenTextureID_Whiten = [_whitenProgram uniformIndex:@"uWhitenTable"];

    }


    if (_smoothProgram == nil)
    {
        _smoothProgram =  [[GLProgram alloc] initWithVertexShaderString:kSmoothVertexShader fragmentShaderString:kSmoothFragmentShader];

        if (!_smoothProgram.initialized)
        {
            [_smoothProgram addAttribute:@"aPosition"];
            [_smoothProgram addAttribute:@"aTexCoord"];
        }
        if (![_smoothProgram link])
        {
            NSAssert(NO, @"Filter shader link failed");
        }

        _aPosition_Smooth    = [_smoothProgram attributeIndex:@"aPosition"];
        _aTexCoord_Smooth    = [_smoothProgram attributeIndex:@"aTexCoord"];
        _uDegree_Smooth      = [_smoothProgram uniformIndex:@"uSmoothDegree"];
        _uTextureID_Smooth   = [_smoothProgram uniformIndex:@"uInputTex"];
        _uContrastTextureID_Smooth = [_smoothProgram uniformIndex:@"uContrast"];

    }
}

#pragma mark --初始化查色表纹理
-(void)initTableTexture
{
    _redTextureID = [HAVTools createTextureWithImage:[UIImage imageNamed:@"reddenWhiten_whiten.zmlp"]];
    _whitenTextureID = [HAVTools createTextureWithImage:[UIImage imageNamed:@"reddenWhiten_redden.zmlp"]];
    _constrastTextureID = [HAVTools createTextureWithImage:[UIImage imageNamed:@"smooth_contrast.zmlp"]];
    
    if (!_testTextureID)
    {
        _testTextureID = [HAVTools createTextureWithImage:[UIImage imageNamed:@"timg.jpg"]];
    }
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
  
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
  
    
    NSLog(@"正在进行美颜处理");
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    if (firstInputFramebuffer)
    {
        [self setupFbos:[firstInputFramebuffer size]];
    }
    
    GLfloat vertices1 [] =
    {
        -1.0f,-1.0f,
        1.0f,-1.0f,
        -1.0f,1.0f,
        1.0f,1.0f
    };
    
    //绘制美白
    [GPUImageContext setActiveShaderProgram:_whitenProgram];
    [self.whitenFBO bindFBO];

    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, _whitenTextureID);
    glUniform1i(_uWhitenTextureID_Whiten, 5);

    glActiveTexture(GL_TEXTURE6);
    glBindTexture(GL_TEXTURE_2D, _redTextureID);
    glUniform1i(_uRedTextureID_Whiten, 6);

    glActiveTexture(GL_TEXTURE7);
    glBindTexture(GL_TEXTURE_2D, firstInputFramebuffer.texture);
    glUniform1i(_uTextureID_Whiten, 7);

    glUniform1f(_uReddenLevel, self.reddening);
    glUniform1f(_uWhitenLevel, self.whitening);

    glEnableVertexAttribArray(_aPosition_Whiten);
    glEnableVertexAttribArray(_aTexCoord_Whiten);
    glVertexAttribPointer(_aPosition_Whiten, 2, GL_FLOAT, 0, 0, vertices1);
    glVertexAttribPointer(_aTexCoord_Whiten, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    [self.whitenFBO unbindFBO];
    
    //绘制磨皮
    [GPUImageContext setActiveShaderProgram:_smoothProgram];
    [self.smoothFBO bindFBO];

    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, [self.whitenFBO fboTexture]);
    glUniform1i(_uTextureID_Smooth, 3);

    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, _constrastTextureID);
    glUniform1i(_uContrastTextureID_Smooth, 4);

    glUniform1f(_uDegree_Smooth, self.smoothing);

    glEnableVertexAttribArray(_aPosition_Smooth);
    glEnableVertexAttribArray(_aTexCoord_Smooth);
    glVertexAttribPointer(_aPosition_Smooth, 2, GL_FLOAT, 0, 0, vertices1);
    glVertexAttribPointer(_aTexCoord_Smooth, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    [self.smoothFBO unbindFBO];

    //绘制到outputFramebuffer
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    [outputFramebuffer activateFramebuffer];
    [GPUImageContext setActiveShaderProgram:filterProgram];
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //视频帧
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, [self.smoothFBO fboTexture]);
    
    glUniform1i(filterInputTextureUniform, 1);
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    

    [firstInputFramebuffer unlock];
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}


-(void) dealloc
{
    
    //清除纹理hold的内存
    if (_redTextureID != 0)
    {
        glDeleteTextures(1, &_redTextureID);
        _redTextureID = 0;
    }
    if (_whitenTextureID != 0)
    {
        glDeleteTextures(1, &_whitenTextureID);
        _whitenTextureID = 0;
    }
    if (_constrastTextureID != 0)
    {
        glDeleteTextures(1, &_constrastTextureID);
        _constrastTextureID = 0;
    }
}

- (void) reset
{
    isEndProcessing = NO;
}

- (void)endProcessing
{
    [super endProcessing];
    isEndProcessing = NO;
}

@end

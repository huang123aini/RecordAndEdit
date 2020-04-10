//
//  HCutOutFilter.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/13.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HCutOutFilter.h"
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kQHVCEditGIColorReplacingFragmentShaderString = SHADER_STRING
(
 precision mediump float;\n
 varying highp vec2 textureCoordinate;\n
 uniform sampler2D inputImageTexture;\n
 uniform float u_diff;\n
 uniform float u_targetColor[4];\n
 uniform int u_smoothMode;\n
 uniform float u_widthStep;\n
 uniform float u_heightStep;\n
 uniform float u_blackValueMax;\n
 uniform float u_graySaturationMax;\n
 uniform float u_grayValueMax;\n
 uniform float u_redHueMin;\n
 uniform float u_redHueMax;\n
 uniform float u_orangeHueMin;\n
 uniform float u_orangeHueMax;\n
 uniform float u_yellowHueMin;\n
 uniform float u_yellowHueMax;\n
 uniform float u_greenHueMin;\n
 uniform float u_greenHueMax;\n
 uniform float u_cyanHueMin;\n
 uniform float u_cyanHueMax;\n
 uniform float u_blueHueMin;\n
 uniform float u_blueHueMax;\n
 uniform float u_purpleHueMin;\n
 uniform float u_purpleHueMax;\n
 uniform float u_array3x3[18];\n
 uniform float u_weight3x3[9];\n
 uniform float u_array5x5[50];\n
 uniform float u_weight5x5[25];\n
 \n
 vec4 rgb2hsv(vec4 colorRGB){\n
     float h;\n
     float s;\n
     float v;\n
     if (colorRGB.r >= colorRGB.g && colorRGB.r >= colorRGB.b) {\n
         v = colorRGB.r;\n
         float minC = 0.0;\n
         if (colorRGB.g >= colorRGB.b) {\n
             minC = colorRGB.b;\n
         } else {\n
             minC = colorRGB.g;\n
         }\n
         s = 0.0;\n
         if (v > 0.0) {\n
             s = 1.0 - minC/v;\n
         } else {\n
             s = 0.0;\n
         }
         h = 60.0*(colorRGB.g - colorRGB.b)/(v-minC);\n
         if (h<0.0) {\n
             h = h+360.0;\n
         }\n
         return vec4(h,s,v,colorRGB.a);\n
     }\n
     else if (colorRGB.g >= colorRGB.r && colorRGB.g >= colorRGB.b) {\n
         v = colorRGB.g;\n
         float minC = 0.0;\n
         if (colorRGB.r >= colorRGB.b) {\n
             minC = colorRGB.b;\n
         } else {\n
             minC = colorRGB.r;\n
         }\n
         s = 0.0;\n
         if (v > 0.0) {\n
             s = 1.0 - minC/v;\n
         } else {\n
             s = 0.0;\n
         }\n
         h = 120.0+60.0*(colorRGB.b - colorRGB.r)/(v-minC);\n
         if (h<0.0) {\n
             h = h+360.0;\n
         }\n
         return vec4(h,s,v,colorRGB.a);\n
     }\n
     else if (colorRGB.b >= colorRGB.r && colorRGB.b >= colorRGB.g) {\n
         v = colorRGB.b;\n
         float minC = 0.0;\n
         if (colorRGB.r >= colorRGB.g) {\n
             minC = colorRGB.g;\n
         } else {\n
             minC = colorRGB.r;\n
         }\n
         s = 0.0;\n
         if (v > 0.0) {\n
             s = 1.0 - minC/v;\n
         } else {\n
             s = 0.0;\n
         }\n
         h = 240.0+60.0*(colorRGB.r - colorRGB.g)/(v-minC);\n
         if (h < 0.0) {\n
             h = h+360.0;\n
         }\n
         return vec4(h,s,v,colorRGB.a);\n
     }\n
     else {\n
         return vec4(1.0, 1.0, 1.0, 1.0);\n
     }\n
 }\n
 \n
 int getColorIndex(vec4 colorHSV){\n
     float h = colorHSV.r;\n
     float s = colorHSV.g;\n
     float v = colorHSV.b;\n
     if (v <= u_blackValueMax) {\n
         return 0;\n
     }\n
     if (s <= u_graySaturationMax) {\n
         if (v <= u_grayValueMax) {\n
             return 1;\n
         } else {\n
             return 2;\n
         }\n
     }\n
     \n
     if (u_redHueMin <= h || h <= u_redHueMax) {\n
         return 3;\n
     } else if ((u_orangeHueMin) <= h && h <= (u_orangeHueMax)) {\n
         return 4;\n
     } else if ((u_yellowHueMin) <= h && h <= (u_yellowHueMax)) {\n
         return 5;\n
     } else if ((u_greenHueMin) <= h && h <= (u_greenHueMax)) {\n
         return 6;\n
     } else if ((u_cyanHueMin) <= h && h <= (u_cyanHueMax)) {\n
         return 7;\n
     } else if ((u_blueHueMin) <= h && h <= (u_blueHueMax)) {\n
         return 8;\n
     } else if ((u_purpleHueMin) <= h && h <= (u_purpleHueMax)) {\n
         return 9;\n
     }\n
     \n
     return -1;\n
 }\n
 \n
 vec4 checkNearGreen(vec4 nearColor) {\n
     float df = u_diff;\n
     float dtValue = 0.004;\n
     float alpha = 1.0;\n
     float th = 0.2*df*10.0;\n
     vec4 hsv = rgb2hsv(nearColor);\n
     int colorIndex = getColorIndex(hsv);\n
     if (6 == colorIndex) {\n
         if (nearColor.g>(nearColor.r+0.03125*th) && nearColor.g>(nearColor.b+0.03125*th)) {\n
             vec4 tColor = vec4(u_targetColor[0], u_targetColor[1], u_targetColor[2], u_targetColor[3]);\n
             float redMean = (tColor.r + nearColor.r)*0.5;\n
             float deltaR = tColor.r - nearColor.r;\n
             float deltaG = tColor.g - nearColor.g;\n
             float deltaB = tColor.b - nearColor.b;\n
             float partR = (2.0 + redMean)*deltaR*deltaR;\n
             float partG = (4.0          )*deltaG*deltaG;\n
             float partB = (3.0 - redMean)*deltaB*deltaB;\n
             float delta = sqrt(partR + partG + partB)*0.111111;\n
             if (delta <= df*1.0) {\n
                 nearColor = vec4(0.0);\n
             } else {
                 float gray = (nearColor.r + nearColor.g + nearColor.b) / 3.0;\n
                 gray=clamp(gray, 0.0, 1.0);\n
                 nearColor = vec4(gray);\n
             }\n
         }\n
     }\n
     return nearColor;\n
 }\n
\n
 vec4 replaceGreenColor(vec4 color) {\n
     float df = u_diff;\n
     float dtValue = 0.004;\n
     float alpha = 1.0;\n
     float th = 0.2*df*10.0;\n
     \n
     if (color.g>(color.r+0.03125*th) && color.g>(color.b+0.03125*th)) {\n
         vec4 tColor = vec4(u_targetColor[0], u_targetColor[1], u_targetColor[2], u_targetColor[3]);\n
         float redMean = (tColor.r + color.r)*0.5;\n
         float deltaR = tColor.r - color.r;\n
         float deltaG = tColor.g - color.g;\n
         float deltaB = tColor.b - color.b;\n
         float partR = (2.0 + redMean)*deltaR*deltaR;\n
         float partG = (4.0          )*deltaG*deltaG;\n
         float partB = (3.0 - redMean)*deltaB*deltaB;\n
         float delta = sqrt(partR + partG + partB)*0.111111;\n
         \n
         if (delta <= df*1.0) {\n
             color = vec4(0.0, 0.0, 0.0, 0.0);\n
         } else {\n
             float count = 0.0;\n
             float uKC = 5.0/255.0;\n
             float ws = u_widthStep;\n
             float hs = u_heightStep;\n
             vec4 colorReplace = vec4(0.0);\n
             vec4 nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(-ws, 0.0));\n// -1,0
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(0.0, -hs));\n//0,-1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(ws, 0.0));\n//1,0
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(0.0, hs));\n//0,1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(-ws, hs));\n//-1,1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(-ws, -hs));\n//-1.-1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(ws, -hs));\n//1,-1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(ws, hs));\n//1,1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(-2.0*ws, 0.0));\n//-2,0
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(0.0, -2.0*hs));\n//0,-2
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(2.0*ws, 0.0));\n//2,0
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(0.0, 2.0*hs));\n//0,2
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 colorReplace += checkNearGreen(nearColor);\n
                 count += 1.0;\n
             }\n
             \n
             if (count > 0.5) {\n
                 color = colorReplace/count;\n
             } else {\n
                 float gray = (color.r + color.g + color.b) / 3.0;\n
                 color = vec4(clamp(gray, 0.0, 1.0));\n
             }\n
         }\n
     }\n
     return color;\n
 }\n
 \n
 vec4 replaceGreenColor3x3(vec4 color) {\n
     float df = u_diff;\n
     float dtValue = 0.004;\n
     float alpha = 1.0;\n
     float th = 0.2*df*10.0;\n
     \n
     if (color.g>(color.r+0.03125*th) && color.g>(color.b+0.03125*th)) {\n
         vec4 tColor = vec4(u_targetColor[0], u_targetColor[1], u_targetColor[2], u_targetColor[3]);\n
         float redMean = (tColor.r + color.r)*0.5;\n
         float deltaR = tColor.r - color.r;\n
         float deltaG = tColor.g - color.g;\n
         float deltaB = tColor.b - color.b;\n
         float partR = (2.0 + redMean)*deltaR*deltaR;\n
         float partG = (4.0          )*deltaG*deltaG;\n
         float partB = (3.0 - redMean)*deltaB*deltaB;\n
         float delta = sqrt(partR + partG + partB)*0.111111;\n
         \n
         if (delta <= df*1.0) {\n
             color = vec4(0.0, 0.0, 0.0, 0.0);\n
         } else {\n
             float count = 0.0;\n
             float uKC = 5.0/255.0;\n
             float ws = u_widthStep;\n
             float hs = u_heightStep;\n
             vec4 nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(-ws, 0.0));\n// -1,0
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(0.0, -hs));\n//0,-1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(ws, 0.0));\n//1,0
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(0.0, hs));\n//0,1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(-ws, hs));\n//-1,1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(-ws, -hs));\n//-1.-1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(ws, -hs));\n//1,-1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(ws, hs));\n//1,1
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(-2.0*ws, 0.0));\n//-2,0
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(0.0, -2.0*hs));\n//0,-2
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(2.0*ws, 0.0));\n//2,0
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             nearColor = texture2D(inputImageTexture, textureCoordinate+vec2(0.0, 2.0*hs));\n//0,2
             if (distance(nearColor.rgb, color.rgb)<uKC) {\n
                 color = checkNearGreen(nearColor);\n
                 return color;\n
             }\n
             \n
             float gray = (color.r + color.g + color.b) / 3.0;\n
             color = vec4(clamp(gray, 0.0, 1.0));\n
         }\n
     }\n
     return color;\n
 }\n
 \n
 vec4 doSmooth1x1() {\n
     float ws = u_widthStep;\n
     float hs = u_heightStep;\n
     vec4 colorOri = texture2D(inputImageTexture, textureCoordinate);\n
     vec4 colorNew = replaceGreenColor3x3(colorOri);\n
     float aSmooth = colorNew.a;\n
     vec4 colorSmooth = vec4(0.0);\n
     if (aSmooth > 0.9) {\n
         colorSmooth = colorOri;\n
     }\n
     else if (aSmooth < 0.01 /*|| colorNewAlphaAll < 0.01*/) {\n
         colorSmooth = vec4(0.0);\n
     }\n
     else {\n
         colorSmooth = colorOri*colorNew;\n
         colorSmooth = vec4(colorSmooth.rgb, aSmooth);\n
         colorSmooth.rgb = vec3((colorSmooth.r+colorSmooth.g+colorSmooth.b)/3.0);\n
     }\n
     return colorSmooth;\n
 }\n
 \n
 vec4 doSmooth3x3() {\n
     float ws = u_widthStep;\n
     float hs = u_heightStep;\n
     vec4 colorOri[9];\n
     vec4 colorNew[9];\n
     float aSmooth = 0.0;\n
     \n
     for (int i=0; i<9; i++) {\n
         int idx = 2*i;\n
         colorOri[i] = texture2D(inputImageTexture, textureCoordinate+vec2(u_array3x3[idx]*ws,  u_array3x3[idx+1]*hs));\n
         colorNew[i] = replaceGreenColor3x3(colorOri[i]);\n
         aSmooth += colorNew[i].a;\n
     }\n
     aSmooth /= 9.0;\n
     \n
     vec4 colorSmooth = vec4(0.0);\n
     if (aSmooth > 0.9) {\n
         colorSmooth = colorOri[4];\n
     }\n
     else if (aSmooth < 0.01 /*|| colorNewAlphaAll < 0.01*/) {\n
         colorSmooth = vec4(0.0);\n
     }\n
     else {\n
         for (int i=0; i<9; i++) {\n
             colorSmooth += colorOri[i]*colorNew[i]*u_weight3x3[i];\n
         }\n
         colorSmooth *= 0.0625;\n
         colorSmooth = vec4(colorSmooth.rgb, aSmooth);\n
         colorSmooth.rgb = vec3((colorSmooth.r+colorSmooth.g+colorSmooth.b)/3.0);\n
     }\n
     return colorSmooth;\n
 }\n
 \n
 vec4 doSmooth5x5() {\n
     float ws = u_widthStep;\n
     float hs = u_heightStep;\n
     vec4 colorOri[25];\n
     vec4 colorNew[25];\n
     float aSmooth = 0.0;\n
     for (int i=0; i<25; i++) {\n
         int idx = 2*i;\n
         colorOri[i] = texture2D(inputImageTexture, textureCoordinate+vec2(u_array5x5[idx]*ws, u_array5x5[idx+1]*hs));\n
         colorNew[i] = replaceGreenColor(colorOri[i]);\n
         aSmooth += colorNew[i].a;\n
     }\n
     aSmooth *= 0.04;\n
     \n
     vec4 colorSmooth = vec4(0.0);\n
     if (aSmooth > 0.9) {\n
         colorSmooth = colorOri[12];\n
     }\n
     else if (aSmooth < 0.01 /*|| colorNewAlphaAll < 0.01*/) {\n
         colorSmooth = vec4(0.0);\n
     }\n
     else {\n
         for (int i=0; i<25; i++) {\n
             colorSmooth += colorOri[i]*colorNew[i]*u_weight5x5[i];\n
         }\n
         colorSmooth /= 273.0;\n
         colorSmooth = vec4(colorSmooth.rgb, aSmooth);\n
         colorSmooth.rgb = vec3((colorSmooth.r+colorSmooth.g+colorSmooth.b)/3.0);\n
     }\n
     return colorSmooth;\n
 }\n
 \n
 void main()\n
 {\n
     vec4 color = texture2D(inputImageTexture, textureCoordinate);\n
     vec4 tColor = vec4(u_targetColor[0], u_targetColor[1], u_targetColor[2], u_targetColor[3]);\n
     \n
     vec4 hsv = rgb2hsv(color);\n
     int colorIndex = getColorIndex(hsv);\n
     vec4 hsvTarget = rgb2hsv(tColor);\n
     int colorIndexTarget = getColorIndex(hsvTarget);\n
     vec4 newColor = color;\n
     if (6 == colorIndexTarget) {\n
         newColor = replaceGreenColor(color);\n
         if (newColor.r < 0.9) {\n
             if (u_smoothMode == 0) {\n
                 newColor = doSmooth1x1();\n
             }\n
             else if (u_smoothMode == 1) {\n
                 newColor = doSmooth3x3();\n
             } else {\n
                 newColor = doSmooth5x5();\n
             }\n
         }\n
     } else {\n
         if (colorIndex == colorIndexTarget) {\n
             newColor = vec4(0.0, 0.0, 0.0, 0.0);\n
         }\n
     }\n
     gl_FragColor = newColor;\n
 }\n
 );
#else
NSString *const kQHVCEditGIColorReplacingFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float brightness;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4((textureColor.rgb + vec3(brightness)), textureColor.w);
 }
 );
#endif

@implementation HCutOutFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init
{
    if (!(self = [super initWithFragmentShaderFromString:kQHVCEditGIColorReplacingFragmentShaderString]))
    {
        return nil;
    }
    
    targetColorUniform = [filterProgram uniformIndex:@"u_targetColor"];
    targetColor[0] = 0.0f;
    targetColor[1] = 255.0f;
    targetColor[2] = 0.0f;
    targetColor[3] = 0.0f;
    
    widthStepUniform = [filterProgram uniformIndex:@"u_widthStep"];
    widthStep = 1.0f/1280.0f;
    
    heightStepUniform = [filterProgram uniformIndex:@"u_heightStep"];
    heightStep = 1.0f/720.0f;
                         
    diffUniform = [filterProgram uniformIndex:@"u_diff"];
    diff = 1.0f;
    
    smoothModeUniform = [filterProgram uniformIndex:@"u_smoothMode"];
    smoothMode = 0;
    
    blackValueMaxUniform = [filterProgram uniformIndex:@"u_blackValueMax"];
    blackValueMax = 0.15f;
    
    graySaturationMaxUniform = [filterProgram uniformIndex:@"u_graySaturationMax"];
    graySaturationMax = 0.2f;
    
    grayValueMaxUniform = [filterProgram uniformIndex:@"u_grayValueMax"];
    grayValueMax = 0.4f;
    
    redHueMinUniform = [filterProgram uniformIndex:@"u_redHueMin"];
    redHueMin = 337.5f;
    
    redHueMaxUniform = [filterProgram uniformIndex:@"u_redHueMax"];
    redHueMax = 15.0f;
    
    orangeHueMinUniform = [filterProgram uniformIndex:@"u_orangeHueMin"];
    orangeHueMin = 15.0f;
    
    orangeHueMaxUniform = [filterProgram uniformIndex:@"u_orangeHueMax"];
    orangeHueMax = 45.0f;
    
    yellowHueMinUniform = [filterProgram uniformIndex:@"u_yellowHueMin"];
    yellowHueMin = 45.0f;
    
    yellowHueMaxUniform = [filterProgram uniformIndex:@"u_yellowHueMax"];
    yellowHueMax = 70.0f;
    
    greenHueMinUniform = [filterProgram uniformIndex:@"u_greenHueMin"];
    greenHueMin = 70.0f;
    
    greenHueMaxUniform = [filterProgram uniformIndex:@"u_greenHueMax"];
    greenHueMax = 165.5f;
    
    cyanHueMinUniform = [filterProgram uniformIndex:@"u_cyanHueMin"];
    cyanHueMin = 165.5f;
    
    cyanHueMaxUniform = [filterProgram uniformIndex:@"u_cyanHueMax"];
    cyanHueMax = 228.0f;
    
    blueHueMinUniform = [filterProgram uniformIndex:@"u_blueHueMin"];
    blueHueMin = 228.0f;
    
    blueHueMaxUniform = [filterProgram uniformIndex:@"u_blueHueMax"];
    blueHueMax = 292.5f;
    
    purpleHueMinUniform = [filterProgram uniformIndex:@"u_purpleHueMin"];
    purpleHueMin = 292.5f;
    
    purpleHueMaxUniform = [filterProgram uniformIndex:@"u_purpleHueMax"];
    purpleHueMax = 337.5f;
    
    array3x3Uniform = [filterProgram uniformIndex:@"u_array3x3"];
    float array18[18] = {
        -1.0f, 1.0f,  0.0f, 1.0f,  1.0f, 1.0f,
        -1.0f, 0.0f,  0.0f, 0.0f,  1.0f, 0.0f,
        -1.0f,-1.0f,  0.0f,-1.0f,  1.0f,-1.0f
    };
    memcpy(array3x3, array18, 18*sizeof(float));
    
    weight3x3Uniform = [filterProgram uniformIndex:@"u_weight3x3"];
    float array9[9] = {
        1.0f, 2.0f, 1.0f,
        2.0f, 4.0f, 2.0f,
        1.0f, 2.0f, 1.0f
    };
    memcpy(weight3x3, array9, 9*sizeof(float));
    
    array5x5Uniform = [filterProgram uniformIndex:@"u_array5x5"];
    float array50[50] = {
        -2.0f, 2.0f,  -1.0f, 2.0f,  0.0f, 2.0f,  1.0f, 2.0f,  2.0f, 2.0f,
        -2.0f, 1.0f,  -1.0f, 1.0f,  0.0f, 1.0f,  1.0f, 1.0f,  2.0f, 1.0f,
        -2.0f, 0.0f,  -1.0f, 0.0f,  0.0f, 0.0f,  1.0f, 0.0f,  2.0f, 0.0f,
        -2.0f,-1.0f,  -1.0f,-1.0f,  0.0f,-1.0f,  1.0f,-1.0f,  2.0f,-1.0f,
        -2.0f,-2.0f,  -1.0f,-2.0f,  0.0f,-2.0f,  1.0f,-2.0f,  2.0f,-2.0f
    };
    memcpy(array5x5, array50, 50*sizeof(float));
    
    weight5x5Uniform = [filterProgram uniformIndex:@"u_weight5x5"];
    float weight25[25] = {
        1.0f,  4.0f,  7.0f,  4.0f, 1.0f,
        4.0f, 16.0f, 26.0f, 16.0f, 4.0f,
        7.0f, 26.0f, 41.0f, 26.0f, 7.0f,
        4.0f, 16.0f, 26.0f, 16.0f, 4.0f,
        1.0f,  4.0f,  7.0f,  4.0f, 1.0f
    };
    memcpy(weight5x5, weight25, 25*sizeof(float));
    
    [self setArray];
    [self setHSV];
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setWidth:(int)w height:(int)h
{
    width = w;
    widthStep = 1.0f/(float)width;
    height = h;
    heightStep = 1.0f/(float)height;
    
    [self setFloat:widthStep forUniform:widthStepUniform program:filterProgram];
    [self setFloat:heightStep forUniform:heightStepUniform program:filterProgram];
}

- (void)setSmoothMode:(int)mode
{
    smoothMode = mode;
    
    [self setInteger:smoothMode forUniform:smoothModeUniform program:filterProgram];
}

- (void) setDiff:(float)df
{
    diff = df;
    [self setFloat:diff forUniform:diffUniform program:filterProgram];
}

- (void)setTargetColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a
{
    targetColor[0] = r;
    targetColor[1] = g;
    targetColor[2] = b;
    targetColor[3] = a;
    
    [self setFloatArray:targetColor length:4 forUniform:targetColorUniform program:filterProgram];
}

- (void)setHSV
{
    [self setFloat:blackValueMax forUniform:blackValueMaxUniform program:filterProgram];
    [self setFloat:graySaturationMax forUniform:graySaturationMaxUniform program:filterProgram];
    [self setFloat:grayValueMax forUniform:grayValueMaxUniform program:filterProgram];
    [self setFloat:redHueMin forUniform:redHueMinUniform program:filterProgram];
    [self setFloat:redHueMax forUniform:redHueMaxUniform program:filterProgram];
    [self setFloat:orangeHueMin forUniform:orangeHueMinUniform program:filterProgram];
    [self setFloat:orangeHueMax forUniform:orangeHueMaxUniform program:filterProgram];
    [self setFloat:yellowHueMin forUniform:yellowHueMinUniform program:filterProgram];
    [self setFloat:yellowHueMax forUniform:yellowHueMaxUniform program:filterProgram];
    [self setFloat:greenHueMin forUniform:greenHueMinUniform program:filterProgram];
    [self setFloat:greenHueMax forUniform:greenHueMaxUniform program:filterProgram];
    [self setFloat:cyanHueMin forUniform:cyanHueMinUniform program:filterProgram];
    [self setFloat:cyanHueMax forUniform:cyanHueMaxUniform program:filterProgram];
    [self setFloat:blueHueMin forUniform:blueHueMinUniform program:filterProgram];
    [self setFloat:blueHueMax forUniform:blueHueMaxUniform program:filterProgram];
    [self setFloat:purpleHueMin forUniform:purpleHueMinUniform program:filterProgram];
    [self setFloat:purpleHueMax forUniform:purpleHueMaxUniform program:filterProgram];
}

- (void)setArray
{
    [self setFloatArray:array3x3  length:18 forUniform:array3x3Uniform  program:filterProgram];
    [self setFloatArray:weight3x3 length:9  forUniform:weight3x3Uniform program:filterProgram];
    [self setFloatArray:array5x5  length:50 forUniform:array5x5Uniform  program:filterProgram];
    [self setFloatArray:weight5x5 length:25 forUniform:weight5x5Uniform program:filterProgram];
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex
{
    [super setInputSize:CGSizeMake(newSize.width, newSize.height) atIndex:textureIndex];
    [self setWidth:newSize.width height:newSize.height];
}

@end

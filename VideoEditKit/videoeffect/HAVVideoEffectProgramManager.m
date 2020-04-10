//
//  HAVVideoEffectProgramManager.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVVideoEffectProgramManager.h"
#import "HAVVideoEffect.h"
#undef sin
#undef pow
#undef floor
#undef ceil
#undef sqrt
#undef cos
#undef sqrt
#undef exp

NSString *const kGPUImageVideoEffectVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const kGPUVideoEffectShaderString1 = SHADER_STRING(
                                                             precision highp float;
                                                             varying highp vec2 textureCoordinate;
                                                             uniform sampler2D inputImageTexture;
                                                             uniform float iGlobalTime;
                                                             vec2 scaleuv(vec2 uv, float s){
                                                                 return (uv - vec2(0.5, 0.5)) * s + vec2(0.5, 0.5);
                                                             }
                                                             void main()
{
    vec2 uv = textureCoordinate;
    float f = fract(iGlobalTime * 1.5);
    f = f *                                                                                                  (f, 0.5);
    float scale = 1.0 - 0.8 * f;
    vec4 color1 = texture2D(inputImageTexture, uv);
    vec4 color2 = texture2D(inputImageTexture, scaleuv(uv, scale));
    
    gl_FragColor = color1 * 0.8  + color2 * 0.2;
}
                                                             );

//NSString *const kGPUVideoEffectShaderString2 = SHADER_STRING(
//                                                             precision highp float;
//                                                             uniform float  iGlobalTime;
//                                                             varying highp vec2 textureCoordinate;
//                                                             uniform sampler2D inputImageTexture;
//
//                                                             float rand () {
//                                                                 return fract(sin(iGlobalTime)*1e4);
//                                                             }
//                                                             void main( )
//{
//    vec2 uv = textureCoordinate.xy ;
//
//    vec2 uvR = uv;
//    vec2 uvB = uv;
//
//    uvR.x = uv.x * 1.0 - rand() * 0.02 * 0.8;
//    uvB.y = uv.y * 1.0 + rand() * 0.02 * 0.8;
//
//    //
//    if(uv.y < rand() && uv.y > rand() -0.1 && sin(iGlobalTime) < 0.0)
//    {
//        uv.x = (uv + 0.02 * rand()).x;
//    }
//    //
//    vec4 c;
//    c.r = texture2D(inputImageTexture, uvR).r;
//    c.g = texture2D(inputImageTexture, uv).g;
//    c.b = texture2D(inputImageTexture, uvB).b;
//
//    //
//    float scanline = sin( uv.y * 800.0 * rand())/30.0;
//    c *= 1.0 - scanline;
//
//    //vignette
//    float vegDist = length(( 0.5 , 0.5 ) - uv);
//    c *= 1.0 - vegDist * 0.6;
//
//    gl_FragColor = c;
//});

NSString *const kGPUVideoEffectShaderString2 = SHADER_STRING(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform float iGlobalTime;
                                                             
const vec2 iResolution = vec2(720.0,1280.0);
                                                             float normpdf(in float x, in float sigma)
                                                             {
    return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}
                                                             
                                                             
                                                             void main()
{
   
        
        //declare stuff
        const int mSize = 31;
        const int kSize = (mSize-1)/2;
        float kernel[mSize];
        vec3 final_colour = vec3(0.0);
        
//        //create the 1-D kernel
//        float sigma = 7.0;
     float sigma = (sin(iGlobalTime*2.0)*0.5 + 0.5) * 15.0;
        float Z = 0.0;
        for (int j = 0; j <= kSize; ++j)
        {
            kernel[kSize+j] = kernel[kSize-j] = normpdf(float(j), sigma);
        }
        
        //get the normalization factor (as the gaussian has been clamped)
        for (int j = 0; j < mSize; ++j)
        {
            Z += kernel[j];
        }
        
        //read out the texels
        for (int i=-kSize; i <= kSize; ++i)
        {
            for (int j=-kSize; j <= kSize; ++j)
            {
                final_colour += kernel[kSize+j]*kernel[kSize+i]*texture2D(inputImageTexture, (gl_FragCoord.xy+vec2(float(i),float(j))) / iResolution.xy).rgb;
                
            }
        }
        gl_FragColor = vec4(final_colour/(Z*Z), 1.0);
    
});

NSString *const kGPUVideoEffectShaderString3 = SHADER_STRING(
                                                             precision highp float;
                                                             uniform float  iGlobalTime;
                                                             varying highp vec2 textureCoordinate;
                                                             uniform sampler2D inputImageTexture;
                                                             float sat( float t ) {
                                                                 return clamp( t, 0.0, 1.0 );
                                                             }
                                                             
                                                             vec2 sat( vec2 t ) {
                                                                 return clamp( t, 0.0, 1.0 );
                                                             }
                                                             
                                                             //remaps inteval [a;b] to [0;1]
                                                             float remap  ( float t, float a, float b ) {
                                                                 return sat( (t - a) / (b - a) );
                                                             }
                                                             
                                                             //note: /\ t=[0;0.5;1], y=[0;1;0]
                                                             float linterp( float t ) {
                                                                 return sat( 1.0 - abs( 2.0*t - 1.0 ) );
                                                             }
                                                             
                                                             vec3 spectrum_offset( float t ) {
                                                                 vec3 ret;
                                                                 float lo = step(t,0.5);
                                                                 float hi = 1.0-lo;
                                                                 float w = linterp( remap( t, 1.0/6.0, 5.0/6.0 ) );
                                                                 float neg_w = 1.0-w;
                                                                 ret = vec3(lo,1.0,hi) * vec3(neg_w, w, neg_w);
                                                                 return pow( ret, vec3(1.0/2.2) );
                                                             }
                                                             
                                                             //note: [0;1]
                                                             float rand( vec2 n ) {
                                                                 return fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453);
                                                             }
                                                             
                                                             //note: [-1;1]
                                                             float srand( vec2 n ) {
                                                                 return rand(n) * 2.0 - 1.0;
                                                             }
                                                             
                                                             float mytrunc( float x, float num_levels )
{
    return floor(x*num_levels) / num_levels;
}
                                                             vec2 mytrunc( vec2 x, float num_levels )
{
    return floor(x*num_levels) / num_levels;
}
                                                             
                                                             void main()
{
    vec2 uv = textureCoordinate.xy;
    //    uv.y = 1.0 - uv.y;
    
    float time = mod(iGlobalTime, 32.0); // + modelmat[0].x + modelmat[0].z;
    
    float GLITCH = 0.1; //+ iMouse.x / iResolution.x;
    
    float gnm = sat( GLITCH );
    float rnd0 = rand( mytrunc( vec2(time, time), 6.0 ) );
    float r0 = sat((1.0-gnm)*0.7 + rnd0);
    float rnd1 = rand( vec2(mytrunc( uv.x, 10.0*r0 ), time) ); //horz
    //float r1 = 1.0f - sat( (1.0f-gnm)*0.5f + rnd1 );
    float r1 = 0.5 - 0.5 * gnm + rnd1;
    r1 = 1.0 - max( 0.0, ((r1<1.0) ? r1 : 0.9999999) ); //note: weird ass bug on old drivers
    float rnd2 = rand( vec2(mytrunc( uv.y, 40.0*r1 ), time) ); //vert
    float r2 = sat( rnd2 );
    
    float rnd3 = rand( vec2(mytrunc( uv.y, 10.0*r0 ), time) );
    float r3 = (1.0-sat(rnd3+0.8)) - 0.1;
    
    float pxrnd = rand( uv + time );
    
    float ofs = 0.05 * r2 * GLITCH * ( rnd0 > 0.5 ? 1.0 : -1.0 );
    ofs += 0.5 * pxrnd * ofs;
    
    uv.y += 0.1 * r3 * GLITCH;
    
    const int NUM_SAMPLES = 10;
    const float RCP_NUM_SAMPLES_F = 1.0 / float(NUM_SAMPLES);
    
    vec4 sum = vec4(0.0);
    vec3 wsum = vec3(0.0);
    for( int i=0; i<NUM_SAMPLES; ++i )
    {
        float t = float(i) * RCP_NUM_SAMPLES_F;
        uv.x = sat( uv.x + ofs * t );
        vec4 samplecol = texture2D( inputImageTexture, uv, -10.0 );
        vec3 s = spectrum_offset(t);
        samplecol.rgb = samplecol.rgb * s;
        sum += samplecol;
        wsum += s;
    }
    sum.rgb /= wsum;
    sum.a *= RCP_NUM_SAMPLES_F;
    
    gl_FragColor.a = sum.a;
    gl_FragColor.rgb = sum.rgb; // * outcol0.a;
});


NSString *const kGPUVideoEffectShaderString4 = SHADER_STRING(
                                                             precision highp float;
                                                             uniform float  iGlobalTime;
                                                             varying highp vec2 textureCoordinate;
                                                             uniform sampler2D inputImageTexture;
                                                             void main()
{
    vec2 uv = textureCoordinate;
    if(uv.x > 0.5){
        uv.x = 1.0 - uv.x;
    }
    gl_FragColor = texture2D(inputImageTexture, uv);
}
                                                             );

NSString *const kGPUVideoEffectShaderString5 = SHADER_STRING(
                                                             precision highp float;
                                                             varying highp vec2 textureCoordinate;
                                                             uniform sampler2D inputImageTexture;
                                                             uniform float iGlobalTime;
                                                             vec2 scaleuv(vec2 uv, float s){
                                                                 return (uv - vec2(0.5, 0.5)) * s + vec2(0.5, 0.5);
                                                             }
                                                             void main()
{
    vec2 uv = textureCoordinate;
    float f = fract(iGlobalTime * 1.5);
    f = f * step(f, 0.5);
    float offsetr = 0.04 * f;
    float offsetb = 0.02 * f;
    float scale = 1.0 - 0.3 * f;
    float r = texture2D(inputImageTexture, scaleuv(uv + vec2(-offsetr, -offsetr), scale)).r;
    float b = texture2D(inputImageTexture, scaleuv(uv + vec2(-offsetb, -offsetb), scale)).b;
    vec4 color1 = texture2D(inputImageTexture, scaleuv(uv , scale));
    
    gl_FragColor = vec4(color1.r * 0.2 + r * 0.8, color1.g, color1.b * 0.6 + b * 0.4, 1.);
}
                                                             );

NSString *const kGPUVideoEffectShaderString6 = SHADER_STRING(
                                                             precision highp float;
                                                             varying highp vec2 textureCoordinate;
                                                             uniform sampler2D inputImageTexture;
                                                             uniform float iGlobalTime;
                                                             
                                                             void main()
{
    float c = ceil(mod(iGlobalTime * 2., 3.));
    vec2 uv = fract(textureCoordinate * c);
    gl_FragColor = texture2D(inputImageTexture, uv);
}
                                                             );

NSString *const kGPUVideoEffectShaderString7 = SHADER_STRING(
                                                             precision highp float;
                                                             varying highp vec2 textureCoordinate;
                                                             uniform sampler2D inputImageTexture;
                                                             uniform sampler2D inputImageTexture2;
                                                             uniform float iGlobalTime;
                                                             void main()
{
    gl_FragColor = mix(texture2D(inputImageTexture, textureCoordinate),texture2D(inputImageTexture2, textureCoordinate),0.75);
}
                                                             );

//NSString *const kGPUVideoEffectShaderString7 = SHADER_STRING(
//                                                             precision highp float;
//                                                             varying highp vec2 textureCoordinate;
//                                                             uniform sampler2D inputImageTexture;
//                                                             uniform float iGlobalTime;
//
//                                                             void main()
//{
//    vec2 uv = textureCoordinate;
//    float y =
//    0.7*sin((uv.y + iGlobalTime) * 4.0) * 0.038 +
//    0.3*sin((uv.y + iGlobalTime) * 8.0) * 0.010 +
//    0.05*sin((uv.y + iGlobalTime) * 40.0) * 0.05;
//
//    float x =
//    0.5*sin((uv.y + iGlobalTime) * 5.0) * 0.1 +
//    0.2*sin((uv.x + iGlobalTime) * 10.0) * 0.05 +
//    0.2*sin((uv.x + iGlobalTime) * 30.0) * 0.02;
//
//    gl_FragColor = texture2D(inputImageTexture, 0.79*(uv + vec2(y+0.11, x+0.11)));
//}
//                                                             );

NSString *const kGPUVideoEffectShaderString8 = SHADER_STRING(
                                                             precision highp float;
                                                             varying highp vec2 textureCoordinate;
                                                             uniform sampler2D inputImageTexture;
                                                             uniform float iGlobalTime;
                                                             uniform vec2 iResolution;
                                                             float d;
                                                             vec2 center = vec2(0.5,0.5);
                                                             float speed = 0.4;
                                                             vec3 bg(vec2 uv)
{
    float invAr = 16. / 9.;
    
    vec3 col = vec4(.0, .5 ,0.5,1.0).xyz;
    
    vec3 texcol;
    
    float x = (center.x-uv.x);
    float y = (center.y-uv.y) *invAr;
    
    float r = -sqrt(x*x + y*y); //uncoment this line to symmetric ripples
    float z = 1.0 + 0.8*sin((r+iGlobalTime*speed)/0.06);
    
    texcol.x = z;
    texcol.y = z;
    texcol.z = z;
    
    return col*texcol;
}
                                                             
                                                             float lookup(vec2 p, float dx, float dy)
{
    vec2 uv = (p.xy + vec2(dx * d, dy * d)) / iResolution.xy;
    vec4 c = texture2D(inputImageTexture, uv.xy);
    
    // return as luma
    return 0.2126*c.r + 0.7152*c.g + 0.0722*c.b;
}
                                                             
                                                             void main()
{
    d = 2.; // kernel offset
    vec2 p = gl_FragCoord.xy;
    
    // simple sobel edge detection
    float gx = 0.0;
    gx += -1.0 * lookup(p, -1.0, -1.0);
    gx += -2.0 * lookup(p, -1.0,  0.0);
    gx += -1.0 * lookup(p, -1.0,  1.0);
    gx +=  1.0 * lookup(p,  1.0, -1.0);
    gx +=  2.0 * lookup(p,  1.0,  0.0);
    gx +=  1.0 * lookup(p,  1.0,  1.0);
    
    float gy = 0.0;
    gy += -1.0 * lookup(p, -1.0, -1.0);
    gy += -2.0 * lookup(p,  0.0, -1.0);
    gy += -1.0 * lookup(p,  1.0, -1.0);
    gy +=  1.0 * lookup(p, -1.0,  1.0);
    gy +=  2.0 * lookup(p,  0.0,  1.0);
    gy +=  1.0 * lookup(p,  1.0,  1.0);
    
    float g = gx*gx + gy*gy;
    
    vec2 uv =  p / iResolution.xy;//uv
    vec4 col = texture2D(inputImageTexture, textureCoordinate);
    
    vec4 bgColor = vec4(bg(uv), 1.);
    
    gl_FragColor = col + bgColor * g;
}
                                                             );
NSString *const kGPUVideoEffectShaderString9 = SHADER_STRING(precision highp float;
                                                             varying highp vec2 textureCoordinate;
                                                             uniform sampler2D inputImageTexture;
                                                             uniform float iGlobalTime;
                                                             void main()
{
    float c = 2.;
    float speedTime = 2. * iGlobalTime;
    float s = mod(ceil(speedTime), 2.);
    
    float mx = textureCoordinate.x + s*(step((1.0-textureCoordinate.y), .5) * 2. - 1.) * fract(speedTime) * .5 + 1.;
    float my = textureCoordinate.y - (1.-s) *(step((1.0-textureCoordinate.x), .5) * 2. - 1.) * fract(speedTime) * .5 + 1.;
    
    vec2 uv = fract(vec2(mx, my) * c);
    
    gl_FragColor = texture2D(inputImageTexture, uv);
    
});
NSString *const kGPUVideoEffectShaderString10 = SHADER_STRING(precision highp float;
                                                              varying highp vec2 textureCoordinate;
                                                              uniform sampler2D inputImageTexture;
                                                              uniform float iGlobalTime;
                                                              
                                                              void main()
{
    vec2 p = textureCoordinate * 2. - vec2(1.);
    p.y = p.y * 16./9.;
    float f = fract(iGlobalTime);
    f = f * step(f, 0.75) * 2.677 * 3.14;
    vec2 cst = vec2( cos(f), sin(f) );
    //mat2 rot = (1.0 - 0.5 * sin(f / 2.))*mat2(cst.x,-cst.y,cst.y,cst.x);
    
    vec2 rp = (1.0 - 0.6 * sin(f / 2.)) * p;
    rp.y = rp.y * 9./16.;
    gl_FragColor = texture2D(inputImageTexture, (rp + vec2(1.))*0.5);
});
NSString *const kGPUVideoEffectShaderString11 = SHADER_STRING(
                                                              precision highp float;
                                                              varying highp vec2 textureCoordinate;
                                                              uniform sampler2D inputImageTexture;
                                                              uniform float iGlobalTime;
                                                              const float STRENGTH = 0.6;
                                                              const float PI = 3.141592653589793;
                                                              float Linear_ease(in float begin, in float change, in float duration, in float time) {
                                                                  return change * time / duration + begin;
                                                              }
                                                              float Exponential_easeInOut(in float begin, in float change, in float duration, in float time) {
                                                                  if (time == 0.0)
                                                                      return begin;
                                                                  else if (time == duration)
                                                                      return begin + change;
                                                                  time = time / (duration / 2.0);
                                                                  if (time < 1.0)
                                                                      return change / 2.0 * pow(2.0, 10.0 * (time - 1.0)) + begin;
                                                                  return change / 2.0 * (-pow(2.0, -10.0 * (time - 1.0)) + 2.0) + begin;
                                                              }
                                                              
                                                              float Sinusoidal_easeInOut(in float begin, in float change, in float duration, in float time) {
                                                                  return -change / 2.0 * (cos(PI * time / duration) - 1.0) + begin;
                                                              }
                                                              
                                                              float random(in vec3 scale, in float seed) {
                                                                  return fract(sin(iGlobalTime) * 43758.5453);
                                                              }
                                                              vec3 crossFade(in vec2 uv) {
                                                                  return texture2D(inputImageTexture, uv).rgb;
                                                              }
                                                              vec4 getMask(vec2 uv)
                                                              {
                                                                  vec4 color3 = vec4(1., 1., 1., 1.);
                                                                  vec4 color2 = vec4(.64, .9, 1., 1.);
                                                                  vec4 color1 = vec4(.76, .58, 1., 1.);
                                                                  vec4 retColor;
                                                                  if(uv.y > 0.5){
                                                                      retColor =  mix(color2, color1, (uv.y-0.5) * 2.0);
                                                                  } else {
                                                                      retColor =  mix(color3, color2, uv.y*2.0);
                                                                  }
                                                                  
                                                                  return retColor;
                                                              }
                                                              float psAdd(float a, float b){
                                                                  if(a<=.5){
                                                                      return a * b * 2.;
                                                                  } else {
                                                                      return 1. - 2. *(1. -a)*(1.-b);
                                                                  }
                                                              }
                                                              void main() {
                                                                  vec2 texCoord = textureCoordinate;
                                                                  float progress = sin(iGlobalTime * 2.) * 0.5 + 0.5;
                                                                  // Linear interpolate center across center half of the image
                                                                  vec2 center = vec2(Linear_ease(0.5, 0.0, 1.0, progress),0.5);
                                                                  // Mirrored sinusoidal loop. 0->strength then strength->0
                                                                  float strength = Sinusoidal_easeInOut(0.0, STRENGTH, 0.5, progress);
                                                                  vec3 color = vec3(0.0);
                                                                  float total = 0.0;
                                                                  vec2 toCenter = center - texCoord;
                                                                  /* randomize the lookup values to hide the fixed number of samples */
                                                                  float offset = random(vec3(12.9898, 78.233, 151.7182), 0.0)*0.5;
                                                                  for (float t = 0.0; t <= 20.0; t++) {
                                                                      float percent = (t + offset) / 20.0;
                                                                      float weight = 1.0 * (percent - percent * percent);
                                                                      color += crossFade(texCoord + toCenter * percent * strength) * weight;
                                                                      total += weight;
                                                                  }
                                                                  vec4 oriColor = vec4(color / total, 1.);
                                                                  vec4 maskColor = getMask(texCoord);
                                                                  float ratio = strength * .75;
                                                                  vec4 colorRet = vec4(psAdd(oriColor.r, maskColor.r),
                                                                                       psAdd(oriColor.g, maskColor.g),
                                                                                       psAdd(oriColor.b, maskColor.b),1.);
                                                                  gl_FragColor = mix(oriColor, colorRet, ratio);
                                                              }
                                                              );

NSString *const kGPUVideoEffectShaderString12 = SHADER_STRING(
                                                              precision highp float; //指定默认精度
                                                              varying highp vec2 textureCoordinate;
                                                              uniform sampler2D inputImageTexture;
                                                              uniform float iGlobalTime;
                                                              float psAdd(float a, float b){
                                                                  if(a<=0.5){
                                                                      return a * b * 2.0;
                                                                  } else {
                                                                      return 1.0 - 2.0 *(1.0 -a)*(1.0-b);
                                                                  }
                                                              }
                                                              
                                                              vec3 hsb2rgb(vec3 c ){
                                                                  vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                                                                                           6.0)-3.0)-1.0,
                                                                                   0.0,1.0 );
                                                                  rgb = rgb*rgb*(3.0-2.0*rgb);
                                                                  return c.z * mix(vec3(1.0), rgb, c.y);
                                                              }
                                                              void main() {
                                                                  float time = iGlobalTime * 40.0;
                                                                  float beats[10] ;//= float[](1., 0., 1., 0., .5, .5, .5, 0., 1., 1.);
                                                                  beats[0] = 1.0;
                                                                  beats[1] = 0.0;
                                                                  beats[2] = 1.0;
                                                                  beats[3] = 0.0;
                                                                  beats[4] = 0.5;
                                                                  beats[5] = 0.5;
                                                                  beats[6] = 0.5;
                                                                  beats[7] = 0.0;
                                                                  beats[8] = 1.0;
                                                                  beats[9] = 1.0;
                                                                  
                                                                  float progress = (cos(time + 3.14159) / 2. + .5 ) * beats[int(floor(mod(time /2./ 3.14159, 10.)))];
                                                                  float timesPi = time / 2. / 3.14159 + .5;
                                                                  float colorIndex = floor(mod(timesPi, 7.)) / 6.;
                                                                  vec4 colorOri = texture2D(inputImageTexture, textureCoordinate);
                                                                  vec3 color = hsb2rgb(vec3(colorIndex,1.0,1.0));
                                                                  vec4 colorAdd = vec4(mix(color, vec3(0.,0.,0.), 1.0-textureCoordinate.y), 1.);
                                                                  vec4 white = vec4(1.);
                                                                  vec4 colorRet = white - (white - colorOri) * (white - colorAdd);
                                                                  gl_FragColor = mix(colorOri, colorRet, progress);
                                                              }
                                                              );


NSString *const kGPUVideoEffectShaderString13 = SHADER_STRING(
                                                              precision highp float;
                                                              varying highp vec2 textureCoordinate;
                                                              uniform sampler2D inputImageTexture;
                                                              uniform float iGlobalTime;
                                                              uniform vec2 iResolution;
                                                              float d;
                                                              vec3 rgb2hsb(vec3 c ){
                                                                  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                                                                  vec4 p = mix(vec4(c.bg, K.wz),
                                                                               vec4(c.gb, K.xy),
                                                                               step(c.b, c.g));
                                                                  vec4 q = mix(vec4(p.xyw, c.r),
                                                                               vec4(c.r, p.yzx),
                                                                               step(p.x, c.r));
                                                                  float d = q.x - min(q.w, q.y);
                                                                  float e = 1.0e-10;
                                                                  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),d / (q.x + e),q.x);
                                                              }
                                                              
                                                              vec3 hsb2rgb(vec3 c ){
                                                                  vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0,0.0,1.0 );
                                                                  rgb = rgb*rgb*(3.0-2.0*rgb);
                                                                  return c.z * mix(vec3(1.0), rgb, c.y);
                                                              }
                                                              
                                                              float lookup(vec2 p, float dx, float dy)
{
    vec2 uv = p + vec2(dx * d, dy * d) / iResolution.xy;
    vec4 c = texture2D(inputImageTexture, uv.xy);
    
    // return as luma
    return 0.2126*c.r + 0.7152*c.g + 0.0722*c.b;
}
                                                              
                                                              vec4 blendHardLight(vec4 blend, vec4 base){
                                                                  return vec4(base.r < 0.5 ? (2.0 * base.r * blend.r) : (1.0 - 2.0 * (1.0 - base.r) * (1.0 - blend.r)),base.g < 0.5 ? (2.0 * base.g * blend.g) : (1.0 - 2.0 * (1.0 - base.g) * (1.0 - blend.g)),base.b < 0.5 ? (2.0 * base.b * blend.b) : (1.0 - 2.0 * (1.0 - base.b) * (1.0 - blend.b)),                    1.0);
                                                              }
                                                              
                                                              void main()
{
    d = 4.0; // kernel offset
    vec2 uv = textureCoordinate;
    
    // simple sobel edge detection
    float gx = 0.0;
    gx += -1.0 * lookup(uv, -1.0, -1.0);
    gx += -2.0 * lookup(uv, -1.0,  0.0);
    gx += -1.0 * lookup(uv, -1.0,  1.0);
    gx +=  1.0 * lookup(uv,  1.0, -1.0);
    gx +=  2.0 * lookup(uv,  1.0,  0.0);
    gx +=  1.0 * lookup(uv,  1.0,  1.0);
    
    float gy = 0.0;
    gy += -1.0 * lookup(uv, -1.0, -1.0);
    gy += -2.0 * lookup(uv,  0.0, -1.0);
    gy += -1.0 * lookup(uv,  1.0, -1.0);
    gy +=  1.0 * lookup(uv, -1.0,  1.0);
    gy +=  2.0 * lookup(uv,  0.0,  1.0);
    gy +=  1.0 * lookup(uv,  1.0,  1.0);
    
    float g = sqrt(gx*gx + gy*gy);
    
    vec4 col = texture2D(inputImageTexture, uv);
    
    vec4 color1 = blendHardLight(col, col * g);
    vec3 hsb1 = rgb2hsb(color1.rgb);
    hsb1.g += 0.5;
    
    vec4 color2 = vec4(hsb2rgb(hsb1), 1.0);
    color2 += vec4(0.2, -0.05, -0.1, 0.0);//vec4(0.078, -0.019, -0.039, 0.0);
    vec3 hsb2 = rgb2hsb(color2.rgb);
    
    vec4 color3 = vec4(hsb2rgb(vec3(hsb2.r, hsb2.g, hsb1.b)), 1.0);
    
    gl_FragColor = color3;
});
NSString *const kGPUVideoEffectShaderString14 = SHADER_STRING(
                                                              precision highp float;
                                                              varying highp vec2 textureCoordinate;
                                                              uniform sampler2D inputImageTexture;
                                                              uniform float iGlobalTime;
                                                              uniform vec2 iResolution;
                                                              void main()
{
    vec4 color = texture2D(inputImageTexture, textureCoordinate);
    gl_FragColor = vec4(vec3(1.0) - color.rgb, 1.0);
});

//灵魂出窍
NSString *const kGPUVideoEffectShaderString15 = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform float iGlobalTime;
 
 uniform int uHasSoulTexture;
 
 void main()
 {
     if(uHasSoulTexture == 0)
     {
         gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
     }else if(uHasSoulTexture == 1)
     {
         gl_FragColor = mix(texture2D(inputImageTexture2, textureCoordinate),texture2D(inputImageTexture, textureCoordinate),0.2);
     }
 }
 );

//高斯模糊
NSString *const kGPUVideoEffectShaderString16 = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform float iGlobalTime;
 
 void main()
 {
      float da = 1280.0;
      float db = 720.0;
      vec3 centerColor;
      vec2 coordinate = textureCoordinate;
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
      float centerG = texture2D(inputImageTexture, coordinate).g;
      float weightSum;
      float gSum;
      float prob;
      float diffCenterG;
      float weight;
      float norFactor = 3.6;
      weightSum = 0.2;
      gSum = centerG * 0.2;
      
      prob = texture2D(inputImageTexture, gausCoord0).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord1).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord2).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord3).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord4).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord5).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord6).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord7).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord8).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord9).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord10).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord11).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.08 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord12).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.1 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord13).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.1 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord14).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.1 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord15).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.1 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord16).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.1 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord17).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.1 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord18).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.1 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      prob = texture2D(inputImageTexture, gausCoord19).g;
      diffCenterG = min(abs(centerG - prob) * norFactor, 1.0);
      weight = 0.2 * (1.0 - diffCenterG);
      weightSum += weight;
      gSum += prob * weight;
      
      gSum = gSum / weightSum;
      
      centerColor = texture2D(inputImageTexture, coordinate).rgb;
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
    
    const smoothDegree = 1.0;
//      smoothResult = mix(centerColor, smoothResult, uSmoothDegree);
    smoothResult = mix(centerColor, smoothResult, smoothDegree);
      vec4 result = vec4(pow(smoothResult, vec3(0.96)), 1.0);
    
    result = vec4(1.0,0.0,0.0,0.0);
      gl_FragColor = result;
 }
 );

@interface HAVVideoEffectProgramManager()

@property (nonatomic,  strong) NSMutableArray *effectStrings;
@property (nonatomic,  strong) NSMutableDictionary *dictory;

@end

@implementation HAVVideoEffectProgramManager

- (instancetype) init{
    self = [super init];
    if(self){
        self.dictory = [NSMutableDictionary dictionary];
        self.effectStrings = [NSMutableArray array];
        [_effectStrings addObject:kGPUVideoEffectShaderString1];
        [_effectStrings addObject:kGPUVideoEffectShaderString2];
        [_effectStrings addObject:kGPUVideoEffectShaderString3];
        [_effectStrings addObject:kGPUVideoEffectShaderString4];
        [_effectStrings addObject:kGPUVideoEffectShaderString5];
        [_effectStrings addObject:kGPUVideoEffectShaderString6];
        [_effectStrings addObject:kGPUVideoEffectShaderString7];
        [_effectStrings addObject:kGPUVideoEffectShaderString8];
        [_effectStrings addObject:kGPUVideoEffectShaderString9];
        [_effectStrings addObject:kGPUVideoEffectShaderString10];
        [_effectStrings addObject:kGPUVideoEffectShaderString11];
        [_effectStrings addObject:kGPUVideoEffectShaderString12];
        [_effectStrings addObject:kGPUVideoEffectShaderString13];
        [_effectStrings addObject:kGPUVideoEffectShaderString14];
        [_effectStrings addObject:kGPUVideoEffectShaderString15];
        [_effectStrings addObject:kGPUVideoEffectShaderString16];
        
    }
    return self;
}

-(void) bindProgram:(HAVVideoEffect *) effect withSharedId:(NSInteger) shaderId{
    NSInteger shaderIndex = shaderId - 1;
    if((shaderIndex >=0) && (shaderIndex < self.effectStrings.count)){
        NSString *fragmentShaderString = [self.effectStrings objectAtIndex:shaderIndex];
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageContext useImageProcessingContext];
            
            GLProgram *filterProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVideoEffectVertexShaderString fragmentShaderString:fragmentShaderString];
            
            if (!filterProgram.initialized)
            {
                [self initializeAttributes:filterProgram];
                
                if (![filterProgram link]){
                    NSAssert(NO, @"Filter shader link failed");
                }
            }
            
            effect.filterPositionAttribute = [filterProgram attributeIndex:@"position"];
            effect.filterTextureCoordinateAttribute = [filterProgram attributeIndex:@"inputTextureCoordinate"];
            effect.filterInputTextureUniform = [filterProgram uniformIndex:@"inputImageTexture"];
            effect.filterInputTextureUniform2 = [filterProgram uniformIndex:@"inputImageTexture2"];
            
            effect.uHasSoulTexture = [filterProgram uniformIndex:@"uHasSoulTexture"];
            
            
            effect.program = filterProgram;
            // This does assume a name of "inputImageTexture" for the fragment shader
            
        });
    }
}

-(GLProgram *) createProgramWithId:(NSInteger) shaderId{
    NSInteger shaderIndex = shaderId - 1;
    
    if((shaderIndex >= 0) && (shaderIndex < self.effectStrings.count)){
        
        NSString *fragmentShaderString = [self.effectStrings objectAtIndex:shaderIndex];
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageContext useImageProcessingContext];
            
            GLProgram *filterProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVideoEffectVertexShaderString fragmentShaderString:fragmentShaderString];
            
            if (!filterProgram.initialized)
            {
                [self initializeAttributes : filterProgram];
                
                if (![filterProgram link])
                {
                    NSString *progLog = [filterProgram programLog];
                    NSLog(@"Program link log: %@", progLog);
                    NSString *fragLog = [filterProgram fragmentShaderLog];
                    NSLog(@"Fragment shader compile log: %@", fragLog);
                    NSString *vertLog = [filterProgram vertexShaderLog];
                    NSLog(@"Vertex shader compile log: %@", vertLog);
                    filterProgram = nil;
                    NSAssert(NO, @"Filter shader link failed");
                }
            }
            
            //            filterPositionAttribute = [filterProgram attributeIndex:@"position"];
            //            filterTextureCoordinateAttribute = [filterProgram attributeIndex:@"inputTextureCoordinate"];
            //            filterInputTextureUniform = [filterProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
            
        });
    }
    
    return nil;
}

- (void)initializeAttributes:(GLProgram *) filterProgram;
{
    [filterProgram addAttribute:@"position"];
    [filterProgram addAttribute:@"inputTextureCoordinate"];
    
    // Override this, calling back to this super method, in order to add new attributes to your vertex shader
}

-(GLProgram *) createProgramWithString:(NSString*) shaderString{
    return nil;
}
@end

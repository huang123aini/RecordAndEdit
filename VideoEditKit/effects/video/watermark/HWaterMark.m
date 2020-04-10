//
//  HWaterMark.m
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/9.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HWaterMark.h"
#define KCURRENTVIDEO_FPS  30.0f

@interface HWaterMark()
{
    BOOL _isShowID;
    GLuint texturId;
    GLuint numTextureID;
    GLfloat _texCoords[8];
}
@property (nonatomic, assign) CGSize pictureSize;
@property (nonatomic, assign) CGPoint postionPoint;
@property (nonatomic, strong) UIImage * waterMarkImage;
@property (nonatomic, assign) NSInteger imageCount;
@property (nonatomic, assign) CMTime startTime;
@property (nonatomic, assign) int row;
@property (nonatomic, assign) int column;
@property (nonatomic, assign) float uvWidth ;
@property (nonatomic, assign) float uvHeight;
@property (nonatomic, strong) NSArray *images;

@property (nonatomic, assign) int indexCount;

@property (nonatomic, assign) BOOL isFirstStart;

//绘制ID
@property (nonatomic, strong) UIImage* idImage;
@property (nonatomic, assign) CGSize  idImageSize;
@property (nonatomic, assign) CGPoint idImagePoint;


@property (nonatomic, assign) int rotatinMode;


@end

@implementation HWaterMark

- (GLuint) createWaterMarkTexture:(NSArray *) array
{
    UIImage *image = [array firstObject];
    self.row = 720 / image.size.width;
    int column = ((int)array.count / self.row);
    if(array.count % self.row != 0)
    {
        column += 1;
    }
    self.uvWidth = 1.0f /self.row;
    self.uvHeight = 1.0f/column;
    CGSize size = CGSizeMake(self.row * image.size.width , column * image.size.height);
    
    UIGraphicsBeginImageContext(size);
    int index;
    for (int j = 0; j < column; j++){
        for (int i = 0; i < self.row; i++)
        {
            index = j * self.row + i;
            if(index < array.count)
            {
                UIImage *waterMarkImage = [array objectAtIndex:index];
                [waterMarkImage drawAtPoint:CGPointMake(i * image.size.width,(column - j-1) * image.size.height)];
            }else
            {
            }
        }
    }
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);
    
    glEnable(GL_TEXTURE_2D);
    GLuint textureID ;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    glBindTexture(GL_TEXTURE_2D, 0);
    CGContextRelease(context);
    free(imageData);
    return textureID;
}

- (instancetype) initWithImageArray:(NSArray *) array pictureSize:(CGSize) size postion:(CGPoint) point
{
    self = [super init];
    if(self)
    {
        // self.fps = 25;
        self.pictureSize = size;
        self.postionPoint = point;
        
        self.imageCount = array.count;
        texturId = 0;
        self.images = array;
        self.indexCount = 0;
        self.rotatinMode = kGPUImageNoRotation;
        if(texturId == 0)
        {
            texturId = [self createWaterMarkTexture:self.images];
            self.images = nil;
        }
        
        self.isFirstStart = YES;
    }
    return self;
}
-(void)displayImage:(UIImage*)image pictureSize:(CGSize)size position:(CGPoint)point
{
    _isShowID = YES;
    self.idImage = image;
    self.idImageSize = size;
    self.idImagePoint = point;
}

-(void)showIDImage
{
    
    if (numTextureID == 0)
    {
        numTextureID = [self createTextureWithImage:self.idImage];
        self.idImage = nil;
    }
    GLfloat coordinate[] =
    {
        0,0, //左下
        1,0, //右下
        0,1, //左上
        1,1  //右上
    };
    
    CGFloat leftBottomX =  - self.idImageSize.width  / self.frameBufferSize.width ;
    CGFloat leftBottomY =  - self.idImageSize.height / self.frameBufferSize.height ;
    CGFloat rightBottomX =   self.idImageSize.width  / self.frameBufferSize.width;
    CGFloat rightBottomY =  - self.idImageSize.height / self.frameBufferSize.height;
    CGFloat leftTopX =  - self.idImageSize.width  / self.frameBufferSize.width;
    CGFloat leftTopY =   self.idImageSize.height / self.frameBufferSize.height;
    CGFloat rightTopX =  self.idImageSize.width  / self.frameBufferSize.width;
    CGFloat rightTopY =  self.idImageSize.height / self.frameBufferSize.height;
    GLfloat positonX =  (self.idImagePoint.x - 0.5 * self.frameBufferSize.width) / (0.5 * self.frameBufferSize.width);
    GLfloat positonY = -(self.idImagePoint.y - 0.5 * self.frameBufferSize.height) / (0.5 * self.frameBufferSize.height);
    //左下 0
    leftBottomX += positonX;
    leftBottomY += positonY;
    //右下 1
    rightBottomX += positonX;
    rightBottomY += positonY;
    //左上 2
    leftTopX += positonX;
    leftTopY += positonY;
    //右上 3
    rightTopX += positonX;
    rightTopY += positonY;
    GLfloat position[] = {leftBottomX,leftBottomY,rightBottomX,rightBottomY,leftTopX,leftTopY,rightTopX,rightTopY};
    
    glActiveTexture(GL_TEXTURE6);
    glBindTexture(GL_TEXTURE_2D, numTextureID);
    glUniform1i(self.inputTextureUniform, 6);
    glEnableVertexAttribArray(self.textureCoordinateAttribute);
    glEnableVertexAttribArray(self.positionAttribute);
    glVertexAttribPointer(self.textureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, 0, coordinate);
    glVertexAttribPointer(self.positionAttribute, 2, GL_FLOAT, GL_FALSE, 0, position);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisable(GL_BLEND);
}

-(GLuint)createTextureWithImage:(UIImage*)image
{
    CGImageRef spriteImage = image.CGImage;
    GLuint width = (GLuint)CGImageGetWidth(spriteImage);
    GLuint height = (GLuint)CGImageGetHeight(spriteImage);
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    CGContextRelease(spriteContext);
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    free(spriteData);
    return texName;
}

- (void) drawFrameAtTime:(CMTime) frameTime
{
    if (texturId != 0)
    {
        int index = ((int)(self.fps / KCURRENTVIDEO_FPS * self.indexCount)) % self.imageCount;
        int column = (int)(index / self.row);
        int row = index % self.row;
        //UV 左上 (0,0)
        float leftUVTopX =  row * self.uvWidth;
        float leftUVTopY = column * self.uvHeight;
        //UV 右上 (1,0)
        float rightUVTopX = leftUVTopX + self.uvWidth;
        float rightUVTopY = leftUVTopY;
        //UV 左下 (0,1)
        float leftUVBottomX = leftUVTopX;
        float leftUVBottomY = leftUVTopY + self.uvHeight;
        //UV 右下 (1,1)
        float rightUVBottomX = leftUVTopX + self.uvWidth;
        float rightUVBottomY = leftUVTopY + self.uvHeight;
        GLfloat coordinate[] = {leftUVBottomX,leftUVBottomY,rightUVBottomX,rightUVBottomY,leftUVTopX,leftUVTopY,rightUVTopX,rightUVTopY};
        
        //横屏时交换
        if (self.rotatinMode == UIInterfaceOrientationLandscapeLeft || self.rotatinMode == UIInterfaceOrientationLandscapeRight)
        {
            self.frameBufferSize = CGSizeMake(self.frameBufferSize.height, self.frameBufferSize.width);
        }
        CGFloat leftBottomX =  - self.pictureSize.width  / self.frameBufferSize.width ;
        CGFloat leftBottomY =  - self.pictureSize.height / self.frameBufferSize.height ;
        CGFloat rightBottomX =  self.pictureSize.width  / self.frameBufferSize.width;
        CGFloat rightBottomY =  -self.pictureSize.height / self.frameBufferSize.height;
        
        CGFloat leftTopX =  - self.pictureSize.width  / self.frameBufferSize.width;
        CGFloat leftTopY =  self.pictureSize.height / self.frameBufferSize.height;
        
        CGFloat rightTopX =  self.pictureSize.width  / self.frameBufferSize.width;
        CGFloat rightTopY =  self.pictureSize.height / self.frameBufferSize.height;
        
        GLfloat positonX = (self.postionPoint.x - 0.5 * self.frameBufferSize.width) / (0.5 * self.frameBufferSize.width);
        GLfloat positonY = -(self.postionPoint.y - 0.5 * self.frameBufferSize.height) / (0.5 * self.frameBufferSize.height);
        //左下 0
        leftBottomX += positonX;
        leftBottomY += positonY;
        //右下 1
        rightBottomX += positonX;
        rightBottomY += positonY;
        //左上 2
        leftTopX += positonX;
        leftTopY += positonY;
        //右上 3
        rightTopX += positonX;
        rightTopY += positonY;
        GLfloat postion[] = {leftBottomX,leftBottomY,rightBottomX,rightBottomY,leftTopX,leftTopY,rightTopX,rightTopY};
        glActiveTexture(GL_TEXTURE5);
        glBindTexture(GL_TEXTURE_2D, texturId);
        glUniform1i(self.inputTextureUniform, 5);
        
        [self changeTexCoords:coordinate]; //根据视频旋转更改纹理坐标

        glEnableVertexAttribArray(self.textureCoordinateAttribute);
        glVertexAttribPointer(self.textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, _texCoords);

        glEnableVertexAttribArray(self.positionAttribute);
        glVertexAttribPointer(self.positionAttribute, 2, GL_FLOAT, GL_FALSE, 0, postion);
        
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_BLEND);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glDisable(GL_BLEND);
        
        self.indexCount ++;
        
    }
    
    //ID图显示
    if (_isShowID)
    {
        [self showIDImage];
    }
}

-(void)changeTexCoords:(GLfloat*)texCoords
{
    
    //1.竖直方向
    //2.Home键在上
    //3.Home键在右
    //4.Home键在左
    switch (self.rotatinMode)
    {
        case 1:
        {
            /*kGPUImageNoRotation*/
            for (int i = 0; i < 8; i++)
            {
                _texCoords[i] = *(texCoords + i);
            }
            break;
        }
        case 2:
        {
            /*kGPUImageRotate180*/
            _texCoords[0] = *(texCoords + 6);
            _texCoords[1] = *(texCoords + 7);
            _texCoords[2] = *(texCoords + 4);
            _texCoords[3] = *(texCoords + 5);
            
            _texCoords[4] = *(texCoords + 2);
            _texCoords[5] = *(texCoords + 3);
            _texCoords[6] = *(texCoords + 0);
            _texCoords[7] = *(texCoords + 1);
            break;
        }
        case 3:
        {
            /*kGPUImageRotateRight*/
            _texCoords[0] = *(texCoords + 4);
            _texCoords[1] = *(texCoords + 5);
            _texCoords[2] = *(texCoords + 0);
            _texCoords[3] = *(texCoords + 1);
            
            _texCoords[4] = *(texCoords + 6);
            _texCoords[5] = *(texCoords + 7);
            _texCoords[6] = *(texCoords + 2);
            _texCoords[7] = *(texCoords + 3);
            break;
        }
        case 4:
        {
            /*kGPUImageRotateLeft*/
            _texCoords[0] = *(texCoords + 2);
            _texCoords[1] = *(texCoords + 3);
            _texCoords[2] = *(texCoords + 6);
            _texCoords[3] = *(texCoords + 7);
            
            _texCoords[4] = *(texCoords + 0);
            _texCoords[5] = *(texCoords + 1);
            _texCoords[6] = *(texCoords + 4);
            _texCoords[7] = *(texCoords + 5);
            break;
        }
            
        default:
            break;
    }
}

-(void)setRotation:(int)mode
{
    self.rotatinMode = mode;
}

-(void)dealloc
{
    glDeleteTextures(1, &texturId);
}

@end

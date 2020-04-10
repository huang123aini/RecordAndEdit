//
//  HOpenGLTools.h
//  QAVKit
//
//  Created by 黄世平 on 2019/1/22.
//  Copyright © 2019 guowei. All rights reserved.
//

#import <Foundation/Foundation.h>


#define __FILENAME__ (strrchr(__FILE__, '/') ? (strrchr(__FILE__, '/') + 1) : __FILE__)
#define __DEFAULT_TAG "zhedit"

#define ZLogI(fmt, ...) __ZLogFormat(__DEFAULT_TAG, keZmLog_Debug,   __FILENAME__, __LINE__, __FUNCTION__, fmt, ##__VA_ARGS__)
#define ZLogW(fmt, ...) __ZLogFormat(__DEFAULT_TAG, keZmLog_Warning, __FILENAME__, __LINE__, __FUNCTION__, fmt, ##__VA_ARGS__)
#define ZLogE(fmt, ...) __ZLogFormat(__DEFAULT_TAG, keZmLog_Error,   __FILENAME__, __LINE__, __FUNCTION__, fmt, ##__VA_ARGS__)


// for OpenGL ES
#define H_GL_CHECK_ERROR_T(tag) \
{ \
for ( ; ; ) { \
GLenum glErr = glGetError(); \
if (glErr == GL_NO_ERROR) \
break; \
ZLogE("[OpenGL ES %s], glGetError (0x%x)", tag, glErr); \
} \
}

#define H_GL_CHECK_ERROR()   H_GL_CHECK_ERROR_T("");

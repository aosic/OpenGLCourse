//
//  OpenGLESView.m
//  OpenGLCourse_1
//
//  Created by 智衡宋 on 2017/9/19.
//  Copyright © 2017年 智衡宋. All rights reserved.
//

#import "OpenGLESView.h"
#import <OpenGLES/ES2/gl.h>
#import "GLUtil.h"

#include "JpegUtil.h"
typedef struct {
    GLfloat x,y,z;
    GLfloat r,g,b;
} Vertex;

@interface OpenGLESView (){
    EAGLContext           *_context;
    CAEAGLLayer           *_eaglLayer;
    GLuint                 _colorRenderBuffer;
    GLuint                 _frameBuffer;
    
    
    //着色器程序
    GLuint                 _program;
    int                    _vertCount;
    GLuint          _vbo;
    GLuint          _texture;
}

@end

@implementation OpenGLESView

+ (Class)layerClass {
    // 只有 [CAEAGLLayer class] 类型的 layer 才支持在其上描绘 OpenGL 内容。
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self szh_setupLayer];
        [self szh_setupContext];
        [self szh_setupGLProgramShader];
    }
    return self;
}

- (void)layoutSubviews {
    //将当前上下文设置为我们创建的上下文
    [EAGLContext setCurrentContext:_context];
    
    [self szh_destroyFrameBufferAndColorsRenderBuffer];
    [self szh_setupFrameBufferAndColorsRenderBuffer];
    [self szh_render];
}

- (void)dealloc {
    glDeleteBuffers(1, &_vbo);
    glDeleteTextures(1, &_texture);
    glDeleteProgram(_program);
}

#pragma mark -------- 设置layer

- (void)szh_setupLayer {
    
    _eaglLayer  = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
}

#pragma mark -------- 设置当前上下文,初始化

- (void)szh_setupContext {
    _context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

#pragma mark -------- 设置着色器程序

- (void)szh_setupGLProgramShader {
//    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"vert.glsl" ofType:nil];
//    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"frag.glsl" ofType:nil];

    //图像腐蚀
//        NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"corrode_vert.glsl" ofType:nil];
//        NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"corrode_frag.glsl" ofType:nil];
    
    //图像模糊
//        NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"blur_vert.glsl" ofType:nil];
//        NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"blur_frag.glsl" ofType:nil];
    
    //图像膨胀
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"expand_vert.glsl" ofType:nil];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"expand_frag.glsl" ofType:nil];
    
    
    _program = createGLProgramFromFile(vertFile.UTF8String, fragFile.UTF8String);
    
    //调用着色器程序对象
    glUseProgram(_program);

}

#pragma mark -------- 清除帧缓存和渲染缓存

- (void)szh_destroyFrameBufferAndColorsRenderBuffer {
    
    glDeleteFramebuffers(1, &_frameBuffer);
    _frameBuffer = 0;
    glDeleteRenderbuffers(1, &_colorRenderBuffer);
    _colorRenderBuffer = 0;
    
}

#pragma mark -------- 设置帧缓存和渲染缓存,并进行绑定

- (void)szh_setupFrameBufferAndColorsRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    //分配存储空间
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    
}


#pragma mark -------- 绘图

- (void)szh_render {
    
    //清屏
    glClearColor(1.0, 1.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glLineWidth(2.0);
    //设置视口大小
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    //绘制图形
    [self szh_setupVertexData];
    
    //将指定 renderbuffer 呈现在屏幕上，在这里我们指定的是前面已经绑定为当前 renderbuffer 的那个，在 renderbuffer 可以被呈现之前，必须调用renderbufferStorage:fromDrawable: 为之分配存储空间。
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    
   
}

#pragma mark -------- 设置顶点数据

- (void)szh_setupVertexData {
    
    _vertCount = 6;
    
    GLfloat vertices[] = {
        0.5f,  0.5f, 0.0f, 1.0f, 0.0f,   // 右上
        0.5f, -0.5f, 0.0f, 1.0f, 1.0f,   // 右下
        -0.5f, -0.5f, 0.0f, 0.0f, 1.0f,  // 左下
        -0.5f, -0.5f, 0.0f, 0.0f, 1.0f,  // 左下
        -0.5f,  0.5f, 0.0f, 0.0f, 0.0f,  // 左上
        0.5f,  0.5f, 0.0f, 1.0f, 0.0f,   // 右上
    };
    _vbo =  createVBO(GL_ARRAY_BUFFER, GL_STATIC_DRAW, sizeof(vertices), vertices);
    glEnableVertexAttribArray(glGetAttribLocation(_program, "position"));
    glVertexAttribPointer(glGetAttribLocation(_program, "position"), 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
   
    glEnableVertexAttribArray(glGetAttribLocation(_program, "texcoord"));
    glVertexAttribPointer(glGetAttribLocation(_program, "texcoord"), 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL + sizeof(GLfloat)*3);
    
    [self szh_setupTextureData];
   
}

#pragma mark -------- 设置纹理

- (void)szh_setupTextureData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"wood" ofType:@"jpg"];
    

    unsigned char *data;
    int size;
    int width;
    int height;
    
    //加载纹理
    if (read_jpeg_file(path.UTF8String, &data, &size, &width, &height) < 0) {
        printf("%s\n", "decode fail");
    }
    
    //创建纹理
    _texture = createTexture2D(GL_RGB, width, height, data);
    if (data) {
        free(data);
        data = NULL;
    }
    
    //激活纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(glGetUniformLocation(_program, "image"), 0);
    
    //绘图
    glDrawArrays(GL_TRIANGLES, 0, _vertCount);
}



@end

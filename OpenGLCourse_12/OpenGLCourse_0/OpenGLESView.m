//
//  OpenGLESView.m
//  OpenGLCourse_0
//
//  Created by 智衡宋 on 2017/9/21.
//  Copyright © 2017年 智衡宋. All rights reserved.
//

#import "OpenGLESView.h"
#import <OpenGLES/ES2/gl.h>
#include "GLUtil.h"
#include "GLMath.h"
#import "JpegUtil.h"
@interface OpenGLESView()
{
    CAEAGLLayer        *_eaglLayer;
    EAGLContext        *_context;
    GLuint              _colorRenderBuffer;
    GLuint              _depthRenderBuffer;
    GLuint              _frameBuffer;
    GLuint              _program;
    
    GLuint              _vbo;
    GLuint              _texture;
    int                 _vertCount;
}
@end

@implementation OpenGLESView


#pragma mark -------------- 初始化

+ (Class)layerClass {
    return [CAEAGLLayer class];
}


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self szh_setupLayer];
        [self szh_setupContext];
        //设置着色器程序
        [self szh_setupGLProgramVertGLSL:@"vert.glsl" andFragGLSL:@"frag.glsl"];
        [self szh_setupProjectionMatrix];
        [self szh_setupModelViewMatrix];
        [self szh_setupVertData];
        [self szh_setupTexture];
        [self szh_setupCADisplayLinker];
        
    }
    return self;
}




- (void)layoutSubviews {
    [EAGLContext setCurrentContext:_context];
    [self szh_destoryRenderAndFrameBuffer];
    [self szh_setupRenderAndFrameBuffer];
    [self szh_render];
}


#pragma mark -------------- 初始化环境

- (void)szh_setupLayer {
    
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
}

- (void)szh_setupContext {
    
    _context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    // 将当前上下文设置为我们创建的上下文
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
}


#pragma mark -------------- 设置缓存环境(包括深度缓存)

- (void)szh_destoryRenderAndFrameBuffer {
    glDeleteFramebuffers(1, &_frameBuffer);
    _frameBuffer = 0;
    glDeleteRenderbuffers(1, &_colorRenderBuffer);
    _colorRenderBuffer = 0;
}

- (void)szh_setupRenderAndFrameBuffer {
    
//    glGenRenderbuffers(1, &_colorRenderBuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
//    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
//
//
//    //设置深度缓存
//    int width, height;
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
//
//    glGenRenderbuffers(1, &_depthRenderBuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
//    glRenderbufferStorage(GL_FRAMEBUFFER, GL_DEPTH_COMPONENT, width, height);
//
//
//    //帧缓存
//    glGenFramebuffers(1, &_frameBuffer);
//    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
//
//
//    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
//
//    //检查
//    GLenum status = glCheckFramebufferStatus(GL_RENDERBUFFER_WIDTH);
//    if (status != GL_FRAMEBUFFER_COMPLETE) {
//        NSLog(@"Error: Frame buffer is not completed.");
//        exit(1);
//    }
    
    
    // Setup color render buffer
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    // Setup depth render buffer
    int width, height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    // Create a depth buffer that has the same size as the color buffer.
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    
    // Setup frame buffer
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    // Attach color render buffer and depth render buffer to frameBuffer
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                              GL_RENDERBUFFER, _depthRenderBuffer);
    
    // Set color render buffer as current render buffer
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    // Check FBO satus
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Error: Frame buffer is not completed.");
        exit(1);
    }
    
}

#pragma mark -------------- 设置着色器程序

- (void)szh_setupGLProgramVertGLSL:(NSString *)vert andFragGLSL:(NSString *)frag {
    
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:vert ofType:nil];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:frag ofType:nil];
    _program = createGLProgramFromFile(vertFile.UTF8String, fragFile.UTF8String);
    glUseProgram(_program);
}


#pragma mark -------------- 绘图

- (void)szh_render {
    
    //开启深度测试
    glEnable(GL_DEPTH_TEST);
    //glDepthFunc(GL_ALWAYS);
    //glDepthMask(GL_FALSE);
    
    glClearColor(1.0, 1.0, 1.0, 1.0);
    //清理深度缓存
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    
    [self  szh_setupModelViewMatrix];
    
    // 激活纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(glGetUniformLocation(_program, "image"), 0);
    
    // 绘制
    glDrawArrays(GL_TRIANGLES, 0, _vertCount);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark -------------- 设置数据

- (void)szh_setupVertData {
    
    _vertCount = 36;
    
    GLfloat vertices[] = {
        -0.5f, -0.5f, -0.5f,  0.0f, 0.0f,
        0.5f, -0.5f, -0.5f,  1.0f, 0.0f,
        0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
        0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
        -0.5f,  0.5f, -0.5f,  0.0f, 1.0f,
        -0.5f, -0.5f, -0.5f,  0.0f, 0.0f,
        
        -0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
        0.5f, -0.5f,  0.5f,  1.0f, 0.0f,
        0.5f,  0.5f,  0.5f,  1.0f, 1.0f,
        0.5f,  0.5f,  0.5f,  1.0f, 1.0f,
        -0.5f,  0.5f,  0.5f,  0.0f, 1.0f,
        -0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
        
        -0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
        -0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
        -0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
        -0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
        -0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
        -0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
        
        0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
        0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
        0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
        0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
        0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
        0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
        
        -0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
        0.5f, -0.5f, -0.5f,  1.0f, 1.0f,
        0.5f, -0.5f,  0.5f,  1.0f, 0.0f,
        0.5f, -0.5f,  0.5f,  1.0f, 0.0f,
        -0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
        -0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
        
        -0.5f,  0.5f, -0.5f,  0.0f, 1.0f,
        0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
        0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
        0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
        -0.5f,  0.5f,  0.5f,  0.0f, 0.0f,
        -0.5f,  0.5f, -0.5f,  0.0f, 1.0f
    };
    
    // 创建VBO
    _vbo = createVBO(GL_ARRAY_BUFFER, GL_STATIC_DRAW, sizeof(vertices), vertices);
    
    glEnableVertexAttribArray(glGetAttribLocation(_program, "position"));
    glVertexAttribPointer(glGetAttribLocation(_program, "position"), 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
    glEnableVertexAttribArray(glGetAttribLocation(_program, "texcoord"));
    glVertexAttribPointer(glGetAttribLocation(_program, "texcoord"), 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL+sizeof(GL_FLOAT)*3);
    
    
}

#pragma mark -------------- 设置纹理

- (void)szh_setupTexture {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"wood" ofType:@"jpg"];

    unsigned char *data;
    int size;
    int width;
    int height;

    // 加载纹理
    if (read_jpeg_file(path.UTF8String, &data, &size, &width, &height) < 0) {
        printf("%s\n", "decode fail");
    }

    // 创建纹理
    _texture = createTexture2D(GL_RGB, width, height, data);

    if (data) {
        free(data);
        data = NULL;
    }
    
    
    
}

#pragma mark -------------- 设置定时器刷新

- (void)szh_setupCADisplayLinker {
    
    CADisplayLink *linker = [CADisplayLink displayLinkWithTarget:self selector:@selector(szh_render)];
    linker.frameInterval = 1;
    [linker addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
}

#pragma mark -------------- 设置模型矩阵

- (void)szh_setupProjectionMatrix
{
    mat4_t projectMatrix = mat4_perspective(M_PI/3, self.frame.size.width/self.frame.size.height, 1, 10);
    GLint projectionSlot = glGetUniformLocation(_program, "projection");
    glUniformMatrix4fv(projectionSlot, 1, GL_FALSE, (GLfloat *)&projectMatrix);
}

- (void)szh_setupModelViewMatrix
{
    static CGFloat angle = 0;
    mat4_t modelView = mat4_create_translation(0, 0, -4);
    modelView = mat4_rotate(modelView, angle, 1, 1, 0);
    GLint modelViewSlot = glGetUniformLocation(_program, "modelView");
    glUniformMatrix4fv(modelViewSlot, 1, GL_FALSE, (GLfloat *)&modelView);
    
    angle += M_PI/180;
}




@end

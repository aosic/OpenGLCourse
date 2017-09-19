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
@interface OpenGLESView (){
    EAGLContext           *_context;
    CAEAGLLayer           *_eaglLayer;
    GLuint                 _colorRenderBuffer;
    GLuint                 _frameBuffer;
    
    
    //着色器程序
    GLuint                 _program;
    
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
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"vert.glsl" ofType:nil];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"frag.glsl" ofType:nil];
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
    
    //设置视口大小
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    //绘制图形
    [self szh_setupVertexData];
    
   
    
    //将指定 renderbuffer 呈现在屏幕上，在这里我们指定的是前面已经绑定为当前 renderbuffer 的那个，在 renderbuffer 可以被呈现之前，必须调用renderbufferStorage:fromDrawable: 为之分配存储空间。
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
}

#pragma mark -------- 设置顶点数据

- (void)szh_setupVertexData {
    
    static GLfloat vertices[] = {
        0.0f,  0.5f, 0.0f,
        -0.5f, -0.5f, 0.0f,
        0.5f, -0.5f, 0.0f
    };
    
    GLuint posSlot = glGetAttribLocation(_program, "position");
    glVertexAttribPointer(posSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(posSlot);
    
    
    static GLfloat colors[] = {
        0.0f, 1.0f, 1.0f,
        1.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 0.0f
    };
    GLuint colorSot = glGetAttribLocation(_program, "color");
    glVertexAttribPointer(colorSot, 3, GL_FLOAT, GL_FALSE, 0, colors);
    glEnableVertexAttribArray(colorSot);
    
    //绘制三角形
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
}




@end

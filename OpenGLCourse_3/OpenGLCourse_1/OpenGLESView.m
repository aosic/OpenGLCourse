//
//  OpenGLESView.m
//  OpenGLCourse_1
//
//  Created by 智衡宋 on 2017/9/19.
//  Copyright © 2017年 智衡宋. All rights reserved.
//

#import "OpenGLESView.h"
#import <OpenGLES/ES3/gl.h>
#import "GLUtil.h"

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
    
    
    Vertex          *_vertext;
    GLuint          _vao;
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
    _context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 3.0 context");
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
    
    CGPoint p1 = CGPointMake(-0.8, 0);
    CGPoint p2 = CGPointMake(0.8, 0.2);
    CGPoint control = CGPointMake(0, -0.9);
    CGFloat deltaT = 0.01;
    
    _vertCount = 1.0 / deltaT;
    _vertext = (Vertex *)malloc(sizeof(Vertex) * _vertCount);
    
    for (int i = 0; i < _vertCount; i++) {
        float t = i * deltaT;
        
        // 二次方计算公式
        float cx = (1-t)*(1-t)*p1.x + 2*t*(1-t)*control.x + t*t*p2.x;
        float cy = (1-t)*(1-t)*p1.y + 2*t*(1-t)*control.y + t*t*p2.y;
        _vertext[i] = (Vertex){cx, cy, 0.0, 1.0, 0.0, 0.0};
        
        printf("%f, %f\n",cx, cy);
    }
    
    

    [self szh_setupVAO];
    
    
    // VAO
    glBindVertexArray(_vao);
    glDrawArrays(GL_LINE_STRIP, 0, _vertCount);

}


- (void)szh_setupVAO
{
    glGenVertexArrays(1, &_vao);
    glBindVertexArray(_vao);
    
    // VBO
    GLuint vbo = createVBO(GL_ARRAY_BUFFER, GL_STATIC_DRAW, sizeof(Vertex) * (_vertCount + 1), _vertext);
    
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL);
    
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL+sizeof(GLfloat)*3);
    
    glBindVertexArray(0);
}


@end

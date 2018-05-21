//
//  ViewController.m
//  LKOpenGLMetalBridge
//
//  Created by lingtonke on 2018/4/12.
//  Copyright © 2018年 lingtonke. All rights reserved.
//

#import "ViewController.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <Metal/Metal.h>

@interface ViewController ()
{
    GLuint frameBuffer;
    GLuint renderBuffer;
    GLuint texture;
    GLuint program0;
    GLuint program1;
    GLfloat vertice0[6];
    GLfloat vertice1[8];
    GLfloat coord1[8];
}

@property (nonatomic) CAEAGLLayer *glLayer;
@property (nonatomic) CAMetalLayer *mtlLayer;
@property (nonatomic) EAGLContext *context;
@property (nonatomic) id<MTLDevice> device;
@property (nonatomic) id<MTLBuffer> vertexBuffer;
@property (nonatomic) id<MTLLibrary> library;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.glLayer = [[CAEAGLLayer alloc] init];
    self.glLayer.frame = CGRectMake(0, 100, self.view.bounds.size.width/2, self.view.bounds.size.width/2);
    [self.view.layer addSublayer:self.glLayer];
    self.mtlLayer = [[CAMetalLayer alloc] init];
    self.mtlLayer.frame = CGRectMake(self.view.bounds.size.width/2, 100, self.view.bounds.size.width/2, self.view.bounds.size.width/2);
    [self.view.layer addSublayer:self.glLayer];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:self.context];
    [self init0];
    [self init1];
    self.device = MTLCreateSystemDefaultDevice();
    self.mtlLayer.device = self.device;
    self.vertexBuffer = [self.device newBufferWithBytes:vertice1 length:8*sizeof(GLfloat) options:MTLResourceOptionCPUCacheModeDefault];
    //self.library = [self.device newde]
    
    [self drawOpenGL];
    [self drawMetal];
}

- (void)init0
{
    program0 = [self compileShader:@"test0" fs:@"test0"];
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.glLayer];
    GLint width,height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, NULL);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    vertice0[0] = -1;
    vertice0[1] = -1;
    
    vertice0[2] = 0;
    vertice0[3] = 1;
    
    vertice0[4] = 1;
    vertice0[5] = -1;
}

- (void)init1
{
    program1 = [self compileShader:@"test1" fs:@"test1"];
    
    

    vertice1[0] = -1;
    vertice1[1] = -1;
    
    vertice1[2] = -1;
    vertice1[3] = 1;
    
    vertice1[4] = 1;
    vertice1[5] = 1;
    
    vertice1[6] = 1;
    vertice1[7] = -1;
    
    coord1[0] = 0;
    coord1[1] = 0;
    
    coord1[2] = 0;
    coord1[3] = 1;
    
    coord1[4] = 1;
    coord1[5] = 1;
    
    coord1[6] = 1;
    coord1[7] = 0;
}

- (GLuint)compileShader:(NSString*)vsName fs:(NSString*)fsName;
{
    GLint success;
    GLchar infoLog[512];
    NSString *vsPath = [[NSBundle mainBundle] pathForResource:vsName ofType:@"vs"];
    NSString *fsPath = [[NSBundle mainBundle] pathForResource:fsName ofType:@"fs"];
    NSError *error;
    NSString *vs = [NSString stringWithContentsOfFile:vsPath encoding:NSUTF8StringEncoding error:&error];
    NSString *fs = [NSString stringWithContentsOfFile:fsPath encoding:NSUTF8StringEncoding error:&error];
    
    const GLchar *const vsStr = [vs cStringUsingEncoding:NSUTF8StringEncoding];
    const GLchar *const fsStr = [fs cStringUsingEncoding:NSUTF8StringEncoding];
    
    GLuint vertexShader;
    GLuint fragmentShader;
    
    vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vsStr, NULL);
    glCompileShader(vertexShader);
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
        NSLog(@"vertexShader compile error::%s",infoLog);
        glDeleteShader(vertexShader);
    }
    
    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fsStr, NULL);
    glCompileShader(fragmentShader);
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
        NSLog(@"fragmentShader compile error::%s",infoLog);
        glDeleteShader(fragmentShader);
    }
    
    GLuint program = glCreateProgram();
    if (!program)
    {
        NSLog(@"glprogram create failed");
    }
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    GLint linked;
    
    glLinkProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (!linked)
    {
        glGetProgramInfoLog(program, 512, NULL, infoLog);
        NSLog(@"program link error:%s",infoLog);
        glDeleteProgram(program);
    }
    if (vertexShader)
    {
        glDeleteShader(vertexShader);
        vertexShader = 0;
    }
    if (fragmentShader)
    {
        glDeleteShader(fragmentShader);
        fragmentShader = 0;
    }
    return program;
}

- (void)drawOpenGL
{
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    //glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
    glViewport(0, 0, self.glLayer.frame.size.width, self.glLayer.frame.size.height);
    glClearColor(1, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(program0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, false, 0, vertice0);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    //////////////////////////////////////////////
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
    glClearColor(0, 1, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(program1);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, false, 0, vertice1);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, false, 0, coord1);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    GLuint location = glGetUniformLocation(program1, "tex");
    glUniform1i(location, 0);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)drawMetal
{
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end

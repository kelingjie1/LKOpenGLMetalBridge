//
//  LKOpenGLMetalBridge.m
//  microvision
//
//  Created by lingtonke on 2018/4/11.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "LKOpenGLMetalBridge.h"

@interface LKOpenGLMetalBridge()

@property (nonatomic) EAGLContext *context;
@property (nonatomic) CVPixelBufferRef pixelBuffer;
@property (nonatomic) CVOpenGLESTextureRef cvglTexture;
@property (nonatomic) CVMetalTextureRef cvmtlTexture;
@property (nonatomic) CVOpenGLESTextureCacheRef glTextureCache;
@property (nonatomic) CVMetalTextureCacheRef mtlTextureCache;
@property (nonatomic) id<MTLDevice> device;
@property (nonatomic) GLuint progrom;
@property (nonatomic) GLfloat *vertice;

@end

@implementation LKOpenGLMetalBridge

-(instancetype)initWithShareGroup:(EAGLSharegroup *)group
{
    if (self = [super init])
    {
        self.device = MTLCreateSystemDefaultDevice();
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3 sharegroup:group];
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_glTextureCache);
        err = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, self.device, NULL, &_mtlTextureCache);
        self.progrom = [self compileShader:nil];
        self.vertice = malloc(sizeof(GLfloat)*8);
        self.vertice[0] = -1;
        self.vertice[1] = -1;
        
        self.vertice[2] = -1;
        self.vertice[3] = 1;
        
        self.vertice[4] = 1;
        self.vertice[5] = 1;
        
        self.vertice[6] = 1;
        self.vertice[7] = -1;
        glVertexAttribPointer(0, 2, GL_FLOAT, false, false, self.vertice);
    }
    return self;
}

- (void)dealloc
{
    [self releaseBuffer];
    if (self.progrom)
    {
        glDeleteProgram(self.progrom);
        self.progrom = 0;
    }
    
}

- (void)releaseBuffer
{
    if (self.cvglTexture)
    {
        CFRelease(self.cvglTexture);
        self.cvglTexture = nil;
    }
    if (self.cvmtlTexture)
    {
        CFRelease(self.cvmtlTexture);
        self.cvmtlTexture = nil;
    }
    
}

- (GLuint)compileShader:(NSError**)err;
{
    GLint success;
    GLchar infoLog[512];
    NSString *vsPath = [[NSBundle mainBundle] pathForResource:@"LKOpenGLMetalBridge" ofType:@"vs"];
    NSString *fsPath = [[NSBundle mainBundle] pathForResource:@"LKOpenGLMetalBridge" ofType:@"fs"];
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

- (void)setSize:(CGSize)size
{
    _size = size;
    CFMutableDictionaryRef prop = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef attr = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attr, kCVPixelBufferIOSurfacePropertiesKey, prop);
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32BGRA, attr, &_pixelBuffer);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
                                                        self.glTextureCache,
                                                        self.pixelBuffer,
                                                        NULL, // texture attributes
                                                        GL_TEXTURE_2D,
                                                        GL_RGBA, // opengl format
                                                        (int)size.width,
                                                        (int)size.height,
                                                        GL_BGRA, // native iOS format
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        &_cvglTexture);
    glBindTexture(CVOpenGLESTextureGetTarget(self.pixelBuffer), CVOpenGLESTextureGetName(self.pixelBuffer));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    err = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                    self.mtlTextureCache,
                                                    self.pixelBuffer,
                                                    NULL,
                                                    MTLPixelFormatBGRA8Unorm,
                                                    (int)size.width,
                                                    (int)size.height,
                                                    0,
                                                    &_cvmtlTexture);
    CFRelease(prop);
    CFRelease(attr);
}

-(id<MTLTexture>)MTLTexture:(GLuint)glTexture
{
    return nil;
}

@end

//
//  LKOpenGLMetalBridge.h
//  microvision
//
//  Created by lingtonke on 2018/4/11.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <Metal/Metal.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreVideo/CVMetalTextureCache.h>
#import <CoreVideo/CVMetalTexture.h>

@interface LKOpenGLMetalBridge : NSObject

@property (nonatomic) CGSize size;

-(instancetype)initWithShareGroup:(EAGLSharegroup*)group;
-(id<MTLTexture>)MTLTexture:(GLuint)glTexture;

@end

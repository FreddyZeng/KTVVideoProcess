//
//  KTVVPTransformFilter.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/9.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPTransformFilter.h"
#import "KTVVPStandardProgram.h"
#import "KTVVPGLPlaneModel.h"
#import "KTVVPFrameDrawable.h"

@interface KTVVPTransformFilter ()

@property (nonatomic, strong) KTVVPStandardProgram * glProgram;
@property (nonatomic, strong) KTVVPGLPlaneModel * glModel;

@end

@implementation KTVVPTransformFilter


#pragma mark - KTVVPFrameInput

- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    if (!self.enable)
    {
        [super inputFrame:frame fromSource:source];
        return;
    }
    if (frame.rotationMode == KTVVPRotationMode0
        && frame.flipMode == KTVVPFlipModeNone)
    {
        [super inputFrame:frame fromSource:source];
        return;
    }
    
    [self.glContext setCurrentIfNeeded];
    if (!_glModel)
    {
        _glModel = [[KTVVPGLPlaneModel alloc] initWithGLContext:self.glContext];
    }
    if (!_glProgram)
    {
        _glProgram = [[KTVVPStandardProgram alloc] initWithGLContext:self.glContext];
    }
    [frame lock];
    KTVVPSize size = frame.finalSize;
    NSString * key = [KTVVPFrameDrawable keyWithAppendString:[NSString stringWithFormat:@"%d-%d", size.width, size.height]];
    KTVVPFrameDrawable * result = [self.framePool frameWithKey:key factory:^__kindof KTVVPFrame *{
        KTVVPFrame * result = [[KTVVPFrameDrawable alloc] init];
        return result;
    }];
    [result fillWithoutTransformWithFrame:frame];
    _glModel.rotationMode = frame.rotationMode;
    _glModel.flipMode = frame.flipMode;
    [_glModel reloadDataIfNeeded];
    [result uploadIfNeeded:self.frameUploader];
    [result bindFramebuffer];
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [_glProgram use];
    [frame uploadIfNeeded:self.frameUploader];
    [_glProgram bindTexture:frame.texture];
    [_glModel bindPosition_location:_glProgram.position_location
         textureCoordinate_location:_glProgram.textureCoordinate_location];
    [_glModel draw];
    [_glModel bindEmpty];
    [frame unlock];
    [self outputFrame:result];
    [result unlock];
}

@end
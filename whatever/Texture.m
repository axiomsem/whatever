//
//  Texture.m
//  whatever
//
//  Created by user on 10/16/22.
//

#import "Texture.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

@implementation Texture
{
    struct swfloatframe _dstFrame;
    
    id<MTLBuffer> _staging;
    id<MTLDevice> _device;
    id<MTLTexture> _texture;
}

- (nonnull id<MTLTexture>) texture
{
    return _texture;
}

- (void)_makeTexture:(nonnull id<MTLCommandBuffer>)commandBuffer fence:(nonnull id<MTLFence>)fence
{
    MTLTextureDescriptor* descriptor = [[MTLTextureDescriptor alloc] init];
    
    descriptor.depth = 1;
    descriptor.width = _dstFrame.width;
    descriptor.height = _dstFrame.height;
    descriptor.pixelFormat = MTLPixelFormatRGBA32Float;
    descriptor.usage = MTLTextureUsageShaderRead;
    descriptor.sampleCount = 1;
    descriptor.storageMode = MTLStorageModePrivate;
    descriptor.mipmapLevelCount = 1;
    descriptor.textureType = MTLTextureType2D;
    
    
    _texture = [_device newTextureWithDescriptor:descriptor];
    
    _staging = [_device newBufferWithBytes:_dstFrame.buffer
                                   length:_dstFrame.byteLength
                                  options:MTLResourceStorageModeManaged];
    
    id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    
    const size_t bytesPerRow = _dstFrame.bytesPerPixel * _dstFrame.width;
    
    MTLSize size = MTLSizeMake(_dstFrame.width, _dstFrame.height, 1);
    MTLOrigin origin = MTLOriginMake(0, 0, 0);
    
    [blitEncoder synchronizeResource:_staging];
    
    [blitEncoder copyFromBuffer:_staging
                   sourceOffset:0
              sourceBytesPerRow:bytesPerRow
            sourceBytesPerImage:0
                     sourceSize:size
                      toTexture:_texture
               destinationSlice:0
               destinationLevel:0
              destinationOrigin:origin];
    
    [blitEncoder updateFence:fence];
            
    [blitEncoder endEncoding];
}

- (nonnull instancetype) initWithFrame:(nonnull struct swrasterframe *)frame
                                device:(nonnull id<MTLDevice>) device
                         commandBuffer:(nonnull id<MTLCommandBuffer>) commandBuffer
                                 fence:(nonnull id<MTLFence>) fence
{
    self = [super init];
    
    if ((swrastertofloat(&_dstFrame, frame) == SW_E_OK) && self) {
        _device = device;
        [self _makeTexture:commandBuffer fence:fence];
        zfree((void**)&_dstFrame);
    }
    else {
        NSLog(@"Error in Texture initWithFrame: could not allocate swfloatframe");
    }
    
    return self;
}

- (nonnull instancetype) initArrayFromPaths:(nonnull NSArray<NSString*>*)paths
                               device:(nonnull id<MTLDevice>) device
                        commandBuffer:(nonnull id<MTLCommandBuffer>) commandBuffer
                               fence:(nonnull id<MTLFence>) fence
{
    self = [super init];
    
    NSLog(@"[Texture initArrayFromPaths] Begin for %lu images..", paths.count);
    
    size_t fail = 0;
    
    if (self) {        
        //
        for (NSString* path in paths) {
            const char* cpath = [path UTF8String];
            int width, height;
            int comp;
            
            float* buffer = stbi_loadf(cpath, &width, &height, &comp, 4);
            
            if (buffer != nil) {
                _dstFrame.width = (size_t)width;
                _dstFrame.height = (size_t)height;
                _dstFrame.bytesPerPixel = (size_t)comp;
                _dstFrame.buffer = buffer;
                _dstFrame.byteLength = _dstFrame.width * _dstFrame.height * _dstFrame.bytesPerPixel;
                
                //[self _makeTexture:commandBuffer fence:fence];
                
                stbi_image_free(buffer);
            }
            else {
                NSLog(@"\t[Texture initArrayFromPaths] Warning: could not load image file \"%s\"", cpath);
                fail++;
            }
            
        }
    }
    
    NSLog(@"[Texture initArrayFromPaths] Out of %lu images, %lu failed to load.", paths.count, fail);
    
    return self;
}

@end

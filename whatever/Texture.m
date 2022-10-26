//
//  Texture.m
//  whatever
//
//  Created by user on 10/16/22.
//

#import "Texture.h"

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

- (nonnull instancetype) initWithFrame:(nonnull struct swrasterframe *)frame
                                device:(nonnull id<MTLDevice>) device
                         commandBuffer:(nonnull id<MTLCommandBuffer>) commandBuffer
                                 fence:(nonnull id<MTLFence>) fence
{
    self = [super init];
    
    if ((swrastertofloat(&_dstFrame, frame) == SW_E_OK) && self) {
        
        _device = device;
        
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
        
        
        
        zfree((void**)&_dstFrame);
    }
    else {
        NSLog(@"Error in Texture initWithFrame: could not allocate swfloatframe");
    }
    
    return self;
}

@end

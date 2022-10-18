//
//  Texture.h
//  whatever
//
//  Created by user on 10/16/22.
//

//#import <MetalKit/MetalKit.h>
#import <Metal/MTLDevice.h>
#import <Metal/MTLCommandQueue.h>
#import <Metal/MTLTexture.h>

#include "swcommon.h"

#ifndef Texture_h
#define Texture_h

@interface Texture : NSObject

- (nonnull id<MTLTexture>) texture;

- (nonnull instancetype) initWithFrame:(nonnull struct swrasterframe *)frame
                                device:(nonnull id<MTLDevice>) device
                         commandBuffer:(nonnull id<MTLCommandBuffer>) commandBuffer
                                fence:(nonnull id<MTLFence>) fence;

@end

#endif /* Texture_h */

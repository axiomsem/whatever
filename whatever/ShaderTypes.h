//
//  ShaderTypes.h
//  whatever
//
//  Created by user on 10/5/22.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
typedef metal::int32_t EnumBackingType;
#else
#import <Foundation/Foundation.h>
typedef NSInteger EnumBackingType;
#endif

#ifndef RASTER_WITH_TEXCOORDS
#define RASTER_WITH_TEXCOORDS 1
#endif

#ifndef RASTER_WITH_RESOURCE_BLIT
#define RASTER_WITH_RESOURCE_BLIT 0
#endif

#include <simd/simd.h>

typedef NS_ENUM(EnumBackingType, BufferIndex)
{
    BufferIndexMeshPositions = 0,
    BufferIndexMeshGenerics  = 1,
    BufferIndexUniforms      = 2
};

typedef NS_ENUM(EnumBackingType, VertexAttribute)
{
    VertexAttributePosition  = 0,
    VertexAttributeTexcoord  = 1,
    VertexAttributeSceneColor = 1,
    VertexAttributeSceneNormal = 2,
    VertexAttributeSceneTexcoord = 3,
    VertexAttributeSceneMaterial = 4
};

typedef NS_ENUM(EnumBackingType, TextureIndex)
{
    TextureIndexColor    = 0,
};

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} Uniforms;

#endif /* ShaderTypes_h */


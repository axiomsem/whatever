//
//  Shaders.metal
//  whatever
//
//  Created by user on 10/5/22.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[attribute(VertexAttributePosition)]];
#if RASTER_WITH_TEXCOORDS
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
#endif
} RasterVertex;

typedef struct
{
    float4 position [[attribute(VertexAttributePosition)]];
    float4 color [[attribute(VertexAttributeSceneColor)]];
    float3 normal [[attribute(VertexAttributeSceneNormal)]];
    float2 texCoord [[attribute(VertexAttributeSceneTexcoord)]];
    uint3 material [[attribute(VertexAttributeSceneMaterial)]];
} SceneVertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

typedef struct
{
    float4 position [[position]];
#if RASTER_WITH_TEXCOORDS
    float2 texCoord;
#endif
} RasterColorInOut;

typedef struct
{
    float4 position [[position]];
    float4 color;
    uint3 material;
} SceneColorInOut;

vertex ColorInOut vertexShader(Vertex in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    ColorInOut out;

    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;

    return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
                               texture2d<half> colorMap     [[ texture(TextureIndexColor) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    half4 colorSample   = colorMap.sample(colorSampler, in.texCoord.xy);

    return float4(colorSample);
}

vertex RasterColorInOut rasterVertexShader(RasterVertex in [[stage_in]])
{
    RasterColorInOut out;

    float4 position = in.position;
    out.position = position;
    
#if RASTER_WITH_TEXCOORDS
    out.texCoord = in.texCoord;
#endif

    return out;
}

#if RASTER_WITH_TEXCOORDS
fragment float4 rasterFragmentShader(RasterColorInOut in [[stage_in]], texture2d<float> colorMap [[ texture(TextureIndexColor) ]])
{

    constexpr sampler colorSampler(mip_filter::none,
                                   mag_filter::linear,
                                   min_filter::linear);

    float4 colorSample   = colorMap.sample(colorSampler, in.texCoord.xy);

    return colorSample;

}
#else
fragment float4 rasterFragmentShader(RasterColorInOut in [[stage_in]])
{
    return float4(1.0f, 0.0f, 0.0f, 1.0f);
}
#endif

vertex SceneColorInOut sceneVertexShader(SceneVertex in [[stage_in]],
                                         constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    SceneColorInOut out;

    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * in.position;
    out.color = in.color;
    out.material = in.material;

    return out;
}

fragment float4 sceneFragmentShader(SceneColorInOut in [[stage_in]])
{
    return in.color;
}

//
//  Renderer.m
//  whatever
//
//  Created by user on 10/5/22.
//

#import <simd/simd.h>
#import <ModelIO/ModelIO.h>
#include <string.h>
#include "sw.h"
#include "common.h"

#import "SceneView.h"
#import "Renderer.h"
#import "Texture.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "ShaderTypes.h"
#import "fast_obj.h"

static const NSUInteger kMaxBuffersInFlight = 3;

static const size_t kAlignedUniformsSize = (sizeof(Uniforms) & ~0xFF) + 0x100;

static const char* kObjFilename = "Sponza/sponza.obj";

#pragma mark Print Utilities

static void print_float2(const char* name, simd_float2 xy)
{
    // %f is for 64 bit.
    // don't want to create confusion in
    // generated assembly for passing the argument.
    const float x = xy.x;
    const float y = xy.y;
    NSLog(@"%s: { %f, %f }", name, x, y);
}

static void print_float3(const char* name, simd_float3 xyz)
{
    // %f is for 64 bit.
    // don't want to create confusion in
    // generated assembly for passing the argument.
    const float x = xyz.x;
    const float y = xyz.y;
    const float z = xyz.z;
    NSLog(@"%s: { %f, %f, %f }", name, x, y, z);
}

static void print_float4(const char* name, simd_float4 xyzw)
{
    // %f is for 64 bit.
    // don't want to create confusion in
    // generated assembly for passing the argument.
    const float x = xyzw.x;
    const float y = xyzw.y;
    const float z = xyzw.z;
    const float w = xyzw.w;
    NSLog(@"%s: { %f, %f, %f, %f }", name, x, y, z, w);
}

#pragma mark Matrix Math Utilities

matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz)
{
    return (matrix_float4x4) {{
        { 1,   0,  0,  0 },
        { 0,   1,  0,  0 },
        { 0,   0,  1,  0 },
        { tx, ty, tz,  1 }
    }};
}

static matrix_float4x4 matrix4x4_rotation(float radians, vector_float3 axis)
{
    axis = vector_normalize(axis);
    float ct = cosf(radians);
    float st = sinf(radians);
    float ci = 1 - ct;
    float x = axis.x, y = axis.y, z = axis.z;

    return (matrix_float4x4) {{
        { ct + x * x * ci,     y * x * ci + z * st, z * x * ci - y * st, 0},
        { x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0},
        { x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0},
        {                   0,                   0,                   0, 1}
    }};
}

matrix_float4x4 matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ)
{
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);

    return (matrix_float4x4) {{
        { xs,   0,          0,  0 },
        {  0,  ys,          0,  0 },
        {  0,   0,         zs, -1 },
        {  0,   0, nearZ * zs,  0 }
    }};
}



typedef struct _FPSCamera
{
    simd_float4x4 orientation;
    simd_float4x4 inverseOrientation;
    simd_float4x4 translation;
    
    simd_float4 origin;
    simd_float4 orientAngles;
    
    float lastMouseX;
    float lastMouseY;
}
FPSCamera;

void FPSCamera_Init(FPSCamera* camera)
{
    camera->origin = simd_make_float4(0.0f, 0.0f, 0.0f, 1.0f);
    camera->orientAngles = simd_make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    // identity
    camera->orientation = matrix_identity_float4x4;
    
    camera->inverseOrientation = matrix_identity_float4x4;
    
    camera->lastMouseX = 0.0f;
    camera->lastMouseY = 0.0f;
}

void FPSCamera_Update(FPSCamera* camera, float mouseX, float mouseY, SceneKeyFlags Flags)
{
    const float FactorRot = 1.0f;
    const float FactorT = 5.0f;
    
    float rotdY = mouseX - camera->lastMouseX;
    float rotdX = mouseY - camera->lastMouseY;
    
    // rotation
    {
        camera->orientAngles.x += rotdX * FactorRot;
        camera->orientAngles.y += rotdY * FactorRot;
        
        camera->lastMouseX = mouseX;
        camera->lastMouseY = mouseY;
        
        simd_float4x4 orientY = matrix4x4_rotation(camera->orientAngles.y * deg2rad, simd_make_float3(0.0f, 1.0f, 0.0f));
        simd_float4x4 orientX = matrix4x4_rotation(camera->orientAngles.x * deg2rad, simd_make_float3(1.0f, 0.0f, 0.0f));
        
        camera->orientation = matrix_multiply(orientY, orientX);
        camera->inverseOrientation = matrix_invert(camera->orientation);
    }
    
    // translation
    {
        if ((Flags & SceneKeyForward) == SceneKeyForward) {
            simd_float4 ax = simd_make_float4(0.0f, 0.0f, -1.0f, 1.0f);
            simd_float4 direction = matrix_multiply(camera->inverseOrientation, ax);
            //camera->origin.
            
            simd_float4 scaled = direction * FactorT;
            simd_float4 result = camera->origin + scaled;
            camera->origin = result;
        }
        
        if ((Flags & SceneKeyBackward) == SceneKeyBackward) {
            simd_float4 ax = simd_make_float4(0.0f, 0.0f, 1.0f, 1.0f);
            simd_float4 direction = matrix_multiply(camera->inverseOrientation, ax);
            
            simd_float4 scaled = direction * FactorT;
            simd_float4 result = camera->origin + scaled;
            camera->origin = result;
        }
        
        if ((Flags & SceneKeyLeft) == SceneKeyLeft) {
            simd_float4 ax = simd_make_float4(-1.0f, 0.0f, 0.0f, 1.0f);
            simd_float4 direction = matrix_multiply(camera->inverseOrientation, ax);
            //camera->origin.
            
            simd_float4 scaled = direction * FactorT;
            simd_float4 result = camera->origin + scaled;
            camera->origin = result;
        }
        
        if ((Flags & SceneKeyRight) == SceneKeyRight) {
            simd_float4 ax = simd_make_float4(1.0f, 0.0f, 0.0f, 1.0f);
            simd_float4 direction = matrix_multiply(camera->inverseOrientation, ax);
            
            simd_float4 scaled = direction * FactorT;
            simd_float4 result = camera->origin + scaled;
            camera->origin = result;
        }
        
        camera->origin.w = 1.0f;
        
        camera->translation = matrix4x4_translation(-camera->origin.x, -camera->origin.y, -camera->origin.z);
    }
}

typedef struct _RasterVertex
{
    vec4 position;
#if RASTER_WITH_TEXCOORDS
    vec2 texcoord;
#endif
} RasterVertex;

typedef struct _SceneVertex
{
    simd_float4 position;
    simd_float4 color;
    simd_float3 normal;
    simd_float2 texture;
} SceneVertex;

typedef struct _AABB
{
    simd_float3 origin;
    simd_float3 extents;
} AABB;

static AABB MakeAABB(simd_float3 min, simd_float3 max)
{
    simd_float3 maxToMin = (max - min);
    simd_float3 ofs = maxToMin * 0.5f;
    AABB ret = {
        .origin = min + ofs,
        .extents = ofs
    };
    return ret;
}

typedef struct _MeshData
{
    AABB bounds;
    // We'll duplicate vertex data for now.
    // It's not good for performance, but that's ok (for the moment).
    SceneVertex* sceneVertices;
    size_t numSceneVertices;
} MeshData;

static void load_obj(MeshData* outMeshData)
{
    NSFileManager *filemgr;
    NSString *currentPath;

    filemgr = [[NSFileManager alloc] init];

    currentPath = [filemgr currentDirectoryPath];
    
    NSLog(@"Reading file %s...", kObjFilename);
    
    fastObjMesh* mesh = fast_obj_read(kObjFilename);
    
    NSLog(@"Finishing reading file...");
    
    const float scale = 1.0f;
    
    if (mesh != NULL) {
        NSLog(@"Allocating memory...");
        outMeshData->sceneVertices = zalloc(sizeof(SceneVertex) * mesh->index_count);

        if (outMeshData->sceneVertices != NULL) {
            NSLog(@"Processing vertex data...");
            outMeshData->numSceneVertices = (size_t)mesh->index_count;
            
            const size_t ENTROPY = 7;
            const float I_ENTROPY = 1.0f / (float)ENTROPY;
            
            // Compute bounds
            {
                simd_float3 min = simd_make_float3(FLT_MAX, FLT_MAX, FLT_MIN);
                simd_float3 max = simd_make_float3(FLT_MIN, FLT_MIN, FLT_MAX);
                
                for (size_t i = 0; i < mesh->position_count; i += 3) {
                    simd_float3 p = simd_make_float3(mesh->positions[i + 0],
                                                     mesh->positions[i + 1],
                                                     mesh->positions[i + 2]);
                    if (min.x > p.x) min.x = p.x;
                    if (min.y > p.y) min.y = p.y;
                    if (min.z < p.z) min.z = p.z;
                    
                    if (max.x < p.x) max.x = p.x;
                    if (max.y < p.y) max.y = p.y;
                    if (max.z > p.z) max.z = p.z;
                }
                
                outMeshData->bounds = MakeAABB(min, max);
            }
            
            // Generate vertex buffer
            {
                for (size_t i = 0; i < mesh->index_count; ++i) {
                    fastObjIndex* index = &mesh->indices[i];
                    size_t pBase = index->p * 3;
                    size_t nBase = index->n * 3;
                    size_t tBase = index->t * 2;
                    
                    outMeshData->sceneVertices[i].position.x = mesh->positions[pBase + 0] * scale;
                    outMeshData->sceneVertices[i].position.y = mesh->positions[pBase + 1] * scale;
                    outMeshData->sceneVertices[i].position.z = mesh->positions[pBase + 2] * scale;
                    outMeshData->sceneVertices[i].position.w = 1.0f;
                    
                    outMeshData->sceneVertices[i].normal.x = mesh->normals[nBase + 0];
                    outMeshData->sceneVertices[i].normal.y = mesh->normals[nBase + 1];
                    outMeshData->sceneVertices[i].normal.z = mesh->normals[nBase + 2];
                    
                    outMeshData->sceneVertices[i].texture.x = mesh->texcoords[tBase + 0];
                    outMeshData->sceneVertices[i].texture.y = mesh->texcoords[tBase + 1];
                    
                    float k = (float)(i & ENTROPY);
                    k *= I_ENTROPY;
                    
                    outMeshData->sceneVertices[i].color.x = k;
                    outMeshData->sceneVertices[i].color.y = k;
                    outMeshData->sceneVertices[i].color.z = k;
                    outMeshData->sceneVertices[i].color.w = 1.0f;
                }
            }
            
            NSLog(@"Finished processing vertex data...");
        }
        else {
            OOM();
        }
    } else {
        NSLog(@"obj file could not be found");
        exit(1);
    }
}


typedef enum _DrawingMode
{
    // Spinning cube + texture
    DrawingModeDefault = 0,
    // Draw to offscreen framebuffer; copy to passthrough shader
    DrawingModeRaster,
    // Draw a dead simple scene with some effects and an fps camera
    DrawingModeScene
}
DrawingMode;

static const DrawingMode kDrawingMode = DrawingModeScene;

@implementation Renderer
{
    FPSCamera fpsCamera;
    
    dispatch_semaphore_t _inFlightSemaphore;
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;

    id <MTLBuffer> _dynamicUniformBuffer;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLDepthStencilState> _depthState;
    id <MTLTexture> _colorMap;
    MTLVertexDescriptor *_mtlVertexDescriptor;
    
    // for DrawingModeRaster or similar
    id <MTLBuffer> _vertexBuffer;
    Texture *_frameBufferTexture;
    struct swrasterframe frame;
    
    // from obj
    MeshData meshData;
    
    // for any DrawingMode
    uint32_t _uniformBufferOffset;

    uint8_t _uniformBufferIndex;

    void* _uniformBufferAddress;

    matrix_float4x4 _projectionMatrix;

    float _rotation;

    MTKMesh *_mesh;
}

-(void)_sceneStats
{
    print_float3("bounds origin", meshData.bounds.origin);
    print_float3("bounds max", meshData.bounds.origin + meshData.bounds.extents);
    print_float3("bounds min", meshData.bounds.origin - meshData.bounds.extents);
    print_float4("camera origin", fpsCamera.origin);
}

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view
{
    self = [super init];
    if(self)
    {
        _device = view.device;
        _inFlightSemaphore = dispatch_semaphore_create(kMaxBuffersInFlight);
        [self _loadMetalWithView:view];
        [self _loadAssetsWithView:view];
    }

    return self;
}

- (void)_exitUnknownDrawingMode
{
    NSLog(@"Error: unknown drawing mode");
    exit(1);
}

- (void)_loadMetalWithView:(nonnull MTKView *)view;
{
    memset(&meshData, 0, sizeof(meshData));
    load_obj(&meshData);
    FPSCamera_Init(&fpsCamera);
    fpsCamera.origin = simd_make_float4(meshData.bounds.origin, 1.0f);
    
    /// Load Metal state objects and initialize renderer dependent view properties

    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    view.sampleCount = 1;
    view.clearColor = MTLClearColorMake(0.2, 0.2, 0.5, 1.0);

    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];

    switch (kDrawingMode)
    {
        case DrawingModeDefault:
        {
            _mtlVertexDescriptor.attributes[VertexAttributePosition].format = MTLVertexFormatFloat3;
            _mtlVertexDescriptor.attributes[VertexAttributePosition].offset = 0;
            _mtlVertexDescriptor.attributes[VertexAttributePosition].bufferIndex = BufferIndexMeshPositions;

            _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].format = MTLVertexFormatFloat2;
            _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].offset = 0;
            _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].bufferIndex = BufferIndexMeshGenerics;
            
            _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stride = 12;
            _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepRate = 1;
            _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

            _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stride = 8;
            _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepRate = 1;
            _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;
        }
            break;
        case DrawingModeRaster:
        {
    
            _mtlVertexDescriptor.attributes[VertexAttributePosition].format = MTLVertexFormatFloat4;
            _mtlVertexDescriptor.attributes[VertexAttributePosition].offset = offsetof(RasterVertex, position);
            _mtlVertexDescriptor.attributes[VertexAttributePosition].bufferIndex = 0;

#if RASTER_WITH_TEXCOORDS
            _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].format = MTLVertexFormatFloat2;
            _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].offset = offsetof(RasterVertex, texcoord);
            _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].bufferIndex = 0;
#endif
            
            _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stride = sizeof(RasterVertex);
            _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepRate = 1;
            _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

        }
            break;
        case DrawingModeScene:
        {
            _mtlVertexDescriptor.attributes[VertexAttributePosition].format = MTLVertexFormatFloat4;
            _mtlVertexDescriptor.attributes[VertexAttributePosition].offset = offsetof(SceneVertex, position);
            _mtlVertexDescriptor.attributes[VertexAttributePosition].bufferIndex = 0;

            _mtlVertexDescriptor.attributes[VertexAttributeSceneColor].format = MTLVertexFormatFloat4;
            _mtlVertexDescriptor.attributes[VertexAttributeSceneColor].offset = offsetof(SceneVertex, color);
            _mtlVertexDescriptor.attributes[VertexAttributeSceneColor].bufferIndex = 0;
            
            _mtlVertexDescriptor.attributes[VertexAttributeSceneTexcoord].format = MTLVertexFormatFloat2;
            _mtlVertexDescriptor.attributes[VertexAttributeSceneTexcoord].offset = offsetof(SceneVertex, texture);
            _mtlVertexDescriptor.attributes[VertexAttributeSceneTexcoord].bufferIndex = 0;
            
            _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stride = sizeof(SceneVertex);
            _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepRate = 1;
            _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;
        }
            break;
        default:
            [self _exitUnknownDrawingMode];
            break;
    }
    

    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    id <MTLFunction> vertexFunction = nil;

    id <MTLFunction> fragmentFunction = nil;
    
    switch (kDrawingMode)
    {
        case DrawingModeDefault:
        {
            vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
            fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        }
            break;
            
        case DrawingModeRaster:
        {
            vertexFunction = [defaultLibrary newFunctionWithName:@"rasterVertexShader"];
            fragmentFunction = [defaultLibrary newFunctionWithName:@"rasterFragmentShader"];
        }
            break;
        case DrawingModeScene:
        {
            vertexFunction = [defaultLibrary newFunctionWithName:@"sceneVertexShader"];
            fragmentFunction = [defaultLibrary newFunctionWithName:@"sceneFragmentShader"];
        }
            break;
        default:
            [self _exitUnknownDrawingMode];
            break;
    }

    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"MyPipeline";
    pipelineStateDescriptor.rasterSampleCount = view.sampleCount;
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
    pipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat;

    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState)
    {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
    
    switch (kDrawingMode)
    {
        case DrawingModeDefault:
        {
            MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
            depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
            depthStateDesc.depthWriteEnabled = YES;
            _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
        }
            break;
        case DrawingModeRaster:
        {
            MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
            depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
            depthStateDesc.depthWriteEnabled = YES;
            _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
        }
            break;
        case DrawingModeScene:
        {
            MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
            depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
            depthStateDesc.depthWriteEnabled = YES;
            _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
        }
            break;
    }

    NSUInteger uniformBufferSize = kAlignedUniformsSize * kMaxBuffersInFlight;

    _dynamicUniformBuffer = [_device newBufferWithLength:uniformBufferSize
                                                 options:MTLResourceStorageModeShared];

    _dynamicUniformBuffer.label = @"UniformBuffer";

    _commandQueue = [_device newCommandQueue];
}

- (void)_clearRasterColorBufferWithRed:(float)red green:(float)green blue:(float)blue
{
    const float nfac = 255.0f;
    
    uint32_t bAlpha = 255;
    uint32_t bRed = (uint32_t)(red * nfac);
    uint32_t bGreen = (uint32_t)(green * nfac);
    uint32_t bBlue = (uint32_t)(blue * nfac);
    
    uint32_t color = bRed | (bGreen << 8) | (bBlue << 16) | (bAlpha << 24);
    
    if (!swrasterframe_isset(&frame)) {
        NSLog(@"Error _clearRasterColorBufferWithRed: frame is not set");
        return;
    }
    
    const size_t numPixels = frame.byteLength >> 2;
    for (size_t i = 0; i < numPixels; ++i) {
        frame.buffer[i] = color;
    }
}

- (void)_loadSceneAssetsWithview:(nonnull MTKView*)view
{
    // Sending these as two triangles
    // using NDC pass through coordinates
    
#if !SCENE_TEST_TRIANGLE
    
    const size_t vertexSize = sizeof(meshData.sceneVertices[0]);
    const size_t sceneVerticesByteSize = meshData.numSceneVertices * vertexSize;
    
    _vertexBuffer = [_device newBufferWithBytes:meshData.sceneVertices
                                         length:sceneVerticesByteSize
                                        options:MTLResourceOptionCPUCacheModeDefault | MTLResourceStorageModeManaged];
#else
    const float SIZE = 1.0f;
    
    // pos lower left
    const float PLLX = -SIZE;
    const float PLLY = -SIZE;
    
    // pos lower right
    const float PLRX = SIZE;
    const float PLRY = -SIZE;
    
    // pos upper left
    const float PULX = -SIZE;
    const float PULY = SIZE;
    
    // pos upper right
    const float PURX = SIZE;
    const float PURY = SIZE;
    
    const float Z = 0.0f;
    const float W = 1.0f;

    // Winding order is CCW
    static const SceneVertex triangleVertices[] =
    {
        // Lower left
        { { PLLX, PLLY, Z, W }, COLORF_R, { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f } },
        // Lower right
        { { PLRX, PLRY, Z, W }, COLORF_G, { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f } },
        // Upper right
        { { PURX, PURY, Z, W }, COLORF_B, { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f } }
    };

    
    const size_t vertexSize = sizeof(SceneVertex);
    const size_t bufferSize = vertexSize * 3;
    
    _vertexBuffer = [_device newBufferWithBytes:triangleVertices
                                         length:bufferSize
                                        options:MTLResourceOptionCPUCacheModeDefault | MTLResourceStorageModeManaged];
#endif
}

- (void)_loadRasterAssetsWithView:(nonnull MTKView*)view
{
    // Sending these as two triangles
    // using NDC pass through coordinates
    
    const float SIZE = 1.0f;
    
    // pos lower left
    const float PLLX = -SIZE;
    const float PLLY = -SIZE;
    
    // pos lower right
    const float PLRX = SIZE;
    const float PLRY = -SIZE;
    
    // pos upper left
    const float PULX = -SIZE;
    const float PULY = SIZE;
    
    // pos upper right
    const float PURX = SIZE;
    const float PURY = SIZE;
    
#if RASTER_WITH_TEXCOORDS
    // tex lower left
    const float TLLX = 0.0f;
    const float TLLY = 1.0f;
    
    // tex lower right
    const float TLRX = 1.0f;
    const float TLRY = 1.0f;
    
    // tex upper left
    const float TULX = 0.0f;
    const float TULY = 0.0f;
    
    // tex upper right
    const float TURX = 1.0f;
    const float TURY = 0.0f;
#endif
    
    const float Z = 0.0f;
    const float W = 1.0f;

#if RASTER_WITH_TEXCOORDS
    
#define V_LOWER_LEFT_P { { PLLX, PLLY, Z, W }, { TLLX, TLLY } }
#define V_LOWER_RIGHT_P { { PLRX, PLRY, Z, W }, { TLRX, TLRY } }
#define V_UPPER_LEFT_P { { PULX, PULY, Z, W }, { TULX, TULY } }
#define V_UPPER_RIGHT_P { { PURX, PURY, Z, W }, { TURX, TURY } }
    
#else
    
#define V_LOWER_LEFT_P { { PLLX, PLLY, Z, W } }
#define V_LOWER_RIGHT_P { { PLRX, PLRY, Z, W } }
#define V_UPPER_LEFT_P { { PULX, PULY, Z, W } }
#define V_UPPER_RIGHT_P { { PURX, PURY, Z, W } }
    
#endif
    // Winding order is CCW
    static const RasterVertex triangleVertices[] =
    {
        V_LOWER_LEFT_P,
        V_LOWER_RIGHT_P,
        V_UPPER_RIGHT_P,
        
        V_LOWER_LEFT_P,
        V_UPPER_RIGHT_P,
        V_UPPER_LEFT_P
    };
    
    const size_t vertexSize = sizeof(RasterVertex);
    const size_t bufferSize = vertexSize * 6;
    
    _vertexBuffer = [_device newBufferWithBytes:triangleVertices
                                         length:bufferSize
                                        options:MTLResourceOptionCPUCacheModeDefault | MTLResourceStorageModeManaged];
}

- (void)_loadDefaultAssetsWithView:(nonnull MTKView*)view
{
    NSError *error;
        
    MTKMeshBufferAllocator *metalAllocator = [[MTKMeshBufferAllocator alloc]
                                              initWithDevice: _device];
    
    MDLMesh *mdlMesh = [MDLMesh newBoxWithDimensions:(vector_float3){4, 4, 4}
                                            segments:(vector_uint3){2, 2, 2}
                                        geometryType:MDLGeometryTypeTriangles
                                       inwardNormals:NO
                                           allocator:metalAllocator];
    
    MDLVertexDescriptor *mdlVertexDescriptor =
    MTKModelIOVertexDescriptorFromMetal(_mtlVertexDescriptor);
    
    mdlVertexDescriptor.attributes[VertexAttributePosition].name  = MDLVertexAttributePosition;
    mdlVertexDescriptor.attributes[VertexAttributeTexcoord].name  = MDLVertexAttributeTextureCoordinate;
    
    mdlMesh.vertexDescriptor = mdlVertexDescriptor;
    
    _mesh = [[MTKMesh alloc] initWithMesh:mdlMesh
                                   device:_device
                                    error:&error];
    
    if(!_mesh || error)
    {
        NSLog(@"Error creating MetalKit mesh %@", error.localizedDescription);
    }
    
    MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
    
    NSDictionary *textureLoaderOptions =
    @{
        MTKTextureLoaderOptionTextureUsage       : @(MTLTextureUsageShaderRead),
        MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
    };
    
    _colorMap = [textureLoader newTextureWithName:@"ColorMap"
                                      scaleFactor:1.0
                                           bundle:nil
                                          options:textureLoaderOptions
                                            error:&error];
    
    if(!_colorMap || error)
    {
        NSLog(@"Error creating texture %@", error.localizedDescription);
    }
}

- (void)_loadAssetsWithView:(nonnull MTKView*)view
{
    /// Load assets into metal objects
    switch (kDrawingMode)
    {
        case DrawingModeDefault:
            [self _loadDefaultAssetsWithView:view];
            break;
        case DrawingModeRaster:
            [self _loadRasterAssetsWithView:view];
            break;
        case DrawingModeScene:
            [self _loadSceneAssetsWithview:view];
            break;
        default:
            [self _exitUnknownDrawingMode];
            break;
    }
}

- (void)_updateDynamicBufferState
{
    /// Update the state of our uniform buffers before rendering

    _uniformBufferIndex = (_uniformBufferIndex + 1) % kMaxBuffersInFlight;

    _uniformBufferOffset = kAlignedUniformsSize * _uniformBufferIndex;

    _uniformBufferAddress = ((uint8_t*)_dynamicUniformBuffer.contents) + _uniformBufferOffset;
}

- (void)_updateGameState
{
    /// Update any game state before encoding renderint commands to our drawable

    Uniforms * uniforms = (Uniforms*)_uniformBufferAddress;

    uniforms->projectionMatrix = _projectionMatrix;

#if !SCENE_TEST_TRIANGLE
    uniforms->modelViewMatrix = matrix_multiply(fpsCamera.orientation, fpsCamera.translation);
#else
    vector_float3 rotationAxis = {1, 1, 0};
    matrix_float4x4 modelMatrix = matrix4x4_rotation(_rotation, rotationAxis);
    matrix_float4x4 translate = matrix_multiply(fpsCamera.translation, matrix4x4_translation(0.0, 0.0, -8.0));
    matrix_float4x4 viewMatrix = matrix_multiply(fpsCamera.orientation, translate);
    uniforms->modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);
#endif
    

    _rotation += .01;
}

- (void)drawInMTKViewDefault:(nonnull MTKView *)view
{
    /// Per frame updates here
    
    
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_NOW);

    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_sema);
     }];

    [self _updateDynamicBufferState];

    [self _updateGameState];

    /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
    ///   holding onto the drawable and blocking the display pipeline any longer than necessary
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil) {

        /// Final pass rendering code here
        
        id <MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        [renderEncoder pushDebugGroup:@"DrawBox"];

        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setDepthStencilState:_depthState];

            
        [renderEncoder setVertexBuffer:_dynamicUniformBuffer
                                offset:_uniformBufferOffset
                               atIndex:BufferIndexUniforms];
        
        [renderEncoder setFragmentBuffer:_dynamicUniformBuffer
                                  offset:_uniformBufferOffset
                                 atIndex:BufferIndexUniforms];

        for (NSUInteger bufferIndex = 0; bufferIndex < _mesh.vertexBuffers.count; bufferIndex++)
        {
            MTKMeshBuffer *vertexBuffer = _mesh.vertexBuffers[bufferIndex];
            if((NSNull*)vertexBuffer != [NSNull null])
            {
                [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                        offset:vertexBuffer.offset
                                       atIndex:bufferIndex];
            }
        }

        [renderEncoder setFragmentTexture:_colorMap
                                  atIndex:TextureIndexColor];
        
        for(MTKSubmesh *submesh in _mesh.submeshes)
        {
            [renderEncoder drawIndexedPrimitives:submesh.primitiveType
                                      indexCount:submesh.indexCount
                                       indexType:submesh.indexType
                                     indexBuffer:submesh.indexBuffer.buffer
                               indexBufferOffset:submesh.indexBuffer.offset];
        }

        [renderEncoder popDebugGroup];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (void)drawInMTKViewScene:(nonnull MTKView *)view
{
    NSPoint mouseLoc = view.window.mouseLocationOutsideOfEventStream;
    
    FPSCamera_Update(&fpsCamera, mouseLoc.x, mouseLoc.y, ((SceneView*)view).keyFlags);
        
    [self _sceneStats];
    
    /// Per frame updates here
    if (dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }
    
    [self _updateDynamicBufferState];

    [self _updateGameState];
    
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
    id<MTLFence> fence = [_device newFence];

    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_sema);
     }];
    
 //   _frameBufferTexture = [[Texture alloc] initWithFrame:&frame
 //                                                device:_device
 //                                          commandBuffer:commandBuffer
 //                                                  fence:fence];
 //   _colorMap = [_frameBufferTexture texture];

    /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
    ///   holding onto the drawable and blocking the display pipeline any longer than necessary
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil) {
        /// Final pass rendering code here

        id <MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        //[renderEncoder waitForFence:fence beforeStages:MTLRenderStageVertex | MTLRenderStageFragment | MTLRenderStageTile];
        
        renderEncoder.label = @"MyRenderEncoder";

        [renderEncoder pushDebugGroup:@"DrawBox"];

        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeNone];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setDepthStencilState:_depthState];

        [renderEncoder setVertexBuffer:_vertexBuffer
                                offset:0
                               atIndex:0];
        
        [renderEncoder setVertexBuffer:_dynamicUniformBuffer
                                offset:_uniformBufferOffset
                               atIndex:BufferIndexUniforms];
        
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:meshData.numSceneVertices];

        [renderEncoder popDebugGroup];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (void)drawInMTKViewRaster:(nonnull MTKView *)view
{
    /// Per frame updates here
    if (dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }

    // Will free if frame is already allocated
    NSSize sz = view.frame.size;
    if (swrasterframe_new(&frame, sz.width, sz.height) == SW_E_FAIL)
    {
        NSLog(@"Renderer drawInMTKViewRaster: could not allocate new frame");
        return;
    }
    
#if RASTER_WITH_TEXCOORDS
    [self _clearRasterColorBufferWithRed:1.0f green:0.0f blue:1.0f];
#endif
    
    swfill(&frame);
    
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
    id<MTLFence> fence = [_device newFence];


    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_sema);
     }];
    
    _frameBufferTexture = [[Texture alloc] initWithFrame:&frame
                                                  device:_device
                                           commandBuffer:commandBuffer
                                                   fence:fence];
    _colorMap = [_frameBufferTexture texture];

    /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
    ///   holding onto the drawable and blocking the display pipeline any longer than necessary
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil) {        
        /// Final pass rendering code here

        id <MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        [renderEncoder waitForFence:fence beforeStages:MTLRenderStageVertex | MTLRenderStageFragment | MTLRenderStageTile];
        
        renderEncoder.label = @"MyRenderEncoder";

        [renderEncoder pushDebugGroup:@"DrawBox"];

        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeNone];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setDepthStencilState:_depthState];

        [renderEncoder setVertexBuffer:_vertexBuffer
                                offset:0
                               atIndex:0];
        
#if RASTER_WITH_TEXCOORDS
        [renderEncoder setFragmentTexture:_colorMap
                                  atIndex:TextureIndexColor];
#endif
        
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

        [renderEncoder popDebugGroup];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    switch (kDrawingMode)
    {
        case DrawingModeDefault:
        {
            [self drawInMTKViewDefault:view];
        }
            break;
        case DrawingModeRaster:
        {
            [self drawInMTKViewRaster:view];
        }
            break;
        case DrawingModeScene:
        {
            [self drawInMTKViewScene:view];
        }
            break;
        default:
            break;
            
    }
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    /// Respond to drawable size or orientation changes here

    float aspect = size.width / (float)size.height;
    _projectionMatrix = matrix_perspective_right_hand(65.0f * (M_PI / 180.0f), aspect, 0.1f, 3000.0f);
}


@end

//
//  swcommon.h
//  whatever
//
//  Created by user on 10/13/22.
//

#ifndef swcommon_h
#define swcommon_h

#import <Foundation/Foundation.h>
#include <simd/simd.h>
#include "linmath.h"
#include "common.h"

typedef float swreal_t;

#define SW_DECL_VERTEX2(name, t1, mem1, t2, mem2)\
struct sw##name {\
    t1 mem1;\
    t2 mem2;\
};\
struct swtri_##name {\
    union swtri_##name##_positions {\
        struct {\
            struct sw##name a;\
            struct sw##name b;\
            struct sw##name c;\
        } s;\
        struct {\
            struct sw##name abc[3];\
        } a;\
    } positions;\
    union swtri_##name##_edges {\
        struct {\
            struct sw##name ab;\
            struct sw##name bc;\
            struct sw##name ca;\
        } s;\
        struct {\
            struct sw##name abc[3];\
        } a;\
    } edges;\
    union swtri_##name##_normals {\
        struct {\
            struct sw##name ab;\
            struct sw##name bc;\
            struct sw##name ca;\
        } s;\
        struct {\
            struct sw##name abc[3];\
        } a;\
    } normals;\
};\
extern const size_t stride_##name;\
extern const size_t dim_##name##_##mem1;\
extern const size_t dim_##name##_##mem2;\
extern const size_t offset_##name##_##mem1;\
extern const size_t offset_##name##_##mem2;

#define SW_IMPL_VERTEX2(name, t1, t1base, mem1, t2, t2base, mem2)\
const size_t stride_##name = sizeof(struct sw##name);\
const size_t dim_##name##_##mem1 = sizeof(t1) / sizeof(t1base);\
const size_t dim_##name##_##mem2 = sizeof(t2) / sizeof(t2base);\
const size_t offset_##name##_##mem1 = offsetof(struct sw##name, mem1);\
const size_t offset_##name##_##mem2 = offsetof(struct sw##name, mem2);

typedef uint8_t swcolor_t[4];

// vertex 3 float color 4 float
SW_DECL_VERTEX2(basic_vertex, vec2, position, swcolor_t, color)

SW_DECL_VERTEX2(raster_vertex, i32vec2, position, swcolor_t, color)

SW_DECL_VERTEX2(vertex, vec4, position, swcolor_t, color);

#define SW_E_OK W_E_OK
#define SW_E_FAIL W_E_FAIL

typedef struct swbasic_vertex swvertex_t;
typedef struct swtri_basic_vertex swtriangle_t;

typedef size_t switer_t;

struct swbuffer
{
    void* mem;
    size_t element_length;
    size_t element_stride;
    size_t byte_length;
};

struct swdepthbuffer
{
    struct swbuffer buffer;
    float depth_near;
    float depth_far;
    float resolution;
};

struct swrasterframe
{
    uint32_t* buffer; // rgba8
    size_t width;
    size_t height;
    size_t byteLength;
};

struct swfloatframe
{
    float* buffer;
    size_t width;
    size_t height;
    size_t byteLength;
    size_t bytesPerPixel;
};

wresult_t swrastertofloat(struct swfloatframe* dst, struct swrasterframe* src);

wresult_t swfloatframe_init(struct swfloatframe* frame, size_t width, size_t height, size_t bytesPerPixel);
void swfloatframe_free(struct swfloatframe* frame);

void swtri_basic_vertex_from_verts(struct swtri_basic_vertex * v, struct swbasic_vertex* a,
                                    struct swbasic_vertex * b, struct swbasic_vertex * c);

wresult_t swbuffer_new(struct swbuffer* buffer, size_t length, size_t stride);

void swbuffer_free(struct swbuffer* buffer);

// resolution is divided over the near - far range
wresult_t swdepthbuffer_new(struct swdepthbuffer* dbuffer, float near, float far, float resolution);

wresult_t swrasterframe_new(struct swrasterframe* frame, size_t width, size_t height);

void swcleardepth(struct swdepthbuffer* dbuffer);

void swrasterframe_free(struct swrasterframe* frame);

bool swrasterframe_isset(struct swrasterframe* frame);

int32_t i32vec2_int_len(i32vec2 v);

int32_t i32vec2_int_dist(i32vec2 a, i32vec2 b);

#endif /* swcommon_h */

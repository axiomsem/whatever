//
//  swcommon.c
//  whatever
//
//  Created by user on 10/13/22.
//

#include "swcommon.h"

#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

SW_IMPL_VERTEX2(attrib, vec4, float, position, vec4, float, color)
SW_IMPL_VERTEX2(raster, vec2, float, position, vec4, float, color)

#ifndef PRINT_TRI_VERTS
#define PRINT_TRI_VERTS 0
#endif

static void newl()
{
    NSLog(@"\n");
}

static void vec2_print(const char* name, const vec2 v)
{
    NSLog(@"%s = { %f, %f }", name, v[0], v[1]);
}

wresult_t swfloatframe_init(struct swfloatframe* frame, size_t width, size_t height, size_t bytesPerPixel)
{
    swfloatframe_free(frame);
    const size_t byteLength = width * height * bytesPerPixel;
    frame->buffer = zalloc(byteLength);
    wresult_t result = SW_E_FAIL;
    if (frame->buffer != NULL) {
        result = SW_E_OK;
        frame->width = width;
        frame->height = height;
        frame->byteLength = byteLength;
        frame->bytesPerPixel = bytesPerPixel;
    }
    return result;
}

void swcleardepth(struct swdepthbuffer* dbuffer)
{
    float * buffer = dbuffer->buffer.mem;
    for (size_t i = 0; i < dbuffer->buffer.element_length; ++i) {
        buffer[i] = dbuffer->depth_far;
    }
}

wresult_t swdepthbuffer_new(struct swdepthbuffer* dbuffer, float near, float far, float resolution)
{
    size_t length = (size_t)floor((far - near) / resolution);
    
    wresult_t result = swbuffer_new(&dbuffer->buffer, length, sizeof(dbuffer->depth_far));
    if (result == SW_E_OK) {
        dbuffer->resolution = resolution;
        dbuffer->depth_far = far;
        dbuffer->depth_near = near;
        swcleardepth(dbuffer);
    }
    
    return result;
}


void swfloatframe_free(struct swfloatframe* frame)
{
    zfree((void**)&frame->buffer);
    memset(frame, 0, sizeof(*frame));
}

wresult_t swrastertofloat(struct swfloatframe* dst, struct swrasterframe* src)
{    
    const size_t txComp = 4;

    wresult_t result =
        swfloatframe_init(dst,
                          src->width,
                          src->height,
                          sizeof(dst->buffer[0]) * txComp);
    
    if (result == SW_E_OK)
    {
        const float inv = 1.0f / 255.0f;
        
        const size_t len = src->width * src->height;
        for (size_t i = 0; i < len; i++)
        {
            const size_t pixelBase = i << 2;
            for (size_t k = 0; k < txComp; ++k)
            {
                uint32_t m = (src->buffer[i] >> (k << 3)) & 0xFF;
                float r = (float)m;
                r *= inv;
                dst->buffer[pixelBase + k] = r;
            }
        }
    }
    
    return result;
}

void swraster_tri_from_vertices(struct swraster_tri * v,
                                   struct swraster_vertex* a,
                                   struct swraster_vertex * b,
                                   struct swraster_vertex * c)
{
    memset(v, 0, sizeof(*v));
    
    //
    // set vertices
    //
    
    memcpy(&v->positions.s.a, a, sizeof(*a));
    memcpy(&v->positions.s.b, b, sizeof(*b));
    memcpy(&v->positions.s.c, c, sizeof(*c));
    
    //
    // calc triangle edges
    //
    
    vec2_sub(v->edges.a.abc[0].position, b->position, a->position);
    vec2_sub(v->edges.a.abc[1].position, c->position, b->position);
    vec2_sub(v->edges.a.abc[2].position, a->position, c->position);
    
#if PRINT_TRI_VERTS
    vec2_print("edge ab", v->edges.s.ab.position); newl();
    vec2_print("edge bc", v->edges.s.bc.position); newl();
    vec2_print("edge ca", v->edges.s.ca.position); newl();
#endif
    //
    // calc triangle edge normals
    //
    // 1. determine whether or not the normal is in the right direction
    //      1. it should be pointing into the triangle
    //      2. one method of doing this:
    //          1. compute the normal from the edge.
    //          2. take the dot product of the normal against the other edges.
    //          3. the edge before the current should have a negative result.
    //          4. the edge after the current should have a positive result.
    //          5. if these aren't true, flip the direction of the normal.
    //
    //
    
    for (size_t i = 0; i < 3; ++i) {
        vec2_calc_normal(v->normals.a.abc[i].position, v->edges.a.abc[i].position);
        size_t edge_next = (i + 1) % 3;
        size_t edge_prev = (i == 0) ? 2 : (i - 1);
        int32_t dot_next = vec2_mul_inner(v->normals.a.abc[i].position, v->edges.a.abc[edge_next].position);
        int32_t dot_prev = vec2_mul_inner(v->normals.a.abc[i].position, v->edges.a.abc[edge_prev].position);
        if (!(dot_next > 0) && !(dot_prev < 0))
        {
            vec2 tmp;
            vec2_dup(tmp, v->normals.a.abc[i].position);
            vec2_neg(v->normals.a.abc[i].position, tmp);
        }
    }
    
#if PRINT_TRI_VERTS
    vec2_print("normal ab", v->normals.s.ab.position); newl();
    vec2_print("normal bc", v->normals.s.bc.position); newl();
    vec2_print("normal ca", v->normals.s.ca.position); newl();
#endif
    
    for (size_t i = 0; i < 3; ++i) {
        vec2 tmp;
        vec2_norm(tmp, v->normals.a.abc[i].position);
        memcpy(v->normals.a.abc[i].position, tmp, sizeof(vec2));
    }
    
#if PRINT_TRI_VERTS
    vec2_print("normal normalized ab", v->normals.s.ab.position); newl();
    vec2_print("normal normalized bc", v->normals.s.bc.position); newl();
    vec2_print("normal normalized ca", v->normals.s.ca.position); newl();
#endif
}

wresult_t swbuffer_new(struct swbuffer* out, size_t length, size_t stride)
{
    swbuffer_free(out);
    
    wresult_t ret = SW_E_FAIL;
    
    if (out != NULL) {
        out->mem = zalloc(length * stride);
        if (out->mem != NULL) {
            out->byte_length = length * stride;
            out->element_length = length;
            out->element_stride = stride;
            ret = SW_E_OK;
        }
    }
    
    return ret;
}

void swbuffer_free(struct swbuffer* buffer)
{
    if (buffer != NULL) {
        if (buffer->mem != NULL) {
            zfree(buffer->mem);
        }
        memset(buffer, 0, sizeof(*buffer));
    }
}

void swrasterframe_free(struct swrasterframe* frame)
{
    void* p = frame->buffer;
    zfree(&p);
    
    memset(frame, 0, sizeof(*frame));
}

wresult_t swrasterframe_new(struct swrasterframe* frame, size_t width, size_t height)
{
    swrasterframe_free(frame);
    
    frame->width = width;
    frame->height = height;
    frame->byteLength = frame->width * frame->height * sizeof(frame->buffer[0]);
    
    frame->buffer = zalloc(frame->byteLength);
    
    if (frame->buffer == NULL) {
        NSLog(@"swrasterframe: allocation failure; width:%zu, height:%zu", width, height);
        return SW_E_FAIL;
    }
    
    return SW_E_OK;
}

bool swrasterframe_isset(struct swrasterframe* frame)
{
    return
        (frame->buffer != NULL) &&
        ((frame->width * frame->height * sizeof(*frame->buffer)) == frame->byteLength) &&
        (frame->byteLength > 0);
}

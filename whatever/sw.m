//
//  sw.c
//  whatever
//
//  Created by user on 10/13/22.
//

#include "sw.h"
#include "swfill_screentest.h"

static void i32vec2_to_vec2(vec2 r, const i32vec2 src)
{
    r[0] = (float)src[0];
    r[1] = (float)src[1];
}

static void tri_raster_to_basic(struct swtri_basic_vertex* r, const struct swtri_raster_vertex* src)
{
    for (size_t i = 0; i < 3; ++i) {
        i32vec2_to_vec2(r->positions.a.abc[i].position, src->positions.a.abc[i].position);
        i32vec2_to_vec2(r->edges.a.abc[i].position, src->edges.a.abc[i].position);
        i32vec2_to_vec2(r->normals.a.abc[i].position, src->normals.a.abc[i].position);
        
        memcpy(r->positions.a.abc[i].color, src->positions.a.abc[i].color, sizeof(src->positions.a.abc[i].color));
    }
}

void swfill_ndc_vertex_to_screen(struct swbasic_vertex* result, const struct swvertex* vndc, const struct swrasterframe* frame)
{
    struct swvertex screen_vertex;
    memcpy(&screen_vertex, vndc, sizeof(screen_vertex));
    
    // conversion for any x from [-1, 1] to some [0,y] is:
    // (x + 1) * (y/2)
    for (size_t i = 0; i < 3ull; ++i)
    {
        screen_vertex.position[i] += 1.0f;
    }
    
    screen_vertex.position[3] = 1.0f;
    
    mat4x4 ndc2scrn = {0};
    
    mat4x4_identity(ndc2scrn);
    
    ndc2scrn[0][0] = frame->width * 0.5f;
    ndc2scrn[0][1] = 0.0f;
    ndc2scrn[0][2] = 0.0f;
    ndc2scrn[0][3] = 0.0f;
    
    ndc2scrn[1][0] = 0.0f;
    ndc2scrn[1][1] = frame->height * 0.5f;
    ndc2scrn[1][2] = 0.0f;
    ndc2scrn[1][3] = 0.0f;
    
    ndc2scrn[2][0] = 0.0f;
    ndc2scrn[2][1] = 0.0f;
    ndc2scrn[2][2] = 1.0f; // keep the depth value
    ndc2scrn[2][3] = 0.0f;
    
    ndc2scrn[3][0] = 0.0f;
    ndc2scrn[3][1] = 0.0f;
    ndc2scrn[3][2] = 0.0f;
    ndc2scrn[3][3] = 0.0f;
    
    vec4 result4 = {0};
    mat4x4_mul_vec4(result4, ndc2scrn, screen_vertex.position);
    
    memcpy(result->color, screen_vertex.color, sizeof(screen_vertex.color));
    for (size_t i = 0; i < dim_basic_vertex_position; ++i) {
        result->position[i] = result4[i];
    }
}

void swfill(struct swrasterframe* frame)
{
    swfill_screentest(frame);
}

void swrasterize(struct swrasterframe* frame, struct swtri_basic_vertex* triangle)
{
    for (ssize_t y = 0; y < (ssize_t)frame->height; ++y) {
        for (ssize_t x = 0; x < (ssize_t)frame->width; ++x) {
            vec2 coords = { (float)x, (float)y };

            bool is_in_tri = true;
            
            size_t i = 0;
            while (is_in_tri && (i < 3)) {
                vec2 n;
                vec2_dup(n, triangle->normals.a.abc[i].position);
                
                vec2 e2c;
                vec2_sub(e2c, coords, triangle->positions.a.abc[i].position);
                
                if (vec2_mul_inner(n, e2c) < 0.0f) {
                    is_in_tri = false;
                }
                i++;
            }
            
            if (is_in_tri) {
                uint32_t r = (uint32_t)triangle->positions.a.abc[0].color[0];
                uint32_t g = (uint32_t)triangle->positions.a.abc[0].color[1];
                uint32_t b = (uint32_t)triangle->positions.a.abc[0].color[2];
                uint32_t a = 255;
                
                const uint32_t pixel = r | (g << 8) | (b << 16) | (a << 24);
                
                frame->buffer[y * frame->width + x] = pixel;
            }
            
        }
    }
}

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

void swfill_ndc_vertex_to_screen(struct swraster_vertex* result, const struct swattrib_vertex* vndc, const struct swrasterframe* frame)
{
    struct swattrib_vertex screen_vertex;
    // copying the color from vndc to this
    // isn't terribly necessary, but it is better
    // for memory locality, since we have to perform
    // calculations on it below.
    memcpy(&screen_vertex, vndc, sizeof(screen_vertex));
    
    // conversion for any x from [-1, 1] to some [0,y] is:
    // (x + 1) * (y/2);
    // the addition here allows for this to work.
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
    
    memcpy(result->color, screen_vertex.position, sizeof(screen_vertex.position));
    
    // take screen space position and assign to result
    for (size_t i = 0; i < dim_raster_position; ++i) {
        result->position[i] = result4[i];
    }
}

void swfill(struct swrasterframe* frame)
{
    swfill_screentest(frame);
}

void swrasterize(struct swrasterframe* frame, struct swraster_tri* triangle)
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
            
            const bool do_blending = true;
            
            if (is_in_tri) {
                // for do_blending, we want to perform a blending
                // based on the pixel's distance in the triangle
                // from each vertex. We then can perform more computations
                // from there.
                if (do_blending) {
                    struct tri_interp_screen_in blend_params = {0};
                    
                    memcpy(blend_params.abc_col[0], triangle->positions.a.abc[0].color, sizeof(vec4));
                    memcpy(blend_params.abc_col[1], triangle->positions.a.abc[1].color, sizeof(vec4));
                    memcpy(blend_params.abc_col[2], triangle->positions.a.abc[2].color, sizeof(vec4));
                    
                    memcpy(blend_params.abc_pos[0], triangle->positions.a.abc[0].position, sizeof(vec2));
                    memcpy(blend_params.abc_pos[1], triangle->positions.a.abc[1].position, sizeof(vec2));
                    memcpy(blend_params.abc_pos[2], triangle->positions.a.abc[2].position, sizeof(vec2));
                    
                    memcpy(blend_params.p, coords, sizeof(coords));
                    
                    vec4 output = {0};
                    tri_interp_screen(&blend_params, output);
                    
                    uint32_t r = (uint32_t)(output[0] * 255.0f);
                    uint32_t g = (uint32_t)(output[1] * 255.0f);
                    uint32_t b = (uint32_t)(output[2] * 255.0f);
                    uint32_t a = 255;
                    
                    const uint32_t pixel = r | (g << 8) | (b << 16) | (a << 24);
                    frame->buffer[y * frame->width + x] = pixel;
                }
                else {
                    
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
}

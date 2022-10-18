//
//  sw.c
//  whatever
//
//  Created by user on 10/13/22.
//

#include "sw.h"

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

float dist_from_point_to_edge(vec2 point, vec2 edge_point, vec2 normal)
{
    // grab the start of the edge, which is still a point,
    // so we can work with it.
    vec2 p2e;
    vec2_sub(p2e, edge_point, point);
    
    vec2 offset;
    vec2_project_v_on_u(offset, p2e, normal);
    
    return vec2_len(offset);
}

void swfill(struct swrasterframe* frame)
{
    vec2 abc[3];
    abc[0][0] = 300.0f;
    abc[0][1] = 200.0f;
    
    abc[1][0] = 400.0f;
    abc[1][1] = 200.0f;
    
    abc[2][0] = 350.0f;
    abc[2][1] = 275.0f;
    
    swcolor_t color = {
      255, 0, 0, 255
    };
    
    struct swbasic_vertex vabc[3];
    
    for (size_t i = 0; i < 3; i++) {
        memcpy(vabc[i].position, abc[i], sizeof(abc[0]));
        memcpy(vabc[i].color, color, sizeof(color));
    }
    
    struct swtri_basic_vertex triangle;
    swtri_basic_vertex_from_verts(&triangle, &vabc[0], &vabc[1], &vabc[2]);
    
    swrasterize(frame, &triangle);
}

void swrasterize(struct swrasterframe* frame, struct swtri_basic_vertex* triangle)
{
    for (size_t y = 0; y < frame->height; ++y) {
        for (size_t x = 0; x < frame->width; ++x) {
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
            
            if (is_in_tri)
            {
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

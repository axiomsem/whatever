//
//  sw.c
//  whatever
//
//  Created by user on 10/13/22.
//

#include "sw.h"
#include "swfill_screentest.h"

struct vec2_elem
{
    vec2 v;
};

struct vec4_elem
{
    vec4 v;
};

#define SWVERTEX_COUNT_INIT 3

struct swpipeline
{
    struct vec4_elem* attribute_positions;
    struct vec4_elem* attribute_colors;
    
    struct vec2_elem* raster_positions;
    struct vec2_elem* raster_edges;
    struct vec2_elem* raster_normals;
    
    struct vec4_elem* raster_colors;
    
    struct matstack camera_to_clip;
    
    struct matstack model_to_camera;
    
    struct swfloatframe floatframe;
    
    struct swrasterframe rasterframe;
    
    enum swpipeline_enum error;
    
    uint8_t negate_axes[3];
    
    uint8_t clip_to_ndc_enabled;
    uint8_t perspective_correct_sampling_enabled;
    uint8_t per_vertex_color_blending_enabled;
};

static struct swpipeline PIPELINE =
{
    .camera_to_clip = {0},
    .model_to_camera = {0},
    .floatframe = {0},
    .rasterframe = {0},
    .error = SWPIPELINE_ERROR_NONE,
    .negate_axes =
    {
        false, true, false
    },
    .clip_to_ndc_enabled = true,
    .per_vertex_color_blending_enabled = true,
    .perspective_correct_sampling_enabled = true
};

void pipeline_setup(size_t width, size_t height)
{
    pipeline_teardown();
    
    if (!CHKRES(matstack_new(&PIPELINE.model_to_camera))) {
        goto error;
    }
    
    if (!CHKRES(matstack_new(&PIPELINE.camera_to_clip))) {
        goto error;
    }
    
    if (!CHKRES(swrasterframe_new(&PIPELINE.rasterframe, width, height))) {
        goto error;
    }
    
    pipeline_matrix_perspective_wh((float)width, (float)height);
    
    return;
    
error:
    PIPELINE.error = SWPIPELINE_ERROR_ALLOC_FAILURE;
}

void pipeline_teardown(void)
{
    swrasterframe_free(&PIPELINE.rasterframe);
    swfloatframe_free(&PIPELINE.floatframe);
    matstack_del(&PIPELINE.camera_to_clip);
    matstack_del(&PIPELINE.model_to_camera);
    
    PIPELINE.error = SWPIPELINE_ERROR_NONE;
}

bool pipeline_valid(void)
{
    return PIPELINE.error == SWPIPELINE_ERROR_NONE;
}

void pipeline_matrix_rotate(float angle, vec3 axes)
{
    matstack_rotate(&PIPELINE.model_to_camera, angle, axes);
}

void pipeline_matrix_translate(vec3 t)
{
    matstack_translate(&PIPELINE.model_to_camera, t);
}

void pipeline_matrix_scale(vec3 s)
{
    matstack_scale(&PIPELINE.model_to_camera, s);
}

void pipeline_matrix_perspective_wh(float width, float height)
{
    matstack_perspective(&PIPELINE.camera_to_clip, 45.0f, width, height, 0.01f, 100.0f);
}

void pipeline_draw_triangles(void)
{
    
}

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
    
    memcpy(result->color, screen_vertex.color, sizeof(vec4));
    
    // take screen space position and assign to result
    for (size_t i = 0; i < dim_raster_position; ++i) {
        result->position[i] = result4[i];
    }
}

void swfill(struct swrasterframe* frame)
{
#if SCREENTEST
    swfill_screentest(frame);
#endif
}

void swrasterize(struct swrasterframe* frame, struct swraster_tri* triangle)
{
    for (ssize_t y = 0; y < (ssize_t)frame->height; ++y) {
        for (ssize_t x = 0; x < (ssize_t)frame->width; ++x) {
            vec2 coords =
            {
                (float)x,
                (float)y
            };

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
                // for per-vertex color blending, we want to perform a blending
                // based on the pixel's distance in the triangle
                // from each vertex. We then can perform more computations
                // from there.
                if (true) {
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

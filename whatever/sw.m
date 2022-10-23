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


static void swfill_ndc_vertex_to_screen(struct swbasic_vertex* result, const struct swvertex* vndc, const struct swrasterframe* frame)
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

static void swfill_screentest_screenspace(struct swrasterframe* frame)
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

static void swfill_screentest_screenspace_flipy(struct swrasterframe* frame)
{
    vec2 abc[3];
    abc[0][0] = 300.0f;
    abc[0][1] = (float)frame->height - 200.0f;
    
    abc[1][0] = 400.0f;
    abc[1][1] = (float)frame->height - 200.0f;
    
    abc[2][0] = 350.0f;
    abc[2][1] = (float)frame->height - 275.0f;
    
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

struct swfill_ndc_tri_in
{
    mat4x4 transform;
    vec4 abc[3];
    uint8_t negate_ax[3];
};

static void swfill_ndc_tri(struct swfill_ndc_tri_in* input, struct swrasterframe* frame)
{
    struct swvertex abc[3] =
    {
        // struct swvertex
        {
            .position = { input->abc[0][0], input->abc[0][1], input->abc[0][2], 1.0f },
            .color = { 255, 0, 0, 255 }
        },
        // struct swvertex
        {
            .position = { input->abc[1][0], input->abc[1][1], input->abc[1][2], 1.0f },
            .color = { 255, 0, 0, 255 }
        },
        // struct swvertex
        {
            .position = { input->abc[2][0], input->abc[2][1], input->abc[2][2], 1.0f },
            .color = { 255, 0, 0, 255 }
        }
    };
    
    struct swbasic_vertex vabc[3];
    
    for (size_t i = 0; i < 3; i++) {
        // need to make a copy, since here we're transforming abc[i].position to some other
        // vec (t) and then negating the axis - we do this last since that's the NDC' space
        // value (between NDC and screen space).
        //
        // we copy it back to abc[i].position, since swfill_ndc_vertex_to_screen is expecting a vertex,
        // not a position.
        vec4 t = {0};
        {
            mat4x4_mul_vec4(t, input->transform, abc[i].position);
            for (size_t j = 0; j < 3; ++j) {
                t[j] = input->negate_ax[j] ? (-t[j]) : (t[j]);
            }
            memcpy(abc[i].position, t, sizeof(t));
        }
        swfill_ndc_vertex_to_screen(&vabc[i], &abc[i], frame);
    }
    
    struct swtri_basic_vertex triangle;
    swtri_basic_vertex_from_verts(&triangle, &vabc[0], &vabc[1], &vabc[2]);
    
    swrasterize(frame, &triangle);
}

static void swfill_screentest_ndc_negatey_rotate(struct swrasterframe* frame, vec3 rotate_ax)
{
    const float SIZE = 0.25f;
    const float DEPTH = 0.0f;
    
    const float AX = -SIZE;
    const float AY = -SIZE;
    const float AZ = DEPTH;
    
    const float BX = SIZE;
    const float BY = -SIZE;
    const float BZ = DEPTH;
    
    const float CX = 0.0f;
    const float CY = SIZE;
    const float CZ = DEPTH;
    
    struct swfill_ndc_tri_in args =
    {
        // transform
        { 0 },
        // abc
        { { AX, AY, AZ },
            { BX, BY, BZ },
            { CX, CY, CZ } },
        // negate_ax
        { false, true, false }
    };
    
    static float ANGLE_RAD = 0.0f;
    static const float ANGLE_STEP = 0.05f;
    
    {
        mat4x4 tmp;
        mat4x4_identity(tmp);
        mat4x4_rotate(args.transform, tmp, rotate_ax[0], rotate_ax[1], rotate_ax[2], ANGLE_RAD);
        ANGLE_RAD += ANGLE_STEP;
    }
    
    swfill_ndc_tri(&args, frame);
}

static void swfill_screentest_ndc(struct swrasterframe* frame)
{
    const float SIZE = 0.25f;
    const float DEPTH = 0.0f;
    
    const float AX = -SIZE;
    const float AY = -SIZE;
    const float AZ = DEPTH;
    
    const float BX = SIZE;
    const float BY = -SIZE;
    const float BZ = DEPTH;
    
    const float CX = 0.0f;
    const float CY = SIZE;
    const float CZ = DEPTH;
    
    struct swvertex abc[3] =
    {
        // struct swvertex
        {
            .position = { AX, AY, AZ, 1.0f },
            .color = { 255, 0, 0, 255 }
        },
        // struct swvertex
        {
            .position = { BX, BY, BZ, 1.0f },
            .color = { 255, 0, 0, 255 }
        },
        // struct swvertex
        {
            .position = { CX, CY, CZ, 1.0f },
            .color = { 255, 0, 0, 255 }
        }
    };
    
    struct swbasic_vertex vabc[3] = {0};
    
    for (size_t i = 0; i < 3; i++) {
        swfill_ndc_vertex_to_screen(&vabc[i], &abc[i], frame);
    }
    
    struct swtri_basic_vertex triangle;
    swtri_basic_vertex_from_verts(&triangle, &vabc[0], &vabc[1], &vabc[2]);
    
    swrasterize(frame, &triangle);
}

static void swfill_screentest_ndc_negatey(struct swrasterframe* frame)
{
    const float SIZE = 0.25f;
    const float DEPTH = 0.0f;
    
    const float AX = -SIZE;
    const float AY = -SIZE;
    const float AZ = DEPTH;
    
    const float BX = SIZE;
    const float BY = -SIZE;
    const float BZ = DEPTH;
    
    const float CX = 0.0f;
    const float CY = SIZE;
    const float CZ = DEPTH;
    
    struct swvertex abc[3] =
    {
        // struct swvertex
        {
            .position = { AX, AY, AZ, 1.0f },
            .color = { 255, 0, 0, 255 }
        },
        // struct swvertex
        {
            .position = { BX, BY, BZ, 1.0f },
            .color = { 255, 0, 0, 255 }
        },
        // struct swvertex
        {
            .position = { CX, CY, CZ, 1.0f },
            .color = { 255, 0, 0, 255 }
        }
    };
    
    struct swbasic_vertex vabc[3];
    
    for (size_t i = 0; i < 3; i++) {
        abc[i].position[1] = -abc[i].position[1];
        swfill_ndc_vertex_to_screen(&vabc[i], &abc[i], frame);
    }
    
    struct swtri_basic_vertex triangle;
    swtri_basic_vertex_from_verts(&triangle, &vabc[0], &vabc[1], &vabc[2]);
    
    swrasterize(frame, &triangle);
}

static void swfill_screentest_ndc_negatey_offsety(struct swrasterframe* frame)
{
    const float SIZE = 0.25f;
    const float DEPTH = 0.0f;
    const float YOFS = 0.5f;
    
    const float AX = -SIZE;
    const float AY = YOFS + -SIZE;
    const float AZ = DEPTH;
    
    const float BX = SIZE;
    const float BY = YOFS + -SIZE;
    const float BZ = DEPTH;
    
    const float CX = 0.0f;
    const float CY = YOFS + SIZE;
    const float CZ = DEPTH;
    
    struct swvertex abc[3] =
    {
        // struct swvertex
        {
            .position = { AX, AY, AZ, 1.0f },
            .color = { 255, 0, 0, 255 }
        },
        // struct swvertex
        {
            .position = { BX, BY, BZ, 1.0f },
            .color = { 255, 0, 0, 255 }
        },
        // struct swvertex
        {
            .position = { CX, CY, CZ, 1.0f },
            .color = { 255, 0, 0, 255 }
        }
    };
    
    struct swbasic_vertex vabc[3];
    
    for (size_t i = 0; i < 3; i++) {
        abc[i].position[1] = -abc[i].position[1];
        swfill_ndc_vertex_to_screen(&vabc[i], &abc[i], frame);
    }
    
    struct swtri_basic_vertex triangle;
    swtri_basic_vertex_from_verts(&triangle, &vabc[0], &vabc[1], &vabc[2]);
    
    swrasterize(frame, &triangle);
}

void swfill(struct swrasterframe* frame)
{
    enum swfillmode
    {
        SWFILLMODE_SCREENTEST_SCREENSPACE = 0,
        SWFILLMODE_SCREENTEST_SCREENSPACE_FLIPY,
        SWFILLMODE_SCREENTEST_NDC,
        SWFILLMODE_SCREENTEST_NDC_NEGATEY,
        SWFILLMODE_SCREENTEST_NDC_NEGATEY_OFFSETY,
        SWFILLMODE_SCREENTEST_NDC_NEGATEY_ROTATEX,
        SWFILLMODE_SCREENTEST_NDC_NEGATEY_ROTATEY,
        SWFILLMODE_SCREENTEST_NDC_NEGATEY_ROTATEZ
    };
    
    const enum swfillmode FILLMODE = SWFILLMODE_SCREENTEST_NDC_NEGATEY_ROTATEZ;
    
    vec3 rotate_ax = { 0 };
    
    switch (FILLMODE) {
        case SWFILLMODE_SCREENTEST_SCREENSPACE:
            swfill_screentest_screenspace(frame);
            break;
        case SWFILLMODE_SCREENTEST_SCREENSPACE_FLIPY:
            swfill_screentest_screenspace_flipy(frame);
            break;
        case SWFILLMODE_SCREENTEST_NDC:
            swfill_screentest_ndc(frame);
            break;
        case SWFILLMODE_SCREENTEST_NDC_NEGATEY:
            swfill_screentest_ndc_negatey(frame);
            break;
        case SWFILLMODE_SCREENTEST_NDC_NEGATEY_OFFSETY:
            swfill_screentest_ndc_negatey_offsety(frame);
            break;
        case SWFILLMODE_SCREENTEST_NDC_NEGATEY_ROTATEX:
            rotate_ax[0] = 1.0f;
            swfill_screentest_ndc_negatey_rotate(frame, rotate_ax);
            break;
        case SWFILLMODE_SCREENTEST_NDC_NEGATEY_ROTATEY:
            rotate_ax[1] = 1.0f;
            swfill_screentest_ndc_negatey_rotate(frame, rotate_ax);
            break;
        case SWFILLMODE_SCREENTEST_NDC_NEGATEY_ROTATEZ:
            rotate_ax[2] = 1.0f;
            swfill_screentest_ndc_negatey_rotate(frame, rotate_ax);
            break;
        
    }
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

#include "swfill_screentest.h"
#include "sw.h"
#include "common.h"

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
    
    struct swraster_vertex vabc[3];
    
    for (size_t i = 0; i < 3; i++) {
        memcpy(vabc[i].position, abc[i], sizeof(abc[0]));
        memcpy(vabc[i].color, color, sizeof(color));
    }
    
    struct swraster_tri triangle;
    swraster_tri_from_vertices(&triangle, &vabc[0], &vabc[1], &vabc[2]);
    
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
    
    struct swraster_vertex vabc[3];
    
    for (size_t i = 0; i < 3; i++) {
        memcpy(vabc[i].position, abc[i], sizeof(abc[0]));
        memcpy(vabc[i].color, color, sizeof(color));
    }
    
    struct swraster_tri triangle;
    swraster_tri_from_vertices(&triangle, &vabc[0], &vabc[1], &vabc[2]);
    
    swrasterize(frame, &triangle);
}

static void swfill_ndc_tri(struct vs_color* input, struct swrasterframe* frame)
{
    struct swattrib_vertex abc[3] =
    {
        // struct swvertex
        {
            .position = { input->abc[0][0], input->abc[0][1], input->abc[0][2], 1.0f },
            .color = { input->color[0][0], input->color[0][1], input->color[0][2], 1.0f }
        },
        // struct swvertex
        {
            .position = { input->abc[1][0], input->abc[1][1], input->abc[1][2], 1.0f },
            .color = { input->color[1][0], input->color[1][1], input->color[1][2], 1.0f }
        },
        // struct swvertex
        {
            .position = { input->abc[2][0], input->abc[2][1], input->abc[2][2], 1.0f },
            .color = { input->color[2][0], input->color[2][1], input->color[2][2], 1.0f }
        }
    };
    
    struct swraster_vertex vabc[3] = {0};
    
    for (size_t i = 0; i < 3; i++) {
        // need to make a copy, since here we're transforming abc[i].position to some other
        // vec (t) and then negating the axis - we do this last since that's the NDC' space
        // value (between NDC and screen space).
        //
        // we copy it back to abc[i].position, since swfill_ndc_vertex_to_screen is expecting a vertex,
        // not a position.
        {
            vec4 t = {0};
            
            mat4x4_mul_vec4(t, input->transform, abc[i].position);
           
            if (SWPIPELINE.clip_to_ndc_enabled) {
                for (size_t j = 0; j < 3; ++j) {
                    t[j] /= t[3];
                    t[j] = SWPIPELINE.negate_axes[j] ? (-t[j]) : (t[j]);
                }
            }
            else
            {
                for (size_t j = 0; j < 3; ++j) {
                    t[j] = SWPIPELINE.negate_axes[j] ? (-t[j]) : (t[j]);
                }
            }
            
            memcpy(abc[i].position, t, sizeof(t));
        }
        swfill_ndc_vertex_to_screen(&vabc[i], &abc[i], frame);
    }
    
    struct swraster_tri triangle;
    swraster_tri_from_vertices(&triangle, &vabc[0], &vabc[1], &vabc[2]);
    
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
    
    struct vs_color args =
    {
        // transform
        { 0 },
        // abc
        { { AX, AY, AZ, 1.0f },
            { BX, BY, BZ, 1.0f },
            { CX, CY, CZ, 1.0f } }
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
    
    struct swattrib_vertex abc[3] =
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
    
    struct swraster_vertex vabc[3] = {0};
    
    for (size_t i = 0; i < 3; i++) {
        swfill_ndc_vertex_to_screen(&vabc[i], &abc[i], frame);
    }
    
    struct swraster_tri triangle;
    swraster_tri_from_vertices(&triangle, &vabc[0], &vabc[1], &vabc[2]);
    
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
    
    struct swattrib_vertex abc[3] =
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
    
    struct swraster_vertex vabc[3];
    
    for (size_t i = 0; i < 3; i++) {
        abc[i].position[1] = -abc[i].position[1];
        swfill_ndc_vertex_to_screen(&vabc[i], &abc[i], frame);
    }
    
    struct swraster_tri triangle;
    swraster_tri_from_vertices(&triangle, &vabc[0], &vabc[1], &vabc[2]);
    
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
    
    struct swattrib_vertex abc[3] =
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
    
    struct swraster_vertex vabc[3];
    
    for (size_t i = 0; i < 3; i++) {
        abc[i].position[1] = -abc[i].position[1];
        swfill_ndc_vertex_to_screen(&vabc[i], &abc[i], frame);
    }
    
    struct swraster_tri triangle;
    swraster_tri_from_vertices(&triangle, &vabc[0], &vabc[1], &vabc[2]);
    
    swrasterize(frame, &triangle);
}

static void swfill_screentest_persp_clip_ndc_negatey(struct swrasterframe* frame, mat4x4 mod2cam)
{
    const struct mesh_template* tmpl = &g_mesh_template;
    
    struct vs_color args =
    {
        .transform =
        {
            0
        },
        .abc =
        {
            { tmpl->triangle[0][0], tmpl->triangle[0][1], tmpl->triangle[0][2], 1.0f },
            { tmpl->triangle[1][0], tmpl->triangle[1][1], tmpl->triangle[1][2], 1.0f },
            { tmpl->triangle[2][0], tmpl->triangle[2][1], tmpl->triangle[2][2], 1.0f }
        },
        .color =
        {
            COLORF_R,
            COLORF_G,
            COLORF_B
        }
    };
    
    memcpy(args.transform, mod2cam, sizeof(mat4x4));
    
    swfill_ndc_tri(&args, frame);
}

enum swtransformmode
{
    SWTRANSFORMMODE_IDENTITY = 0,
    SWTRANSFORMMODE_SCALE_ROTATE_TRANSLATE
};

static void screentest_model_to_camera(mat4x4 mod2cam, vec3 rotate_ax, float width, float height)
{
    const enum swtransformmode mode = SWTRANSFORMMODE_SCALE_ROTATE_TRANSLATE;
    
    static float ANGLE_RAD = 0.0f;
    static const float ANGLE_STEP = 0.05f;
    
    switch (mode) {
        case SWTRANSFORMMODE_IDENTITY:
        {
            mat4x4_identity(mod2cam);
        }
            break;
        case SWTRANSFORMMODE_SCALE_ROTATE_TRANSLATE:
        {
            struct matstack ms = {0};
            matstack_new(&ms);
            vec3 t = { 0.0f, 0.0f, -1.0f };
            vec3 s = { 0.25f, 0.25f, 0.25f };
            matstack_clip_default(&ms, width, height);
            matstack_translate(&ms, t);
            matstack_rotate(&ms, ANGLE_RAD, rotate_ax);
            matstack_scale(&ms, s);
            memcpy(mod2cam, ms.top.value, sizeof(ms.top.value));
            matstack_del(&ms);
        }
            break;
    }
    
    ANGLE_RAD += ANGLE_STEP;

}

void swfill_screentest(struct swrasterframe* frame)
{
    enum swfillmode_screentest
    {
        SWFILLMODE_SCREENTEST_SCREENSPACE = 0,
        SWFILLMODE_SCREENTEST_SCREENSPACE_FLIPY,
        SWFILLMODE_SCREENTEST_NDC,
        SWFILLMODE_SCREENTEST_NDC_NEGATEY,
        SWFILLMODE_SCREENTEST_NDC_NEGATEY_OFFSETY,
        SWFILLMODE_SCREENTEST_NDC_NEGATEY_ROTATEX,
        SWFILLMODE_SCREENTEST_NDC_NEGATEY_ROTATEY,
        SWFILLMODE_SCREENTEST_NDC_NEGATEY_ROTATEZ,
        SWFILLMODE_SCREENTEST_PERSP_CLIP_NDC_NEGATEY
    };
    
    const enum swfillmode_screentest FILLMODE = SWFILLMODE_SCREENTEST_PERSP_CLIP_NDC_NEGATEY;
    
    vec3 rotate_ax = { 0.0f, 1.0f, 0.0f };
    
    mat4x4 mod2cam = { 0 };
    screentest_model_to_camera(mod2cam, rotate_ax, frame->width, frame->height);
    
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
        case SWFILLMODE_SCREENTEST_PERSP_CLIP_NDC_NEGATEY:
            swfill_screentest_persp_clip_ndc_negatey(frame, mod2cam);
            break;
        
    }
}

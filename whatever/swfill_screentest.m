#include "swfill_screentest.h"
#include "sw.h"

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
    
    const enum swfillmode_screentest FILLMODE = SWFILLMODE_SCREENTEST_NDC_NEGATEY_ROTATEZ;
    
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
        case SWFILLMODE_SCREENTEST_PERSP_CLIP_NDC_NEGATEY:
            break;
        
    }
}

//
//  sw.h
//  whatever
//
//  Created by user on 10/13/22.
//

#ifndef sw_h
#define sw_h

#include "swcommon.h"


enum swpipeline_enum
{
    SWPIPELINE_MATRIX_CAMERA_TO_CLIP = 0,
    SWPIPELINE_MATRIX_MODEL_TO_CAMERA,
    SWPIPELINE_ERROR_NONE,
    SWPIPELINE_ERROR_ALLOC_FAILURE
};

void pipeline_setup(size_t frame_width, size_t frame_height);
void pipeline_teardown(void);
bool pipeline_valid(void);
void pipeline_draw_triangles(void);
void pipeline_matrix_rotate(float angle, vec3 axes);
void pipeline_matrix_translate(vec3 t);
void pipeline_matrix_scale(vec3 s);
void pipeline_matrix_perspective_wh(float width, float height);

void sw(struct swrasterframe* f);

void swfill(struct swrasterframe* frame);

void swfill_ndc_vertex_to_screen(struct swraster_vertex* result, const struct swattrib_vertex* vndc, const struct swrasterframe* frame);

void swrasterize(struct swrasterframe* frame, struct swraster_tri* triangle);

#endif /* sw_h */

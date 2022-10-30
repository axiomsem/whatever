//
//  sw.h
//  whatever
//
//  Created by user on 10/13/22.
//

#ifndef sw_h
#define sw_h

#include "swcommon.h"


void sw(struct swrasterframe* f);

void swfill(struct swrasterframe* frame);

void swfill_ndc_vertex_to_screen(struct swraster_vertex* result, const struct swattrib_vertex* vndc, const struct swrasterframe* frame);

void swrasterize(struct swrasterframe* frame, struct swraster_tri* triangle);

#endif /* sw_h */

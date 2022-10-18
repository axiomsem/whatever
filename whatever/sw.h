//
//  sw.h
//  whatever
//
//  Created by user on 10/13/22.
//

#ifndef sw_h
#define sw_h

#include "swcommon.h"

void swfill(struct swrasterframe* frame);

void swrasterize(struct swrasterframe* frame, struct swtri_basic_vertex* triangle);

#endif /* sw_h */

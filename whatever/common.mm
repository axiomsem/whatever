//
//  common.m
//  whatever
//
//  Created by user on 10/25/22.
//
#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// exclusive range test
#define in_range_ex(min, x, max) ((min < (x)) && ((x) < max))

static const size_t k_max_size = 1 << 24;

static size_t g_allocated = 0;

void* zalloc(size_t sz)
{
    void* p = NULL;
    if (in_range_ex(0, sz, k_max_size)) {
        p = malloc(sz);
        if (p != NULL) {
            g_allocated += sz;
            memset(p, 0, sz);
        }
        else {
            printf("oom for %lu with %lu currently used", sz, g_allocated);
        }
    }
    return p;
}

void zfree(void** p)
{
    if (p != NULL) {
        if (*p != NULL) {
            free(*p);
        }
        *p = NULL;
    }
}

const float deg2rad = WPI / 180.0f;

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

wresult_t stack_new(struct stack* s, size_t elem_size)
{
    const size_t initial_size = 20;
    stack_del(s);
    
    s->buffer = zalloc(elem_size * initial_size);
    s->elem_size = elem_size;
    s->length = initial_size;
    
    if (s->buffer != NULL) {
        return W_E_OK;
    }
    
    return W_E_FAIL;
}

void stack_del(struct stack* s)
{
    if (s != NULL) {
        zfree(s->buffer);
        memset(s, 0, sizeof(*s));
    }
}

void stack_push(struct stack* s, void* elem)
{
    if (s->top < s->length) {
        uint8_t* p1 = s->buffer;
        uint8_t* p2 = p1 + s->top * s->elem_size;
        memcpy(p2, elem, s->elem_size);
        s->top++;
    }
}

void* stack_peek(struct stack* s)
{
    if (s->top < s->length) {
        return (void*)(((uint8_t*)s->buffer) + (s->elem_size * s->top));
    }
    return NULL;
}

void stack_pop(struct stack* s)
{
    if (s != NULL) {
        if (s->top != NULL) {
            
        }
    }
}


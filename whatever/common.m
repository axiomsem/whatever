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

void oom_impl(const char* file, const char* func, int line)
{
    printf("out of memory: %s:%s:%i\n", file, func, line);
    exit(1);
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
    
    wresult_t ok = W_E_OK;
    
    if (s->buffer == NULL) {
        OOM();
        ok = W_E_FAIL;
    }
    
    return ok;
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
    if (s->top >= s->length) {
        s->length <<= 1;
        void* r = realloc(s->buffer, s->length * s->elem_size);
        if (r == NULL) {
            OOM();
        }
        s->buffer = r;
    }

    uint8_t* p1 = s->buffer;
    uint8_t* p2 = p1 + s->top * s->elem_size;
    memcpy(p2, elem, s->elem_size);
    s->top++;
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
    if (s->top > 0) {
        s->top--;
    }
}

wresult_t matstack_new(struct matstack* ms)
{
    matstack_del(ms);
    wresult_t ok = stack_new(&ms->s, sizeof(struct matstackelem));
    if (ok == W_E_OK) {
        mat4x4_identity(ms->top.value);
        stack_push(&ms->s, &ms->top);
    }
    return ok;
}

void matstack_rotate(struct matstack* ms, float angle, vec3 axes)
{
    mat4x4 tmp = {0};
    mat4x4_identity(tmp);
    struct matstackelem n = {0};
    mat4x4_rotate(n.value, tmp, axes[0], axes[1], axes[2], angle);
    mat4x4_mul(tmp, ms->top.value, n.value);
}

void matstack_del(struct matstack* ms)
{
    stack_del(&ms->s);
    memset(ms, 0, sizeof(*ms));
}


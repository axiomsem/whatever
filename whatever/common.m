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

const struct mesh_template g_mesh_template =
{
    // triangle
    {
        // A
        {
            -1.0f, -1.0f, 0.0f
        },
        // B
        {
            1.0f, -1.0f, 0.0f
        },
        // C
        {
            0.0f, 1.0f, 0.0f
        }
    }
};

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
        zfree(&s->buffer);
        memset(s, 0, sizeof(*s));
    }
}

wresult_t stack_push(struct stack* s, void* elem)
{
    wresult_t ok = W_E_OK;
    
    if (s->top >= s->length) {
        ok = W_E_FAIL;
        s->length <<= 1;
        void* r = realloc(s->buffer, s->length * s->elem_size);
        if (r != NULL) {
            s->buffer = r;
            ok = W_E_OK;
        }
        else {
            OOM();
        }
        
    }
    
    if (ok == W_E_OK) {
        uint8_t* p1 = s->buffer;
        uint8_t* p2 = p1 + s->top * s->elem_size;
        memcpy(p2, elem, s->elem_size);
        s->top++;
    }
    
    return ok;
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

void matstack_mul(struct matstack* ms, mat4x4 m)
{
    mat4x4 tmp2 = {0};
    mat4x4_mul(tmp2, ms->top.value, m);
    memcpy(ms->top.value, tmp2, sizeof(tmp2));
    stack_push(&ms->s, &ms->top);
}

wresult_t matstack_new(struct matstack* ms)
{
    matstack_del(ms);
    wresult_t ok = stack_new(&ms->s, sizeof(struct matstackelem));
    if (ok == W_E_OK) {
        mat4x4_identity(ms->top.value);
        ok = stack_push(&ms->s, &ms->top);
    }
    return ok;
}

void matstack_rotate(struct matstack* ms, float angle, vec3 axes)
{
    mat4x4 tmp = {0};
    mat4x4_identity(tmp);
    mat4x4 rot = {0};
    mat4x4_identity(rot);
    mat4x4_rotate(rot, tmp, axes[0], axes[1], axes[2], angle);
    matstack_mul(ms, rot);
}

void matstack_clip_default(struct matstack* ms, float width, float height)
{
    mat4x4 tmp;
    mat4x4_identity(tmp);
    mat4x4_perspective(tmp, 45.0f * deg2rad, width / height, 0.01f, 100.0f);
    matstack_mul(ms, tmp);
}

void matstack_translate(struct matstack* ms, vec3 v)
{
    mat4x4 tmp = {0};
    mat4x4_identity(tmp);
    mat4x4_translate(tmp, v[0], v[1], v[2]);
    matstack_mul(ms, tmp);
}

void matstack_scale(struct matstack* ms, vec3 v)
{
    mat4x4 tmp = {0};
    mat4x4_identity(tmp);
    
    tmp[0][0] = v[0];
    tmp[1][1] = v[1];
    tmp[2][2] = v[2];
    
    matstack_mul(ms, tmp);
}

void matstack_del(struct matstack* ms)
{
    stack_del(&ms->s);
    memset(ms, 0, sizeof(*ms));
}



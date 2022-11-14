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
#include <stdbool.h>
#import <Foundation/Foundation.h>

// exclusive range test
#define in_range_ex(min, x, max) ((min < (x)) && ((x) < max))

static const size_t k_max_size = 1 << 31;

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

bool chkres_impl(wresult_t result, const char* expr, const char* file, const char* func, int line)
{
    bool ret = true;
    
    if (result != W_E_OK) {
        printf("WARNING: error reported for %s. Value given: %i, at %s:%s:%i\n", expr, result, file, func, line);
        ret = false;
    }
    
    return ret;
}

bool chk_impl(bool value, const char* expr, const char* file, const char* func, int line)
{
    if (!value) {
        NSLog(@"FATAL ERROR for %s. at %s:%s:%i\n", expr, file, func, line);
        exit(1);
    }
    
    return value;
}

static volatile int NOP_X = 0;
void __nop(void)
{
    volatile int x = 0;
    x++;
    x++;
    x++;
    NOP_X += x * 3;
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

void matstack_perspective(struct matstack* ms, float fovydeg, float width, float height, float znear, float zfar)
{
    mat4x4 tmp;
    mat4x4_identity(tmp);
    mat4x4_perspective(tmp, fovydeg * deg2rad, width / height, znear, zfar);
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

// input: p, a, b, c - abc are vertices; p is point within triangle
// output: uvw -> au + vb + cw = p -> u + v + w = 1
//
// vec v0 = b - a, v1 = c - a, v2 = p - a
// d00 = dot v0 v0
// d01 = dot v0 v1
// d11 = dot v1 v1
// d20 = dot v2 v0
// d21 = dot v2 v1
//
// denom = d00 * d11 - d01 * d01
// v = (d11 * d20 - d01 * d21) / denom
// w = (d00 * d21 - d01 * d20) / denom
// output: uvw -> au + vb + cw = p -> u + v + w = 1
void tri_interp_screen(struct tri_interp_screen_in* input, vec4 output_color)
{
    vec2 v0, v1, v2;
    vec2_sub(v0, input->abc_pos[1], input->abc_pos[0]);
    vec2_sub(v1, input->abc_pos[2], input->abc_pos[0]);
    vec2_sub(v2, input->p, input->abc_pos[0]);
    
    float d00 = vec2_dot(v0, v0);
    float d01 = vec2_dot(v0, v1);
    float d11 = vec2_dot(v1, v1);
    float d20 = vec2_dot(v2, v0);
    float d21 = vec2_dot(v2, v1);
    
    float denom = 1.0f / (d00 * d11 - d01 * d01);
    
    float v = (d11 * d20 - d01 * d21) * denom;
    float w = (d00 * d21 - d01 * d20) * denom;
    float u = 1.0f - v - w;
    
    output_color[0] = input->abc_col[0][0] * u + input->abc_col[1][0] * v + input->abc_col[2][0] * w;
    output_color[1] = input->abc_col[0][1] * u + input->abc_col[1][1] * v + input->abc_col[2][1] * w;
    output_color[2] = input->abc_col[0][2] * u + input->abc_col[1][2] * v + input->abc_col[2][2] * w;
    output_color[3] = 1.0f;
}



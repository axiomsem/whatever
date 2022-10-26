//
//  common.h
//  whatever
//
//  Created by user on 10/25/22.
//

#ifndef common_h
#define common_h

#include "linmath.h"

#define WPI 3.1415926535f

extern const float deg2rad;

typedef int wresult_t;

#define W_E_OK 0
#define W_E_FAIL (-1)

void* zalloc(size_t s);

void zfree(void** p);

void oom_impl(const char* file, const char* func, int line);

#define OOM() oom_impl(__FILE__, __func__, __LINE__)

float dist_from_point_to_edge(vec2 point, vec2 edge_point, vec2 normal);

struct stack
{
    void* buffer;
    size_t top;
    size_t length;
    size_t elem_size;
};

wresult_t stack_new(struct stack* s, size_t elem_size);
void stack_del(struct stack* s);
wresult_t stack_push(struct stack* s, void * elem);
void* stack_peek(struct stack* s);
void stack_pop(struct stack* s);

struct matstackelem {
    mat4x4 value;
};

struct matstack {
    struct stack s;
    struct matstackelem top;
};

wresult_t matstack_new(struct matstack* ms);
void matstack_rotate(struct matstack* ms, float angle, vec3 axes);
void matstack_del(struct matstack* ms);

#endif /* common_h */

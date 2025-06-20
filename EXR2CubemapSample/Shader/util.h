#ifndef util_h
#define util_h

#include <metal_stdlib>
using namespace metal;

float2x2 inverse(float2x2 matrix);
float3x3 inverse(float3x3 m);
float3x3 _3x3(float4x4 matrix);

#endif /* util_h */

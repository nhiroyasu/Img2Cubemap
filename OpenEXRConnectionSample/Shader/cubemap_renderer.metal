#include <metal_stdlib>
#include "util.h"
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texcoord [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 worldPosition;
    float3 normal;
};

vertex VertexOut cubemap_vertex(VertexIn in [[stage_in]],
                                constant float4x4 &model [[buffer(1)]],
                                constant float4x4 &view [[buffer(2)]],
                                constant float4x4 &projection [[buffer(3)]])
{
    float4x4 mvp = projection * view * model;
    float4 position = mvp * float4(in.position, 1.0);
    float4 worldPosition = model * float4(in.position, 1.0);
    float3 normal = normalize(transpose(inverse(_3x3(model))) * in.normal);

    VertexOut out;
    out.position = position;
    out.worldPosition = worldPosition;
    out.normal = normal;
    return out;
}

fragment float4 cubemap_fragment(VertexOut in [[stage_in]],
                                 texturecube<float, access::sample> cubemap [[texture(0)]])
{
    sampler sampler(mag_filter::linear, min_filter::linear, mip_filter::linear);

    float4 color = cubemap.sample(sampler, normalize(in.worldPosition).xyz);

    return color;
}

//
//  shader.metal
//  OpenEXRConnection
//
//  Created by NH on 2025/05/18.
//

#include <metal_stdlib>
using namespace metal;


kernel void generateCubeMap(uint2 gid [[thread_position_in_grid]],
                            texture2d<float, access::sample> inputTexture [[texture(0)]],
                            texturecube<float, access::write> outputCubeMap [[texture(1)]],
                            constant uint &face [[buffer(0)]],
                            constant uint &size [[buffer(1)]])
{
    if (gid.x >= size || gid.y >= size) {
        return;
    }

    sampler textureSampler(mag_filter::linear, min_filter::linear);

    float x = float(gid.x);
    float y = float(size - 1) - float(gid.y);

    float a = 2.0 * (x + 0.5) / size - 1.0; // x in [-1, 1]
    float b = 2.0 * (y + 0.5) / size - 1.0; // y in [-1, 1]

    float3 dir;

    switch (face) {
        case 0: // Positive X
            dir = float3(1.0, b, -a);
            break;
        case 1: // Negative X
            dir = float3(-1.0, b, a);
            break;
        case 2: // Positive Y
            dir = float3(a, 1.0, -b);
            break;
        case 3: // Negative Y
            dir = float3(a, -1.0, b);
            break;
        case 4: // Positive Z
            dir = float3(a, b, 1.0);
            break;
        case 5: // Negative Z
            dir = float3(-a, b, -1.0);
            break;
        default:
            dir = float3(-1.0);
            break;
    }
    dir = normalize(dir);

    float u = 0.5 + atan2(-dir.x, dir.z) / (2.0 * M_PI_F);
    float v = 0.5 + asin(dir.y) / M_PI_F;

    float4 color = inputTexture.sample(textureSampler, float2(u, 1.0 - v));

    outputCubeMap.write(color, gid, face);
}


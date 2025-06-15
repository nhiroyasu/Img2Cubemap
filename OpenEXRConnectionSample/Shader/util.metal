#include <metal_stdlib>
using namespace metal;

float2x2 inverse(float2x2 matrix) {
    float det = determinant(matrix);
    if (det == 0.0) {
        return matrix;
    }
    return float2x2(matrix[1][1], -matrix[0][1],
                    -matrix[1][0], matrix[0][0]) / det;
}

float3x3 inverse(float3x3 m) {
    float a00 = m[0][0], a01 = m[0][1], a02 = m[0][2];
    float a10 = m[1][0], a11 = m[1][1], a12 = m[1][2];
    float a20 = m[2][0], a21 = m[2][1], a22 = m[2][2];

    float det = determinant(m);
    if (abs(det) < 1e-6) return float3x3(1.0); // fallback identity

    float invDet = 1.0 / det;

    float3x3 inv;

    inv[0][0] =  (a11 * a22 - a12 * a21) * invDet;
    inv[0][1] = -(a01 * a22 - a02 * a21) * invDet;
    inv[0][2] =  (a01 * a12 - a02 * a11) * invDet;

    inv[1][0] = -(a10 * a22 - a12 * a20) * invDet;
    inv[1][1] =  (a00 * a22 - a02 * a20) * invDet;
    inv[1][2] = -(a00 * a12 - a02 * a10) * invDet;

    inv[2][0] =  (a10 * a21 - a11 * a20) * invDet;
    inv[2][1] = -(a00 * a21 - a01 * a20) * invDet;
    inv[2][2] =  (a00 * a11 - a01 * a10) * invDet;

    return inv;
}

float3x3 _3x3(float4x4 matrix) {
    return float3x3(matrix[0].xyz, matrix[1].xyz, matrix[2].xyz);
}

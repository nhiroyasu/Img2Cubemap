#ifndef wrapper_h
#define wrapper_h

#include <simd/simd.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SUCCESS 0
#define FAILURE -1

struct {
    int width;
    int height;
    simd_half4 *color;
} typedef ReadExrOut;

int readExrFile(char *path, ReadExrOut *output);

#ifdef __cplusplus
}
#endif

#endif /* wrapper_h */

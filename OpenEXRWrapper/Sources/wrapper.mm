#import <Foundation/Foundation.h>
#import <os/log.h>
#import <simd/simd.h>
#import "ImfRgbaFile.h"
#import "ImfArray.h"
#import "ImfChannelList.h"
#import "ImfHeader.h"
#import "wrapper.h"

using namespace Imf;
using namespace Imath;

int readExrFile(char *path, ReadExrOut *output) {
    try {
        RgbaInputFile file(path);
        Box2i dw = file.dataWindow();
        int width = dw.max.x - dw.min.x + 1;
        int height = dw.max.y - dw.min.y + 1;

        const ChannelList &channels = file.header().channels();
        for (ChannelList::ConstIterator it = channels.begin(); it != channels.end(); ++it) {
            os_log(OS_LOG_DEFAULT, "Channel: %s, Type: %d", it.name(), it.channel().type);
        }

        Array2D<Rgba> pixels(height, width);

        file.setFrameBuffer(&pixels[0][0], 1, width);
        file.readPixels(dw.min.y, dw.max.y);

        os_log(OS_LOG_DEFAULT, "EXR file read successfully. Width: %d, Height: %d", width, height);

        simd_half4 *color = (simd_half4 *)malloc(sizeof(simd_half4) * width * height);
        if (!color) {
            os_log(OS_LOG_DEFAULT, "Memory allocation failed.");
            return FALSE;
        }

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                Rgba &pixel = pixels[y][x];
                color[y * width + x] = {
                    static_cast<_Float16>(pixel.r),
                    static_cast<_Float16>(pixel.g),
                    static_cast<_Float16>(pixel.b),
                    static_cast<_Float16>(pixel.a)
                };
            }
        }

        output->color = color;
        output->width = width;
        output->height = height;

    } catch (const std::exception &e) {
        os_log(OS_LOG_DEFAULT, "Error reading EXR: %s", e.what());
        free(output->color);
        return FAILURE;
    }

    return SUCCESS;
}

simd_half4 ReadExrOutGetColor(ReadExrOut *output, int x, int y) {
    if (x < 0 || x >= output->width || y < 0 || y >= output->height) {
        os_log(OS_LOG_DEFAULT, "Coordinates out of bounds: (%d, %d)", x, y);
        return {0.0f, 0.0f, 0.0f, 0.0f};
    }
    return output->color[y * output->width + x];
}

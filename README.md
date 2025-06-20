# EXR2Cubemap

A Swift package for loading 360-degree images (in equirectangular format) from EXR files.

## Features

- Converts equirectangular EXR files into cubemap `MTLTexture`s.

## Install

### Framework

Coming soon...

## Usage

```swift
import EXR2Cubemap

func load(url: URL) async throws {
    let device = MTLCreateSystemDefaultDevice()!
    let texture = try await generateCubeTexture(device: device, from: url)

    // You can now use the cubemap texture
    // ...
}
```

## Preview

| Equirectangular EXR | Cubemap Texture | Preview |
| --- | --- | --- |
| <img src="./README_ASSETS/equirectangular.jpg" width="300"> | <img src="./README_ASSETS/cubemap.png" width="300"> | <img src="./README_ASSETS/preview.png" width="300"> |

## Sample Project

Use the `EXR2CubemapSample` project to see how to use EXR2Cubemap.

### Prepare

1. Clone the repository
2. Install CMake
3. Run `make` to build the static library of OpenEXR
4. Open `EXR2Cubemap.xcodeproj`
5. Select the `EXR2CubemapSample` scheme and build it

## Build

To build locally, follow the same steps listed in the Sample Project's "Prepare" section.


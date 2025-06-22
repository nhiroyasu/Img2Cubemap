# Img2Cubemap

A Swift package for loading 360-degree images (in equirectangular format) from EXR files.

## Features

- Converts equirectangular EXR files into cubemap `MTLTexture`s.

## Install

### Framework

Coming soon...

## Usage

```swift
import Img2Cubemap

func loadEXR(url: URL) async throws {
    let device = MTLCreateSystemDefaultDevice()!
    let texture = try await generateCubeTexture(device: device, exr: url)

    // You can now use the cubemap texture
    // ...
}
```

## Preview

| Equirectangular EXR | Cubemap Texture | Preview |
| --- | --- | --- |
| <img src="./README_ASSETS/equirectangular.jpg" width="300"> | <img src="./README_ASSETS/cubemap.png" width="300"> | <img src="./README_ASSETS/preview.png" width="300"> |

## Sample Project

Use the `Img2CubemapSample` project to see how to use Img2Cubemap.

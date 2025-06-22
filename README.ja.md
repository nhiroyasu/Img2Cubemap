# EXR2Cubemap
EXRファイルから360度画像(Equirectangular形式の画像)を読み込むためのSwiftパッケージです。

## Features
- Equirectangular形式のEXRファイルからCubemapのMTLTextureを生成できます

## Install
### Swift Package Manager
```
.package(url: "https://github.com/nhiroyasu/Img2Cubemap.git", from: "0.1.0"),
```

## Usage
```swift
import EXR2Cubemap

func loadEXR(url: URL) async throws {
    let device = MTLCreateSystemDefaultDevice()!
    let texture = try await generateCubeTexture(device: device, exr: url)

    // CubemapのTextureを使用できます
    // ...
}
```

## Preview
| Equirectangular EXR | Cubemap Texture | Preview |
| --- | --- | --- |
| <img src="./README_ASSETS/equirectangular.jpg" width="300"> | <img src="./README_ASSETS/cubemap.png" width="300"> | <img src="./README_ASSETS/preview.png" width="300"> |

## Sample Project
EXR2CubemapSample プロジェクトを使用して、EXR2Cubemapの使用方法を確認できます。

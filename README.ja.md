# EXR2Cubemap
EXRファイルから360度画像(Equirectangular形式の画像)を読み込むためのSwiftパッケージです。

## Features
- Equirectangular形式のEXRファイルからCubemapのMTLTextureを生成できます

## Install
### Framework
準備中...

## Usage
```swift
import EXR2Cubemap

func load(url: URL) async throws {
    let device = MTLCreateSystemDefaultDevice()!
    let texture = try await generateCubeTexture(device: device, from: url)

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

### Prepare
1. リポジトリをクローンする 
1. CMakeをインストール
1. `make` を実行して、OpenEXRの静的ライブラリを作成する
1. `EXR2Cubemap.xcodeproj` を開く
1. `EXR2CubemapSample` スキーマを選択してビルドする

## Build
手元でビルドする場合も、Sample ProjectのPrepareと同様の手順を実行してください。

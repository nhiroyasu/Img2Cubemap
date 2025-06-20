 # Directory Structure

 以下は、このプロジェクトのディレクトリ構造と主要コンポーネントの概要です。

 ```
 .
 ├── CMakeLists.txt                 # CMakeビルドスクリプト（OpenEXRライブラリ）
 ├── Makefile                       # OpenEXR静的ライブラリ構築用Makefile
 ├── LICENSE                        # ライセンス情報
 ├── ThirdPartyNotices.txt          # サードパーティライブラリの通知
 ├── README.md                      # 英語版README
 ├── README.ja.md                   # 日本語版README
 ├── README_ASSETS/                 # README用サンプル画像
 │   ├── equirectangular.jpg        # 入力EXRプレビュー用画像
 │   ├── cubemap.png                # 出力キューブマッププレビュー
 │   └── preview.png                # 表示例プレビュー
 ├── openexr_build/                 # CMakeビルド中間成果物ディレクトリ
 │   └── （CMakeFiles, キャッシュ, ログ等）
 ├── openexr_output/                # インストール成果物（OpenEXR）
 │   ├── bin/
 │   ├── include/
 │   ├── lib/
 │   └── share/
 ├── OpenEXRConnection/             # Swiftパッケージ：EXR→キューブマップ
 │   ├── generate_cubemap_texture.metal  # Metalコンピュートシェーダ
 │   ├── OpenEXRConnection.docc          # DocCドキュメントカタログ
 │   ├── OpenEXRConnection.h             # フレームワーク公開ヘッダ
 │   └── Sources/                        # Swiftソース
 │       ├── connection.swift            # ファイル読み込み＆テクスチャ生成
 │       ├── OpenEXRConnectionError.swift# エラー定義
 │       └── DummyClassInFramework.swift # リソースバンドル参照用ダミークラス
 ├── OpenEXRConnectionSample/        # サンプルXcodeプロジェクト
 │   ├── AppDelegate.swift
 │   ├── ViewController.swift
 │   ├── Assets.xcassets
 │   ├── Base.lproj/
 │   ├── Resources/
 │   ├── Shader/
 │   ├── View/
 │   ├── Matrix/
 │   ├── OpenEXRConnection.entitlements
 │   └── README.md
 ├── OpenEXRWrapper/                 # Objective-C++ラッパー：OpenEXR C++ API
 │   ├── OpenEXRWrapper.docc         # DocCドキュメントカタログ
 │   ├── OpenEXRWrapper.h            # フレームワーク公開ヘッダ
 │   └── Sources/
 │       ├── wrapper.h                # Cインターフェイス宣言
 │       └── wrapper.mm               # 実装（ImfRgbaFile利用）
 └── OpenEXRConnection.xcodeproj     # Xcodeプロジェクトファイル
 ```
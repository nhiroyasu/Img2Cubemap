SCRIPT := ./build-metallib.sh
SRC_DIR := Sources/Img2Cubemap/Shader
OUT_DIR := Sources/Img2Cubemap/Resources
PLATFORMS := macosx iphoneos iphonesimulator xros

# .metal ファイルのリストを取得
METAL_SRCS := $(wildcard $(SRC_DIR)/*.metal)

# 各プラットフォーム用のmetallib出力パスを定義
METALLIBS := $(foreach sdk, $(PLATFORMS), $(OUT_DIR)/Img2Cubemap.$(sdk).metallib)

# デフォルトターゲット
.PHONY: all
all: $(METALLIBS)

# 各 metallib の生成ルール
$(OUT_DIR)/Img2Cubemap.%.metallib: $(METAL_SRCS) $(SCRIPT)
	sh $(SCRIPT) $*

# 個別プラットフォーム指定
.PHONY: $(PLATFORMS)
$(PLATFORMS):
	$(MAKE) $(OUT_DIR)/Img2Cubemap.$@.metallib

# クリーンアップ
.PHONY: clean
clean:
	rm -f $(OUT_DIR)/*.air
	rm -f $(OUT_DIR)/*.metallib

.PHONY: all build

buildDir = $(CURDIR)/openexr_build

all: build

build:
	mkdir -p $(buildDir)
	cmake -S $(CURDIR) -B $(buildDir) -D CMAKE_BUILD_TYPE=Release -D BUILD_SHARED_LIBS=OFF
	cmake --build $(buildDir) --target AllDeps
	find $(CURDIR)/openexr_output/lib/ \( -type f -o -type l \) -name "*.dylib" -delete
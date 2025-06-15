cmake_minimum_required(VERSION 3.14)
project(MyProject)

include(ExternalProject)

set(INSTALL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/openexr_output)

# 1. libdeflate
ExternalProject_Add(libdeflate
  GIT_REPOSITORY https://github.com/ebiggers/libdeflate.git
  GIT_TAG        v1.23
  UPDATE_DISCONNECTED TRUE
  CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
    -DBUILD_SHARED_LIBS=OFF
)

# 2. Imath
ExternalProject_Add(Imath
  GIT_REPOSITORY https://github.com/AcademySoftwareFoundation/Imath.git
  GIT_TAG        v3.1.12
  UPDATE_DISCONNECTED TRUE
  CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
    -DBUILD_SHARED_LIBS=OFF
)

# 3. OpenEXR
ExternalProject_Add(
  OpenEXR
  GIT_REPOSITORY https://github.com/AcademySoftwareFoundation/openexr.git 
  GIT_TAG        v3.3.3
  UPDATE_DISCONNECTED TRUE

  CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
    -DBUILD_SHARED_LIBS=OFF

  DEPENDS Imath libdeflate

  STEP_TARGETS configure build install
  BUILD_ALWAYS OFF
)

add_custom_target(AllDeps DEPENDS libdeflate Imath OpenEXR)
cmake_minimum_required(VERSION 3.14)
project(AudioEngineWindows LANGUAGES CXX)

add_library(AudioEngineWindows STATIC
  src/AudioEngineWindows.cpp
)

set(FFMPEG_ROOT "${CMAKE_SOURCE_DIR}/../third_party/ffmpeg-audio")

target_include_directories(AudioEngineWindows
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${FFMPEG_ROOT}/include
)

target_compile_features(AudioEngineWindows PUBLIC cxx_std_17)
target_compile_definitions(AudioEngineWindows PRIVATE UNICODE _UNICODE NOMINMAX)
target_compile_options(AudioEngineWindows PRIVATE /utf-8)

target_link_libraries(AudioEngineWindows
  PUBLIC
    avformat
    avcodec
    avutil
    swresample
    mfuuid
    ole32
    mmdevapi
    avrt
)

target_link_directories(AudioEngineWindows PUBLIC
  ${FFMPEG_ROOT}/lib
  ${FFMPEG_ROOT}/bin
)

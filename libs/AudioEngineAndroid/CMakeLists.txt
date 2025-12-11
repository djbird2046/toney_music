cmake_minimum_required(VERSION 3.22)
project(audioengineandroid LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Path to FFmpeg prebuilts (one subfolder per ABI). Update this to match your layout.
set(FFMPEG_PREBUILT_ROOT "${CMAKE_CURRENT_LIST_DIR}/prebuilt")

set(FFMPEG_PREBUILT_ROOT "${CMAKE_CURRENT_LIST_DIR}/prebuilt")
set(FFMPEG_SOURCE_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../third_party/FFmpeg")

add_library(audioengineandroid SHARED
    src/main/cpp/AudioEngineJNI.cpp
    src/main/cpp/AudioEngine.cpp
)

target_include_directories(audioengineandroid PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/src/main/cpp
    ${FFMPEG_PREBUILT_ROOT}/${ANDROID_ABI}/include
    ${FFMPEG_SOURCE_ROOT}
)

# Link against FFmpeg if available; otherwise link only to system libs.
if(EXISTS "${FFMPEG_PREBUILT_ROOT}/${ANDROID_ABI}/lib/libffmpeg.so")
    add_library(ffmpeg SHARED IMPORTED GLOBAL)
    set_target_properties(ffmpeg PROPERTIES
        IMPORTED_LOCATION "${FFMPEG_PREBUILT_ROOT}/${ANDROID_ABI}/lib/libffmpeg.so"
    )
    target_link_libraries(audioengineandroid PRIVATE ffmpeg)
elseif(EXISTS "${FFMPEG_PREBUILT_ROOT}/${ANDROID_ABI}/lib/libavformat.so")
    add_library(avformat SHARED IMPORTED GLOBAL)
    add_library(avcodec SHARED IMPORTED GLOBAL)
    add_library(avutil SHARED IMPORTED GLOBAL)
    add_library(swresample SHARED IMPORTED GLOBAL)
    set_target_properties(avformat PROPERTIES IMPORTED_LOCATION "${FFMPEG_PREBUILT_ROOT}/${ANDROID_ABI}/lib/libavformat.so")
    set_target_properties(avcodec PROPERTIES IMPORTED_LOCATION "${FFMPEG_PREBUILT_ROOT}/${ANDROID_ABI}/lib/libavcodec.so")
    set_target_properties(avutil PROPERTIES IMPORTED_LOCATION "${FFMPEG_PREBUILT_ROOT}/${ANDROID_ABI}/lib/libavutil.so")
    set_target_properties(swresample PROPERTIES IMPORTED_LOCATION "${FFMPEG_PREBUILT_ROOT}/${ANDROID_ABI}/lib/libswresample.so")
    target_link_libraries(audioengineandroid PRIVATE avformat avcodec avutil swresample)
endif()

target_link_libraries(audioengineandroid PRIVATE log android aaudio)

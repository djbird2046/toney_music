cmake_minimum_required(VERSION 3.14)
project(MoodEngineWindows LANGUAGES CXX)

add_library(MoodEngineWindows STATIC
  src/MoodEngineWindows.cpp
)

target_include_directories(MoodEngineWindows
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_features(MoodEngineWindows PUBLIC cxx_std_17)
target_compile_definitions(MoodEngineWindows PRIVATE UNICODE _UNICODE NOMINMAX)
target_compile_options(MoodEngineWindows PRIVATE /utf-8)

target_link_libraries(MoodEngineWindows
  PUBLIC
    iphlpapi
    advapi32
    ole32
    mmdevapi
)

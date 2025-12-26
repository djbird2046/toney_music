cmake_minimum_required(VERSION 3.14)
project(MediaSessionWindows LANGUAGES CXX)

add_library(MediaSessionWindows STATIC
  src/plugin.cpp
)

target_include_directories(MediaSessionWindows
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/flutter/ephemeral/cpp_client_wrapper/include
    ${CMAKE_SOURCE_DIR}/flutter/ephemeral
)

target_compile_features(MediaSessionWindows PUBLIC cxx_std_17)
target_compile_definitions(MediaSessionWindows PRIVATE UNICODE _UNICODE NOMINMAX)
target_compile_options(MediaSessionWindows PRIVATE /utf-8)

target_link_libraries(MediaSessionWindows
  PUBLIC
    flutter_wrapper_plugin
    runtimeobject
    ole32
    shell32
    user32
    gdi32
)

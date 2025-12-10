cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "audio_engine_channel.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_link_libraries(${BINARY_NAME} PRIVATE AudioEngineWindows)
target_link_libraries(${BINARY_NAME} PRIVATE mfreadwrite mfplat mfuuid)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}/../libs/AudioEngineWindows/include")

# Copy FFmpeg runtime DLLs beside the executable.
set(FFMPEG_BIN_DIR "${CMAKE_SOURCE_DIR}/../third_party/ffmpeg-audio/bin")
add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${FFMPEG_BIN_DIR}/avcodec-62.dll"
    "${FFMPEG_BIN_DIR}/avformat-62.dll"
    "${FFMPEG_BIN_DIR}/avutil-60.dll"
    "${FFMPEG_BIN_DIR}/swresample-6.dll"
    $<TARGET_FILE_DIR:${BINARY_NAME}>
)

# Copy MinGW runtime dependencies required by the FFmpeg DLLs.
set(MINGW_BIN "C:/msys64/mingw64/bin")
add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${MINGW_BIN}/libgcc_s_seh-1.dll"
    "${MINGW_BIN}/libstdc++-6.dll"
    "${MINGW_BIN}/libwinpthread-1.dll"
    "${MINGW_BIN}/zlib1.dll"
    "${MINGW_BIN}/libbz2-1.dll"
    "${MINGW_BIN}/liblzma-5.dll"
    "${MINGW_BIN}/libiconv-2.dll"
    $<TARGET_FILE_DIR:${BINARY_NAME}>
)

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

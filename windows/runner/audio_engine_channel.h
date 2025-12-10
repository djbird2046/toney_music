#pragma once

#include <flutter/flutter_engine.h>

// Registers a MethodChannel named "audio_engine" and wires it to the native
// AudioEngineWindows implementation.
void RegisterAudioEngineChannel(flutter::FlutterEngine* engine);

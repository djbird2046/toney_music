#pragma once

#include <flutter/flutter_engine.h>

// Registers a MethodChannel named "mood_engine" and wires it to the native
// MoodEngineWindows implementation.
void RegisterMoodEngineChannel(flutter::FlutterEngine* engine);

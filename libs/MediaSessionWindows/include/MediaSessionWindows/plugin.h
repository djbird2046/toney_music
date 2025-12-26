#pragma once

#include <flutter/flutter_engine.h>

// Forward-declare HWND without pulling in <windows.h> from a public header.
typedef struct HWND__* HWND;

namespace mediasession_windows {

void RegisterMediaSessionWindows(flutter::FlutterEngine* engine, HWND window);

// Handles WM_COMMAND ids coming from the top-level window to support taskbar
// thumbnail toolbar buttons. Returns true if handled.
bool HandleMediaSessionWindowsCommand(int command_id);

}  // namespace mediasession_windows

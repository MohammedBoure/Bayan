# Windows Runner Directory

This directory contains the native C++ Win32 host executable implementation for the Flutter application.

## Files:
- `main.cpp`: Standard Windows entry point (`wWinMain`), initializes COM, Dart runtime entry point, and the message loop.
- `flutter_window.cpp` / `flutter_window.h`: Subclass of `Win32Window` hosting the Flutter view controller and coordinating plugins.
- `win32_window.cpp` / `win32_window.h`: Low-level Win32 window creation, message handling, DPI scaling, and theming.
- `utils.cpp` / `utils.h`: Helper utilities for command-line string conversions and console attachment.
- `resource.h` / `Runner.rc`: Win32 resource script defining application icons and version information.
- `runner.exe.manifest`: Application manifest declaring Per-Monitor DPI awareness and compatibility GUIDs for Windows 7, Windows 8, Windows 8.1, and Windows 10/11.
- `CMakeLists.txt`: CMake rules compiling the native runner executable.

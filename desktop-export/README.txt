Empires of Olympus — Windows build
=================================

REQUIREMENTS
- 64-bit Windows (x86_64). Will NOT run on macOS, Linux, or ARM Windows.

HOW TO RUN (THIS FOLDER)
1. Keep ALL of these files in the SAME folder:
     game.exe
     game.pck
     game.console.exe   (optional — shows error text)
2. Double-click game.exe
3. If the window closes instantly, run game.console.exe instead and read the message.

COMMON "CRASH" CAUSE
If game.pck is missing or renamed, Godot exits immediately with:
  "Is the .pck file missing?"
That looks like a crash when you only open game.exe.
Download BOTH game.exe AND game.pck (or use the single-file zip from the agent artifacts).

BETTER DOWNLOAD
Prefer EmpiresOfOlympus-Windows.zip (single EmpiresOfOlympus.exe with data embedded).
No separate .pck needed. Use EmpiresOfOlympus.console.exe if it fails.

IF IT STILL CRASHES
1. Run game.console.exe / EmpiresOfOlympus.console.exe and copy the text.
2. Or open: %APPDATA%\Godot\app_userdata\Empires of Olympus\logs\godot.log
3. Allow the exe through SmartScreen / antivirus.
4. Update GPU drivers (this build uses OpenGL Compatibility + ANGLE/D3D11).

CONTROLS
WASD move, mouse look, click attack, Q god-skill, E interact, F block, C dodge

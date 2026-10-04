Empires of Olympus — Windows 10 / 11
====================================

Old-exe motion baseline (no entanglement from bad GLB binds)
--------------------------------------------------------------
The working gofile build (m84Azz3v) imported UAL humanoids as unique
`GeneralSkeleton` and played `%GeneralSkeleton` clips without retarget
or posture correctors. Later workspace GLBs had Y-rotated skin binds that
collapsed meshes while bone smokes still passed.

This build:
- Restores those GLBs from the recovered exe
- Imports with `PATH:Armature/Skeleton3D` → unique `GeneralSkeleton`
- Keeps chat / settings / server browser / multiplayer from the full game
- Keeps `facing_yaw_deg` so chase shows faces (not backs)

------------------------------------------------------------
Download
------------------------------------------------------------
Data-only (recommended):
  https://gofile.io/d/Psg4KukO
  SHA-256: 015de74505cd285ca94e322580c581b9c56f7c95cbad2a629dbd707e8619c6c1

Full zip:
  https://gofile.io/d/0BjW60KE
  SHA-256: 036394797dd919311aa189edc3ad2c0e0b3fcc44bed1f777d7196bec2a1ee970

Pck SHA-256: 2ab1708e4227cdee378c5c65e611e54e3fa67a57cac03d276d7c25b77935ad56
Engine SHA-256 (stock Godot 4.4.1 template):
  b493c1d53fb915f7805f360cfe42d1c3126e720dfc234a4b0f2feb99200f9a4b

If Defender quarantines: Protection history → Allow on this device
(or keep using your existing exclusion folder and replace the files).

Data-only setup:
1. Extract to C:\Games\EmpiresOfOlympus\
2. powershell -ExecutionPolicy Bypass -File .\GET-ENGINE.ps1
3. Run EmpiresOfOlympus.exe (keep next to the .pck)

Empires of Olympus — Windows 10 / 11
====================================

Posture root fix (sky-gaze / entangled townsfolk & UAL enemies)
--------------------------------------------------------------
Same bug as when the hero was the city_guard mesh: shared ual1_* clips tip
the chest/neck/head at the sky once retargeted. Fix:
- Plaza NPCs → Quaternius CC0 cast with native Idle/Walk (colored, upright)
- UAL humanoid enemies → UalPostureFix after AnimationPlayer each frame

------------------------------------------------------------
Download
------------------------------------------------------------
Data-only (recommended):
  https://gofile.io/d/w4F0tDYs
  SHA-256: 5077b4d97f265256ff655b03c21c0849cc92cebe3c55f49320a7b70c4101a2c1

Full zip:
  https://gofile.io/d/BDeCvLuO
  SHA-256: 258ffc91e8c675490d1d14785b9d53670e216de2f5e5bbf7ffadf43af7f8e0cb

Pck SHA-256: b9695a23e1771fc5e993d956d403e94343cb7f9cc161998634bcbe9247bfd990
Engine SHA-256 (stock Godot 4.4.1 template):
  b493c1d53fb915f7805f360cfe42d1c3126e720dfc234a4b0f2feb99200f9a4b

If Defender quarantines: Protection history → Allow on this device
(or keep using your existing exclusion folder and replace the files).

Data-only setup:
1. Extract to C:\Games\EmpiresOfOlympus\
2. powershell -ExecutionPolicy Bypass -File .\GET-ENGINE.ps1
3. Run EmpiresOfOlympus.exe (keep next to the .pck)

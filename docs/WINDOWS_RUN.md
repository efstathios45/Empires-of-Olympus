Empires of Olympus — Windows 10 / 11
====================================

------------------------------------------------------------
Windows Defender / "virus detected"
------------------------------------------------------------
This is a FALSE POSITIVE. The game is not malware.

Why it happens:
- The engine file is the stock Godot 4.4.1 Windows export template
  (byte-identical to Godot’s official windows_release_x86_64.exe).
- Unsigned Godot games + downloads from anonymous file hosts (gofile)
  frequently trip Defender heuristics / cloud reputation.
- Embedding the .pck inside the .exe makes it worse; we already stopped
  doing that. Defender can still flag a zip that merely CONTAINS an .exe.

Engine SHA-256 (must match):
  b493c1d53fb915f7805f360cfe42d1c3126e720dfc234a4b0f2feb99200f9a4b

How to allow a quarantined file:
1. Open Windows Security
2. Virus & threat protection → Protection history
3. Find EmpiresOfOlympus (zip or exe)
4. Actions → Allow on this device / Restore
5. Or: Manage settings → Exclusions → Add folder
     e.g. C:\Games\EmpiresOfOlympus\

Optional Microsoft false-positive report:
  https://www.microsoft.com/en-us/wdsi/filesubmission
  Product: Microsoft Defender Antivirus

There is no free packaging trick that permanently stops this for every
PC. A paid code-signing certificate (or Steam / MS Store) is the real fix.

------------------------------------------------------------
Install option A — data-only zip (best against Defender)
------------------------------------------------------------
Download:
  https://gofile.io/d/BafoP5Nd
  File: EmpiresOfOlympus-data-only.zip
  SHA-256: 3e744ff2214bba64428ea5351832f09700c4f4eac4c1674e5b70c0445048343f

1. Extract to e.g. C:\Games\EmpiresOfOlympus\
2. In that folder, run:
     powershell -ExecutionPolicy Bypass -File .\GET-ENGINE.ps1
3. Wait while it downloads the official Godot 4.4.1 export templates
   from github.com/godotengine (~1.2 GB once), extracts the engine,
   and writes EmpiresOfOlympus.exe next to the .pck
4. Run EmpiresOfOlympus.exe

Keep EmpiresOfOlympus.exe and EmpiresOfOlympus.pck together.

------------------------------------------------------------
Install option B — full zip via GitHub Release
------------------------------------------------------------
Repo is private; you must be logged into GitHub with access:

  https://github.com/efstathios45/Empires-of-Olympus/releases/tag/v0.9.1-windows

Download EmpiresOfOlympus-windows.zip, extract BOTH files into one folder,
run the .exe.

Zip SHA-256: d1f75644008962b4289a48b633e43868d45eec289354183dfa602351d970085f
Pck SHA-256: 42e1eb1a0a8b4a19b9613ecaddce130879c85316bb9c8e7765d82a944419a958

------------------------------------------------------------
"Windows protected your PC" / SmartScreen
------------------------------------------------------------
1. Double-click EmpiresOfOlympus.exe
2. More info → Run anyway
3. Or: Properties → Unblock → OK

------------------------------------------------------------
Includes
------------------------------------------------------------
- Accounts + local / cloud saves, empire map
- Enter-to-chat, server browser, Host World Online (UPnP)
- Panoply, party share, video settings, nameplates / PvP hooks
- PS1 Hoplite Chan, bone centaur, facing + plaza NPC color fixes

Friends: Esc → Host World → Copy Invite. Enter opens chat.

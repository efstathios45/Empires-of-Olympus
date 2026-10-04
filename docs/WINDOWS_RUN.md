Empires of Olympus — Windows 10 / 11
====================================

This build is a zip with two files you keep together:
  EmpiresOfOlympus.exe  (Godot engine)
  EmpiresOfOlympus.pck  (game data)

Extract both into the same folder, then run the .exe.
(The .pck is separate on purpose — see Defender note below.)

------------------------------------------------------------
Windows Defender / "virus detected" (false positive)
------------------------------------------------------------
Godot docs warn that embedding the .pck inside the .exe often
triggers antivirus false positives. This build keeps them
separate to avoid that. The game is not malware.

If Defender still quarantines the download:

1. Windows Security → Virus & threat protection → Protection history
2. Find EmpiresOfOlympus.exe (or the zip)
3. Actions → Allow on this device / Restore
4. Or add an exclusion for your game folder, e.g.
     C:\Games\EmpiresOfOlympus\

Verify the files match the hashes listed under Download before you
allow them (confirms nothing was swapped in transit).

Report as false positive (optional):
  https://www.microsoft.com/en-us/wdsi/filesubmission

------------------------------------------------------------
"Windows protected your PC" / SmartScreen
------------------------------------------------------------
1. Double-click EmpiresOfOlympus.exe
2. If SmartScreen appears, click "More info"
3. Click "Run anyway"

Also try:
  Right-click the .exe → Properties
  - If you see "Unblock", tick it → OK
  - Then run again

------------------------------------------------------------
Where to put the files
------------------------------------------------------------
Extract the zip to a normal folder, for example:
  C:\Games\EmpiresOfOlympus\

Keep EmpiresOfOlympus.exe and EmpiresOfOlympus.pck in that same folder.

------------------------------------------------------------
Download
------------------------------------------------------------
Windows build (separate .exe + .pck — fewer Defender false positives):
  https://gofile.io/d/m1FXTSr8

Archive: EmpiresOfOlympus-windows.zip
SHA-256 (zip): 8a84732a04a98c47aae1b52387617bf71b997b81c3c5381cff915c932dd4433f
MD5 (zip):     6457c2a3f11da3bd399e58dad36baa30

Contents:
  EmpiresOfOlympus.exe  SHA-256: b493c1d53fb915f7805f360cfe42d1c3126e720dfc234a4b0f2feb99200f9a4b
  EmpiresOfOlympus.pck  SHA-256: 42e1eb1a0a8b4a19b9613ecaddce130879c85316bb9c8e7765d82a944419a958

Includes:
- Accounts + local / cloud saves
- Empire map select
- Enter-to-chat (HUD log + overhead bubbles) with multiplayer RPC
- Minecraft-style server browser (LAN names + saved friend worlds)
- Host World Online (UPnP) — host-only Copy Invite; joiners never see raw IPs
- Panoply inventory, party XP/gold share, video settings
- Nameplates / cross-empire PvP arena hooks
- PS1/PSX Hoplite Chan as the hoplite class (built-in dory/aspis)
- Pose/facing: wolves/boars/harpies/minotaur chase facing forward; humanoids leave T-pose; plaza greek_* NPCs get GreekLook color
- Sandstone bone centaur enemy model
- Non-embedded PCK packaging (Defender false-positive mitigation)

How to play with friends
1. Host: enter world → Esc → name world → Host World → Copy Invite (host only).
2. Friend: Browse Servers → join by name, or Add Server with display name + invite.
3. Chat: press Enter in-world; Enter sends, Esc closes.

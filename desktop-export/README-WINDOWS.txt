Empires of Olympus — Windows 10 / 11
====================================

Extract EmpiresOfOlympus.exe and EmpiresOfOlympus.pck into the SAME folder,
then double-click the .exe. (Do not delete the .pck.)

------------------------------------------------------------
Windows Defender / "virus detected" (false positive)
------------------------------------------------------------
Embedding game data inside a Godot .exe often triggers antivirus
false positives. This build ships .exe + .pck separately for that reason.
It is not malware.

If Defender quarantines it:
  Windows Security → Protection history → Allow / Restore
Or exclude your game folder, e.g. C:\Games\EmpiresOfOlympus\

Optional false-positive report:
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
  C:\Games\EmpiresOfOlympus\

Keep both files in that folder.

------------------------------------------------------------
Download
------------------------------------------------------------
Windows build (separate .exe + .pck):
  https://gofile.io/d/m1FXTSr8

Archive: EmpiresOfOlympus-windows.zip
SHA-256: 8a84732a04a98c47aae1b52387617bf71b997b81c3c5381cff915c932dd4433f

Exe SHA-256: b493c1d53fb915f7805f360cfe42d1c3126e720dfc234a4b0f2feb99200f9a4b
Pck SHA-256: 42e1eb1a0a8b4a19b9613ecaddce130879c85316bb9c8e7765d82a944419a958

Includes accounts, empire map, Enter-to-chat, Minecraft-style server
browser, Host World Online (UPnP + host-only invites), panoply,
party share, video settings, nameplates / PvP hooks, PS1 Hoplite Chan,
bone centaur enemies, facing/NPC color fixes.

Friends: Esc → Host World → Copy Invite (host). Browse Servers / Add
Server to join. Enter opens chat in-world.

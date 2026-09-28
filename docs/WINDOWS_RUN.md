Empires of Olympus — Windows 10 / 11
====================================

This build is a single file: EmpiresOfOlympus.exe
(game data is embedded; you do not need a separate .pck)

The exe is Authenticode-signed with a **self-signed** certificate
(publisher name: "Empires of Olympus"). That proves the file was not
randomly altered after build, but Windows SmartScreen still may warn
because the cert is not from a paid Certificate Authority (DigiCert,
Sectigo, etc.). A commercially trusted publisher signature requires
buying that CA cert.

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

If Defender quarantines it: Windows Security → Protection history
→ restore / allow on this device.

------------------------------------------------------------
Where to put the file
------------------------------------------------------------
Save EmpiresOfOlympus.exe to a normal folder, for example:
  C:\Games\EmpiresOfOlympus\

No zip extract needed — this download is the .exe alone.

------------------------------------------------------------
Download
------------------------------------------------------------
Signed single-file Windows build (current):
  https://gofile.io/d/90sXU08C

File name: EmpiresOfOlympus.exe

Includes combat loot crash fix, inventory frame fit, standardized buttons,
local account saves, Enter-to-chat, a visible in-game cursor, and
bag→panoply drag-and-drop (boots, weapon, and other worn slots).
Shared/cloud multiplayer persistence is documented in docs/ACCOUNTS.md.

In-world: Enter opens player chat (see docs/CHAT.md).
Hold RMB + drag to look; open Panoply with I and drag gear onto slots.

Also: clearer Panoply tooltips, party XP/gold share, overhead chat bubbles,
and Video Settings (title + Esc).

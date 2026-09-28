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
Windows build (current — walk + natural NPC idle):
  https://gofile.io/d/PRdeetB0

File name: EmpiresOfOlympus.exe

Includes combat loot crash fix, inventory frame fit, standardized buttons,
local account saves, Enter-to-chat, a visible in-game cursor, and
bag→panoply drag-and-drop (boots, weapon, and other worn slots).
Shared/cloud multiplayer persistence is documented in docs/ACCOUNTS.md.

In-world: Enter opens player chat (see docs/CHAT.md).
Metin2-style camera: hold middle-mouse to orbit. Mouse-wheel zoom is removed
(fixed over-shoulder distance).
Hero/guard Tripo mesh: UAL idle melted legs into a Z-shape — runtime rest-core
plant keeps a standing human silhouette (arms down outside combat).
Open Panoply with I — right-click pouch items to Equip / Sell.
Nameplates show name/level in empire colours.
Multiplayer: title/Esc → Browse Servers (LAN names + saved friend worlds).
Only the host can Copy Invite; joiners never see raw IPs. Host gets each
joiner IP once in local Herald chat. See docs/PVP.md.

Also: clearer Panoply tooltips, party XP/gold share, overhead chat bubbles,
and Video Settings (title + Esc).

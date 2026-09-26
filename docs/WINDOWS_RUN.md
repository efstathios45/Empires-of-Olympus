Empires of Olympus — Windows 10 / 11
====================================

This build is a single file: EmpiresOfOlympus.exe
(game data is embedded; you do not need a separate .pck)

------------------------------------------------------------
"Windows protected your PC" / "Publisher: Unknown"
------------------------------------------------------------
That message is Windows SmartScreen. It appears for ANY new
unsigned desktop game — it is not a bug in the game itself.

This .exe is not code-signed with a paid publisher certificate
(Authenticode). Signing requires a commercial code-signing cert
from a CA (DigiCert, Sectigo, etc.). Until then, Windows will
always say the publisher is unknown.

How to run it anyway on Windows 10:

  1. Double-click EmpiresOfOlympus.exe
  2. If SmartScreen appears, click "More info"
  3. Click "Run anyway"

If Windows says the app "can't run on this PC", also try:

  A) Right-click the .exe → Properties
     - If you see an "Unblock" checkbox at the bottom, tick it → OK
     - Then run again

  B) Right-click → Properties → Compatibility
     - Tick "Run this program in compatibility mode for: Windows 8"
     - Tick "Run this program as an administrator" (optional)
     - Apply → OK

  C) Windows Security → Virus & threat protection → Protection history
     - If SmartScreen / Defender quarantined the file, restore it
       and allow it on this device

Antivirus note: single-file Godot exports are often flagged as
"unknown" the first time. That is a false positive for unsigned
indie builds. Adding an exception for the folder helps.

------------------------------------------------------------
Where to put the file
------------------------------------------------------------
Extract the zip to a normal folder, for example:
  C:\Games\EmpiresOfOlympus\

Do not run it from inside the zip, and prefer a path without
OneDrive / Downloads sync locks if Windows keeps re-blocking it.

Empires of Olympus — Windows builds
===================================

"This app cannot run on your PC" is NOT code signing.
Unsigned apps show SmartScreen ("Windows protected your PC").
"Cannot run" = wrong CPU type, OR a fake/corrupt download.

CHECK FILE SIZE FIRST
---------------------
Real .exe files are ~90–110 MB.
If yours is ~300 KB, delete it (GitHub HTML error page).

PICK YOUR BUILD (Settings → System → About → System type)
---------------------------------------------------------
x64-based processor (most PCs):
  game.exe + game.pck
  (same as game-x64.* in agent artifacts)

ARM-based processor (Snapdragon / Surface Pro X / many Copilot+ PCs):
  game-arm64.exe + game-arm64.pck

32-bit Windows (rare):
  get game-x86.exe + game-x86.pck from Cursor agent artifacts
  (too large for GitHub file limit)

Put BOTH matching files in the SAME folder, then run the .exe.
Do NOT use WinRAR. Download the files directly.

Private GitHub tip: while logged in, use each file's "Download raw file"
button — not raw.githubusercontent.com / Save-link-as.

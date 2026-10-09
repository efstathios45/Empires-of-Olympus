Empires of Olympus — macOS (Intel + Apple Silicon)
=================================================

Remote body fix + social multiplayer build (same as Windows).

macOS shows “cannot verify” / “may harm your Mac” for this build.
That is Gatekeeper. The app is **not Apple-notarized** — expected.

------------------------------------------------------------
Download
------------------------------------------------------------
https://gofile.io/d/31PpRukE
  EmpiresOfOlympus-macos.zip
  SHA-256: e528f051b9b54284e5cbb3e51685de271c86d6c88787bb087be7c3ddd8ce02ae

------------------------------------------------------------
Fix the warning (Sonoma / Sequoia)
------------------------------------------------------------

### Option A — helper script
1. Unzip
2. **Right-click** `OPEN-ON-MAC.command` → **Open** → **Open**
   (First time: do not double-click.)

### Option B — Privacy & Security → Open Anyway
1. Try to open `Empires of Olympus.app` once
2. Click **Done** (do **not** Move to Trash)
3. **System Settings → Privacy & Security** → scroll to the **bottom**
4. Click **Open Anyway** → password / Touch ID → **Open**

### Option C — Terminal
From the unzipped folder:

```sh
xattr -dr com.apple.quarantine "Empires of Olympus.app"
codesign --force --deep --sign - "Empires of Olympus.app"
open "Empires of Olympus.app"
```

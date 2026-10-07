Empires of Olympus — macOS (Intel + Apple Silicon)
=================================================

macOS shows “cannot verify” / “may harm your Mac” for this build.
That is Gatekeeper. The app is **not Apple-notarized** — expected for
an indie export without a paid Developer ID + notarization.

------------------------------------------------------------
Download
------------------------------------------------------------
https://gofile.io/d/J12j72sy
  EmpiresOfOlympus-macos.zip

(If you already have this zip, you do not need to re-download for the
Open Anyway steps below — they work on the copy you have.)

------------------------------------------------------------
Fix the warning (Sonoma / Sequoia)
------------------------------------------------------------

### Option A — helper script
1. Unzip
2. **Right-click** `OPEN-ON-MAC.command` → **Open** → **Open**
   (First time: do not double-click.)

### Option B — Privacy & Security → Open Anyway
1. Try to open `Empires of Olympus.app` once
2. In the warning, click **Done** (do **not** Move to Trash)
3. **System Settings → Privacy & Security**
4. Scroll to the **bottom**
5. Find: *“Empires of Olympus” was blocked…*
6. Click **Open Anyway** → password / Touch ID → **Open**

### Option C — Terminal
From the unzipped folder:

```sh
xattr -dr com.apple.quarantine "Empires of Olympus.app"
codesign --force --deep --sign - "Empires of Olympus.app"
open "Empires of Olympus.app"
```

If it still warns, finish with Option B (Open Anyway).

------------------------------------------------------------
What's inside
------------------------------------------------------------
- Universal binary (x86_64 + arm64), ad-hoc signed (not notarized)
- Psifidoto of the Agora + old-exe motion baseline
- Chat, settings, server browser, multiplayer

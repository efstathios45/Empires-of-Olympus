Empires of Olympus — macOS (Intel + Apple Silicon)
=================================================

Social multiplayer + peer-save build: Browse→Join, host IP/latency,
synced chat bubbles, class-correct remotes, RMB friend/whisper/trade/
party/duel, plus parties, Q/R skills, agora mosaic.

macOS shows “cannot verify” / “may harm your Mac” for this build.
That is Gatekeeper. The app is **not Apple-notarized** — expected.

------------------------------------------------------------
Download
------------------------------------------------------------
https://gofile.io/d/CflPpcoX
  EmpiresOfOlympus-macos.zip
  SHA-256: aa0baf8951e89cae2b006a08444fb755a9d72cb0d32ff37f4e8c2204eee764ff

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

------------------------------------------------------------
What's inside
------------------------------------------------------------
- Universal binary (x86_64 + arm64), ad-hoc signed (not notarized)
- Same content as the Windows social multiplayer build

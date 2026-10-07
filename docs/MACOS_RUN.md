Empires of Olympus — macOS (Intel + Apple Silicon)
=================================================

If the app says "cannot be opened" or "is damaged"
----------------------------------------------------
That is normal for an unsigned download. macOS blocks it.

**Easiest fix:** after unzipping, double-click:

  `OPEN-ON-MAC.command`

(First time: right-click it → Open → Open.)

That clears the quarantine flag and launches the game.

------------------------------------------------------------
Download
------------------------------------------------------------
https://gofile.io/d/ILUvNHLV
  EmpiresOfOlympus-macos.zip
  SHA-256: fa07246b286dbe92b1e674f4ff4e014f2fcfe8ad8724aaa2603662177ca55460

------------------------------------------------------------
Manual Terminal fix
------------------------------------------------------------
cd into the unzipped folder, then:

```sh
xattr -dr com.apple.quarantine "Empires of Olympus.app"
open "Empires of Olympus.app"
```

------------------------------------------------------------
Still blocked? (macOS Sequoia / Sonoma)
------------------------------------------------------------
1. Try once to open the app (so macOS records the block)
2. System Settings → Privacy & Security
3. Scroll down → **Open Anyway** for Empires of Olympus
4. Confirm Open

------------------------------------------------------------
What's inside
------------------------------------------------------------
- Universal binary (x86_64 + arm64), ad-hoc signed (not Apple-notarized)
- Psifidoto of the Agora + old-exe motion baseline
- Chat, settings, server browser, multiplayer

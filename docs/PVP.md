# Rival empires & shared arena

## Nameplates
Every champion shows **name**, **level**, and **empire** in empire colours:
- Sparta — crimson
- Athens — blue
- Corinth — gold

## PvP
Champions of **different empires** can damage each other (melee, skills, projectiles).
Same-empire players cannot harm one another.

On PvP death, random pieces from **worn panoply** and the **pouch** scatter as ground loot (pickups).

## Multiplayer (internet peer host)

### Host (you)
1. Sign in (or Play Guest) → enter the world alone.
2. Esc → **Host World Online**.
3. Wait for the invite (`yourip:7777`). UPnP opens the port when the router allows it.
4. **Copy Invite** and send it to your friend (Discord, etc.).

### Friend
1. Title → paste invite into **Join Friend Online** / **Guest Join Online**, **or**
2. Enter world alone → Esc → paste invite → **Join Friend**.

Port default is `7777` (UDP). If UPnP fails, forward that port on your router or use Tailscale/ZeroTier and share the VPN IP.

Solo / offline still shows your own nameplate. `NetSession` is a presence layer (mirrored avatars), not a full authoritative dedicated server — each peer keeps their own hero save.

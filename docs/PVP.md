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

## Multiplayer (Minecraft-style peer worlds)

Simple peer host for friends — no dedicated master server. LAN worlds appear by **name**; internet friends use a private invite that only the host can copy. Joiners never see raw IPs in the UI. In-game chat stays on **Enter**.

### Host (you)
1. Sign in (or Play Guest) → enter the world alone.
2. Esc → name your world → **Host World** (or open **Server Browser** → Host World).
3. Friends on your network see the world name in **Server Browser** (LAN beacon on UDP `7778`).
4. For internet friends: **Copy Invite (host)** — only you get the `ip:port`. Send it privately (Discord, etc.).
5. When someone joins, you get a one-time local Herald line with their IP (host notice only; not sent to other players).

### Friend
1. Title → **Browse Servers**, **or** Esc in-world → **Server Browser**.
2. Join a LAN world by name, **or** **Add Server** with a display name + the invite the host pasted (list shows the name only).
3. **Join Selected** — enter the world and auto-connect. Press **Enter** to chat.

Port default for gameplay is `7777` (UDP). If UPnP fails, forward that port on your router or use Tailscale/ZeroTier and share that address via Copy Invite / Add Server.

Solo / offline still shows your own nameplate. `NetSession` is a presence layer (mirrored avatars), not a full authoritative dedicated server — each peer keeps their own hero save.

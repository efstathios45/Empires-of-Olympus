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

## Multiplayer (ENet)
From the Esc rest menu:
1. Host enters the world → **Host Arena** (port `7777`)
2. Guest enters the world on another client → **Join localhost** (or edit join IP in code / future UI)
3. Remote champions appear with nameplates; fight if empires differ

Solo / offline still shows your own nameplate. `NetSession` is a presence layer (mirrored avatars), not a full authoritative dedicated server.

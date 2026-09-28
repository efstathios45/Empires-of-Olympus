# Inventory item icons

## 3D gear (weapons, shields, Corinthian helm)
Rendered from the same CC0 / in-game GLBs used on the character (`scripts/tools/render_item_icons.gd`).

| Icon | Source GLB | License |
|------|------------|---------|
| `icon_xiphos.png`, `icon_machaira.png` | `assets/props/gear/xiphos_sword.glb` | [3D Greek Weapons Set](https://opengameart.org/content/3d-greek-weapons-set) (CC0) |
| `icon_kontos.png` | `assets/props/gear/kontos_spear.glb` | same |
| `icon_aspis.png` | `assets/props/gear/aspis_shield.glb` | [Aspis hoplite shield](https://opengameart.org/content/aspis-hoplite-shield) (CC0) |
| `icon_tower_shield.png` | `assets/props/gear/tower_shield.glb` | Kenney Mini Dungeon (CC0) |
| `icon_corinthian_helm.png` | `assets/props/gear/corinthian_helmet.glb` | in-house |
| `icon_bow.png` | `assets/props/weapons/cretan_bow.glb` | in-game asset |

## Accessories, armor slots, materials
Scaled from the game’s UI icon set under `assets/ui/` (potion, sword, shield, boot, gem, etc.).

Regenerate all: `python3 scripts/tools/build_item_icons.py` (requires Godot + Xvfb).

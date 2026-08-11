extends Node
## GameState — persistent RPG state: empire, class, level, gold, inventory,
## refinement, quests, clan. Autoload. All systems read/write through here.

signal stats_changed
signal gold_changed(new_gold: int)
signal xp_changed(new_xp: int, xp_needed: int, level: int)
signal level_up(new_level: int)
signal inventory_changed
signal weapon_refined(new_level: int)
signal quest_advanced(quest_id: String, step: int)
signal clan_changed
signal potions_changed

# ── Empires ──────────────────────────────────────────────────────────────
const EMPIRES := {
	"sparta": {
		"name": "Sparta",
		"desc": "Honor through steel. The phalanx never breaks.",
		"bonus_desc": "+15% physical damage, +10% defense",
		"dmg_mult": 1.15, "def_mult": 1.10, "spell_mult": 1.0,
		"gold_mult": 1.0, "speed_mult": 1.0,
		"color": Color(0.62, 0.16, 0.16),
	},
	"athens": {
		"name": "Athens",
		"desc": "Wisdom is the sharpest blade.",
		"bonus_desc": "+20% skill power, faster mana flow",
		"dmg_mult": 1.0, "def_mult": 1.0, "spell_mult": 1.20,
		"gold_mult": 1.0, "speed_mult": 1.0, "mana_regen": 1.5,
		"color": Color(0.20, 0.38, 0.62),
	},
	"corinth": {
		"name": "Corinth",
		"desc": "Gold flows where Corinthian ships sail.",
		"bonus_desc": "+25% gold, +10% move speed",
		"dmg_mult": 1.0, "def_mult": 1.0, "spell_mult": 1.0,
		"gold_mult": 1.25, "speed_mult": 1.10,
		"color": Color(0.72, 0.58, 0.24),
	},
}

# ── Classes ──────────────────────────────────────────────────────────────
const CLASSES := {
	"hoplite": {
		"name": "Hoplite",
		"desc": "Spear and shield. A wall of bronze that strikes back.",
		"weapon": "res://assets/props/weapons/dory_spear.glb",
		"weapon_name": "Dory Spear",
		"shield": "res://assets/props/gear/aspis_shield.glb",
		"shield_name": "Aspis",
		"base_dmg": 14.0, "base_hp": 130, "base_mp": 60,
		"attack_range": 3.2, "attack_arc": 1.9,
		"skill_name": "Spear of Achilles",
		"skill_desc": "A devastating thrust that pierces all foes before you.",
		"skill_mp": 25, "skill_mult": 2.6, "skill_cd": 8.0,
		"ranged": false,
	},
	"toxotes": {
		"name": "Toxotes",
		"desc": "Cretan bow. Death arrives before the whisper of the string.",
		"weapon": "res://assets/props/weapons/cretan_bow.glb",
		"weapon_name": "Cretan Bow",
		"shield": "",
		"shield_name": "",
		"base_dmg": 11.0, "base_hp": 100, "base_mp": 80,
		"attack_range": 22.0, "attack_arc": 0.5,
		"skill_name": "Artemis Volley",
		"skill_desc": "Loose a fan of five arrows blessed by the Huntress.",
		"skill_mp": 30, "skill_mult": 1.4, "skill_cd": 9.0,
		"ranged": true, "projectile_speed": 26.0,
	},
	"magos": {
		"name": "Magos",
		"desc": "Theurgist of storm and shadow. Olympus answers his call.",
		"weapon": "res://assets/props/weapons/theurgist_staff.glb",
		"weapon_name": "Theurgist Staff",
		"shield": "",
		"shield_name": "",
		"base_dmg": 12.0, "base_hp": 90, "base_mp": 110,
		"attack_range": 18.0, "attack_arc": 0.6,
		"skill_name": "Zeus's Thunderbolt",
		"skill_desc": "Call down heaven's wrath in a burst of divine lightning.",
		"skill_mp": 35, "skill_mult": 3.0, "skill_cd": 10.0,
		"ranged": true, "projectile_speed": 20.0,
	},
}

# ── Refinement ───────────────────────────────────────────────────────────
# Metin2-style success table: chance to go from +N to +(N+1).
const REFINE_BASE_RATES := [0.95, 0.90, 0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.30]
const REFINE_MAX := 9
const REFINE_GOLD_COST := [20, 35, 55, 85, 130, 200, 320, 500, 800]
# Damage multiplier per refine level.
const REFINE_DMG_BONUS := 0.12

const SCROLLS := {
	"hephaestus": {
		"name": "Scroll of Hephaestus's Blessing",
		"desc": "Uses the base success rate. The honest hammer.",
		"price": 60,
	},
	"titan": {
		"name": "Titan's Forging Stone",
		"desc": "Overrides success to a fixed 75%. Titan-forged certainty.",
		"price": 150,
	},
	"oracle": {
		"name": "Oracle's Ritual Stone",
		"desc": "Failure cannot downgrade or destroy the weapon.",
		"price": 220,
	},
}

const SHOP_ITEMS := {
	"health_potion": {"name": "Health Potion", "desc": "Restores 60 HP.", "price": 25, "icon": "res://assets/ui/icon_potion.png", "kind": "consumable"},
	"mana_potion": {"name": "Mana Potion", "desc": "Restores 40 MP.", "price": 25, "icon": "res://assets/ui/icon_mana.png", "kind": "consumable"},
	"hephaestus": {"name": "Scroll of Hephaestus's Blessing", "desc": "Refine at base rate.", "price": 60, "icon": "res://assets/ui/icon_scroll.png", "kind": "scroll"},
	"titan": {"name": "Titan's Forging Stone", "desc": "Refine at fixed 75%.", "price": 150, "icon": "res://assets/ui/icon_gem.png", "kind": "scroll"},
	"oracle": {"name": "Oracle's Ritual Stone", "desc": "Refine with no downgrade risk.", "price": 220, "icon": "res://assets/ui/icon_scroll.png", "kind": "scroll"},
	# Gear — Kenney Mini Dungeon CC0 (aspis/xiphos) + procedural Corinthian helm.
	"aspis": {
		"name": "Aspis (Hoplon)", "desc": "Round bronze-rimmed shield. −12% damage taken.",
		"price": 180, "icon": "res://assets/ui/icon_shield.png", "kind": "gear",
		"slot": "shield", "glb": "res://assets/props/gear/aspis_shield.glb",
		"armor": 0.12,
	},
	"tower_shield": {
		"name": "Tower Aspis", "desc": "Heavy rectangular shield. −18% damage taken.",
		"price": 320, "icon": "res://assets/ui/icon_shield.png", "kind": "gear",
		"slot": "shield", "glb": "res://assets/props/gear/tower_shield.glb",
		"armor": 0.18,
	},
	"xiphos": {
		"name": "Xiphos", "desc": "Short leaf-blade sword. Replaces spear (melee).",
		"price": 240, "icon": "res://assets/ui/icon_sword.png", "kind": "gear",
		"slot": "sidearm", "glb": "res://assets/props/gear/xiphos_sword.glb",
		"dmg_bonus": 4.0,
	},
	"corinthian_helm": {
		"name": "Corinthian Helmet", "desc": "Bronze helm with crest. +25 max HP.",
		"price": 200, "icon": "res://assets/ui/icon_boot.png", "kind": "gear",
		"slot": "helmet", "glb": "res://assets/props/gear/corinthian_helmet.glb",
		"hp_bonus": 25,
	},
}

## Owned gear ids (bought from Brontes). Equipped ids per slot.
var owned_gear: Array = []
var equipped: Dictionary = {
	"shield": "aspis",   # Hoplites start with aspis; cleared for other classes on start
	"helmet": "",
	"sidearm": "",
}

# ── Runtime state ────────────────────────────────────────────────────────
var empire: String = "sparta"
var player_class: String = "hoplite"
var player_name: String = "Champion"

var level: int = 1
var xp: int = 0
var gold: int = 50
var weapon_refine: int = 0

var health_potions: int = 3
var mana_potions: int = 2
var scrolls: Dictionary = {"hephaestus": 1, "titan": 0, "oracle": 0}

# Materials looted from monsters (crafting flavor).
var materials: Dictionary = {}

# Quest chain state.
var quest_index: int = 0
var quest_kills: Dictionary = {}
var oracle_stones_destroyed: int = 0
var minotaur_slain: bool = false

# Clan.
var clan_name: String = ""
var clan_rank: String = ""

func xp_needed() -> int:
	return 60 + (level - 1) * 45 + (level - 1) * (level - 1) * 6

func reset_run() -> void:
	level = 1
	xp = 0
	gold = 50
	weapon_refine = 0
	health_potions = 3
	mana_potions = 2
	scrolls = {"hephaestus": 1, "titan": 0, "oracle": 0}
	materials = {}
	quest_index = 0
	quest_kills = {}
	oracle_stones_destroyed = 0
	minotaur_slain = false
	clan_name = ""
	clan_rank = ""
	owned_gear = []
	equipped = {"shield": "", "helmet": "", "sidearm": ""}
	# Hoplites always march with spear + aspis.
	if player_class == "hoplite":
		owned_gear.append("aspis")
		equipped["shield"] = "aspis"
	stats_changed.emit()
	inventory_changed.emit()

func empire_data() -> Dictionary:
	return EMPIRES.get(empire, EMPIRES["sparta"])

func class_data() -> Dictionary:
	return CLASSES.get(player_class, CLASSES["hoplite"])

# ── Combat math ──────────────────────────────────────────────────────────
func attack_damage() -> float:
	var cd := class_data()
	var base: float = cd["base_dmg"] * (1.0 + weapon_refine * REFINE_DMG_BONUS)
	base *= 1.0 + (level - 1) * 0.08
	if cd["ranged"] and player_class == "magos":
		base *= empire_data().get("spell_mult", 1.0)
	else:
		base *= empire_data().get("dmg_mult", 1.0)
	# Sidearm (xiphos) bonus when equipped.
	var side: String = String(equipped.get("sidearm", ""))
	if side != "" and SHOP_ITEMS.has(side):
		base += float(SHOP_ITEMS[side].get("dmg_bonus", 0.0))
	return base

func skill_damage() -> float:
	var cd := class_data()
	var d: float = attack_damage() * cd["skill_mult"] * empire_data().get("spell_mult", 1.0)
	return d

func armor_mitigation() -> float:
	var total := 0.0
	var sh: String = String(equipped.get("shield", ""))
	if sh != "" and SHOP_ITEMS.has(sh):
		total += float(SHOP_ITEMS[sh].get("armor", 0.0))
	return clampf(total, 0.0, 0.45)

func max_hp() -> int:
	var hp: int = int(class_data()["base_hp"] + (level - 1) * 14)
	var helm: String = String(equipped.get("helmet", ""))
	if helm != "" and SHOP_ITEMS.has(helm):
		hp += int(SHOP_ITEMS[helm].get("hp_bonus", 0))
	return hp

func max_mp() -> int:
	return int(class_data()["base_mp"] + (level - 1) * 8)

func damage_taken_mult() -> float:
	var m: float = 1.0 / empire_data().get("def_mult", 1.0)
	m *= (1.0 - armor_mitigation())
	return m

func move_speed_mult() -> float:
	return empire_data().get("speed_mult", 1.0)

func mana_regen_mult() -> float:
	return empire_data().get("mana_regen", 1.0)

# ── XP / gold ────────────────────────────────────────────────────────────
func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		level_up.emit(level)
	xp_changed.emit(xp, xp_needed(), level)
	stats_changed.emit()

func add_gold(amount: int) -> void:
	gold += int(amount * empire_data().get("gold_mult", 1.0))
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

# ── Inventory ────────────────────────────────────────────────────────────
func add_material(mat: String, count: int = 1) -> void:
	materials[mat] = materials.get(mat, 0) + count
	inventory_changed.emit()

func buy_item(item_id: String) -> bool:
	var item: Dictionary = SHOP_ITEMS.get(item_id, {})
	if item.is_empty():
		return false
	# Already own unique gear — refuse double-buy.
	if String(item.get("kind", "")) == "gear" and owned_gear.has(item_id):
		return false
	if not spend_gold(item["price"]):
		return false
	match item_id:
		"health_potion":
			health_potions += 1
			potions_changed.emit()
		"mana_potion":
			mana_potions += 1
			potions_changed.emit()
		"hephaestus", "titan", "oracle":
			scrolls[item_id] = scrolls.get(item_id, 0) + 1
			inventory_changed.emit()
		_:
			if String(item.get("kind", "")) == "gear":
				if not owned_gear.has(item_id):
					owned_gear.append(item_id)
				equip_gear(item_id)
				inventory_changed.emit()
				stats_changed.emit()
	return true


func equip_gear(item_id: String) -> void:
	if not SHOP_ITEMS.has(item_id):
		return
	if not owned_gear.has(item_id):
		return
	var item: Dictionary = SHOP_ITEMS[item_id]
	var slot: String = String(item.get("slot", ""))
	if slot == "":
		return
	equipped[slot] = item_id
	inventory_changed.emit()
	stats_changed.emit()


func equipped_glb(slot: String) -> String:
	var id: String = String(equipped.get(slot, ""))
	if id == "" or not SHOP_ITEMS.has(id):
		# Class default shield for hoplites.
		if slot == "shield":
			return String(class_data().get("shield", ""))
		return ""
	return String(SHOP_ITEMS[id].get("glb", ""))


func equipped_name(slot: String) -> String:
	var id: String = String(equipped.get(slot, ""))
	if id != "" and SHOP_ITEMS.has(id):
		return String(SHOP_ITEMS[id]["name"])
	if slot == "shield":
		return String(class_data().get("shield_name", "—"))
	return "—"

func use_health_potion() -> bool:
	if health_potions <= 0:
		return false
	health_potions -= 1
	potions_changed.emit()
	return true

func use_mana_potion() -> bool:
	if mana_potions <= 0:
		return false
	mana_potions -= 1
	potions_changed.emit()
	return true

# ── Refinement (the Metin2 gamble) ───────────────────────────────────────
## Returns a Dictionary: {success, destroyed, downgraded, new_level, message}
func refine_weapon(scroll_id: String) -> Dictionary:
	if weapon_refine >= REFINE_MAX:
		return {"success": false, "destroyed": false, "downgraded": false,
			"new_level": weapon_refine, "message": "Already at +%d perfection." % REFINE_MAX}
	if scrolls.get(scroll_id, 0) <= 0:
		return {"success": false, "destroyed": false, "downgraded": false,
			"new_level": weapon_refine, "message": "You lack the required scroll."}
	var cost: int = REFINE_GOLD_COST[weapon_refine]
	if gold < cost:
		return {"success": false, "destroyed": false, "downgraded": false,
			"new_level": weapon_refine, "message": "Not enough gold (%d needed)." % cost}

	scrolls[scroll_id] -= 1
	spend_gold(cost)

	var rate: float = REFINE_BASE_RATES[weapon_refine]
	var protected := false
	match scroll_id:
		"titan":
			rate = 0.75
		"oracle":
			protected = true

	var roll := randf()
	var result := {"success": false, "destroyed": false, "downgraded": false,
		"new_level": weapon_refine, "message": ""}

	if roll <= rate:
		weapon_refine += 1
		result["success"] = true
		result["new_level"] = weapon_refine
		result["message"] = "Success! Your weapon is now +%d." % weapon_refine
		AudioManager.play_sfx("refine_success")
	else:
		if protected:
			result["message"] = "The forge rejects it — but the Oracle's ward holds. No harm done."
		elif weapon_refine >= 7:
			# High-tier failure can destroy (classic Metin2 tension).
			if randf() < 0.30:
				weapon_refine = 0
				result["destroyed"] = true
				result["message"] = "The weapon SHATTERS under the hammer! The gods demand a new one."
			else:
				weapon_refine -= 1
				result["downgraded"] = true
				result["message"] = "Failure! The weapon weakens to +%d." % weapon_refine
		elif weapon_refine >= 4:
			weapon_refine -= 1
			result["downgraded"] = true
			result["message"] = "Failure! The weapon slips back to +%d." % weapon_refine
		else:
			result["message"] = "Failure! The weapon holds at +%d." % weapon_refine
		result["new_level"] = weapon_refine
		AudioManager.play_sfx("refine_fail")

	weapon_refined.emit(weapon_refine)
	inventory_changed.emit()
	return result

# ── Quests ───────────────────────────────────────────────────────────────
const QUESTS := [
	{
		"id": "wolves",
		"title": "Beasts at the Border",
		"brief": "Wolves and boars press the farms. Thin them out.",
		"kills": {"wolf_enemy": 4, "boar_enemy": 3},
		"reward_gold": 120, "reward_xp": 90,
		"turn_in": "The farms breathe again. Sparta — no, all Hellas — thanks you.",
	},
	{
		"id": "wilds",
		"title": "Silence the Wilds",
		"brief": "Satyrs raid the vineyards and harpies foul the cliffs.",
		"kills": {"satyr_enemy": 4, "harpy_enemy": 3},
		"reward_gold": 220, "reward_xp": 200,
		"turn_in": "The songs of the wild grow quieter. Well struck.",
	},
	{
		"id": "stones",
		"title": "Shatter the Curse",
		"brief": "Four cursed Metin stones poison the land. Shatter them all.",
		"stones": 4,
		"reward_gold": 350, "reward_xp": 380,
		"turn_in": "The whispers fade. But something ancient stirs below...",
	},
	{
		"id": "elites",
		"title": "Heroes of Old",
		"brief": "Centaurs and a gorgon guard the path to the Labyrinth.",
		"kills": {"centaur_enemy": 3, "gorgon_enemy": 2},
		"reward_gold": 500, "reward_xp": 600,
		"turn_in": "The way stands open. The Labyrinth awaits, champion.",
	},
	{
		"id": "minotaur",
		"title": "The Labyrinth",
		"brief": "Enter the arena and slay the Minotaur. End the curse at its root.",
		"boss": true,
		"reward_gold": 1000, "reward_xp": 1500,
		"turn_in": "The beast is felled. Olympus itself sings your name!",
	},
]

func current_quest() -> Dictionary:
	if quest_index >= QUESTS.size():
		return {}
	return QUESTS[quest_index]

func quest_progress_text() -> String:
	var q := current_quest()
	if q.is_empty():
		return "All trials complete. Legend achieved."
	var lines: Array[String] = [q["title"]]
	if q.has("kills"):
		for enemy_id in q["kills"]:
			var need: int = q["kills"][enemy_id]
			var have: int = quest_kills.get(enemy_id, 0)
			lines.append("  %s: %d/%d" % [prettify_enemy(enemy_id), mini(have, need), need])
	if q.has("stones"):
		lines.append("  Oracle Stones: %d/%d" % [
			mini(oracle_stones_destroyed, int(q["stones"])), int(q["stones"])])
	if q.has("boss"):
		lines.append("  Minotaur: %s" % ("slain" if minotaur_slain else "alive"))
	return "\n".join(lines)

func prettify_enemy(enemy_id: String) -> String:
	return enemy_id.replace("_enemy", "").capitalize()

func register_kill(enemy_id: String) -> void:
	quest_kills[enemy_id] = quest_kills.get(enemy_id, 0) + 1
	_check_quest_completion()

func register_stone_destroyed() -> void:
	oracle_stones_destroyed += 1
	_check_quest_completion()

func register_minotaur_kill() -> void:
	minotaur_slain = true
	_check_quest_completion()

func _check_quest_completion() -> void:
	var q := current_quest()
	if q.is_empty():
		return
	var done := true
	if q.has("kills"):
		for enemy_id in q["kills"]:
			if quest_kills.get(enemy_id, 0) < q["kills"][enemy_id]:
				done = false
	if q.has("stones") and oracle_stones_destroyed < q["stones"]:
		done = false
	if q.has("boss") and not minotaur_slain:
		done = false
	if done:
		quest_advanced.emit(q["id"], quest_index)

## Called by the priestess when turning in a finished quest.
func turn_in_quest() -> bool:
	var q := current_quest()
	if q.is_empty():
		return false
	add_gold(q["reward_gold"])
	add_xp(q["reward_xp"])
	quest_index += 1
	quest_kills = {}
	quest_advanced.emit(current_quest().get("id", ""), quest_index)
	stats_changed.emit()
	return true

func is_quest_objective_done() -> bool:
	var q := current_quest()
	if q.is_empty():
		return false
	if q.has("kills"):
		for enemy_id in q["kills"]:
			if quest_kills.get(enemy_id, 0) < q["kills"][enemy_id]:
				return false
	if q.has("stones") and oracle_stones_destroyed < q["stones"]:
		return false
	if q.has("boss") and not minotaur_slain:
		return false
	return true

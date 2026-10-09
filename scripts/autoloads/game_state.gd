extends Node



signal stats_changed
signal gold_changed(new_gold: int)
signal xp_changed(new_xp: int, xp_needed: int, level: int)
signal level_up(new_level: int)
signal inventory_changed
signal weapon_refined(new_level: int)
signal quest_advanced(quest_id: String, step: int)
signal clan_changed
signal potions_changed
signal mosaic_changed


const EMPIRES: = {
	"sparta": {
		"name": "Sparta", 
		"desc": "Honor through steel. The phalanx never breaks.", 
		"bonus_desc": "+15% physical damage, +10% defense", 
		"dmg_mult": 1.15, "def_mult": 1.1, "spell_mult": 1.0, 
		"gold_mult": 1.0, "speed_mult": 1.0, 
		"color": Color(0.62, 0.16, 0.16), 
	}, 
	"athens": {
		"name": "Athens", 
		"desc": "Wisdom is the sharpest blade.", 
		"bonus_desc": "+20% skill power, faster mana flow", 
		"dmg_mult": 1.0, "def_mult": 1.0, "spell_mult": 1.2, 
		"gold_mult": 1.0, "speed_mult": 1.0, "mana_regen": 1.5, 
		"color": Color(0.2, 0.38, 0.62), 
	}, 
	"corinth": {
		"name": "Corinth", 
		"desc": "Gold flows where Corinthian ships sail.", 
		"bonus_desc": "+25% gold, +10% move speed", 
		"dmg_mult": 1.0, "def_mult": 1.0, "spell_mult": 1.0, 
		"gold_mult": 1.25, "speed_mult": 1.1, 
		"color": Color(0.72, 0.58, 0.24), 
	}, 
}


const CLASSES: = {
	"hoplite": {
		"name": "Hoplite", 
		"desc": "Spear and shield. A wall of bronze that strikes back.", 
		"character": "res://assets/characters/hoplite_chan/hoplite_chan.glb", 
		"idle": "STANDIND STILL", 
		"weapon": "res://assets/props/weapons/dory_spear.glb", 
		"weapon_name": "Dory Spear", 
		"shield": "res://assets/props/gear/aspis_shield.glb", 
		"builtin_weapons": true, 
		"light_time": 0.85, "heavy_time": 0.88, 
		"credit": "PS1/PSX Hoplite Chan by Seifert — CC-BY 4.0", 
		"base_dmg": 14.0, "base_hp": 130, "base_mp": 60, 
		"attack_range": 3.2, "attack_arc": 1.9, 
		"skill_name": "Spear of Achilles",
		"skill_desc": "A devastating thrust that pierces all foes before you.",
		"skill_mp": 25, "skill_mult": 2.6, "skill_cd": 8.0,
		"skill_anim": "skill", "skill_hit_delay": 0.42,
		"skill2_name": "Phalanx Guard",
		"skill2_desc": "Brace — brief damage reduction and a shield bash.",
		"skill2_mp": 18, "skill2_mult": 1.5, "skill2_cd": 12.0,
		"skill2_anim": "skill2", "skill2_hit_delay": 0.28,
		"ranged": false,
	},
	"toxotes": {
		"name": "Toxotes",
		"desc": "Cretan bow. Death arrives before the whisper of the string.",
		"character": "res://assets/characters/kaykit_rogue/Rogue.glb",
		"idle": "Idle",
		"weapon": "res://assets/props/weapons/cretan_bow.glb",
		"weapon_name": "Cretan Bow",
		"base_dmg": 11.0, "base_hp": 100, "base_mp": 80,
		"attack_range": 22.0, "attack_arc": 0.5,
		"skill_name": "Artemis Volley",
		"skill_desc": "Loose a fan of five arrows blessed by the Huntress.",
		"skill_mp": 30, "skill_mult": 1.4, "skill_cd": 9.0,
		"skill_anim": "skill", "skill_hit_delay": 0.35,
		"skill2_name": "Apollo's Mark",
		"skill2_desc": "A piercing shot that strikes the marked foe hard.",
		"skill2_mp": 22, "skill2_mult": 2.2, "skill2_cd": 11.0,
		"skill2_anim": "skill2", "skill2_hit_delay": 0.30,
		"ranged": true, "projectile_speed": 26.0,
	},
	"magos": {
		"name": "Magos",
		"desc": "Theurgist of storm and shadow. Olympus answers his call.",
		"character": "res://assets/characters/kaykit_mage/Mage.glb",
		"idle": "Spellcasting",
		"weapon": "res://assets/props/weapons/theurgist_staff.glb",
		"weapon_name": "Theurgist Staff",
		"base_dmg": 12.0, "base_hp": 90, "base_mp": 110,
		"attack_range": 18.0, "attack_arc": 0.6,
		"skill_name": "Zeus's Thunderbolt",
		"skill_desc": "Call down heaven's wrath in a burst of divine lightning.",
		"skill_mp": 35, "skill_mult": 3.0, "skill_cd": 10.0,
		"skill_anim": "skill", "skill_hit_delay": 0.48,
		"skill2_name": "Hades' Grasp",
		"skill2_desc": "A dark nova that wounds and slows nearby foes.",
		"skill2_mp": 28, "skill2_mult": 1.8, "skill2_cd": 13.0,
		"skill2_anim": "skill2", "skill2_hit_delay": 0.40,
		"ranged": true, "projectile_speed": 20.0,
	},
}



const REFINE_BASE_RATES: = [0.95, 0.9, 0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.3]
const REFINE_MAX: = 9
const REFINE_GOLD_COST: = [20, 35, 55, 85, 130, 200, 320, 500, 800]

const REFINE_DMG_BONUS: = 0.12

const SCROLLS: = {
	"hephaestus": {
		"name": "Papyrus of Hephaestus", 
		"desc": "Tempers at the base forge rate. The honest hammer.", 
		"price": 60, 
	}, 
	"titan": {
		"name": "Titan's Ember", 
		"desc": "Locks temper chance at a fixed 75%. Titan-forged certainty.", 
		"price": 150, 
	}, 
	"oracle": {
		"name": "Pythia's Ward", 
		"desc": "Failure cannot downgrade or shatter the weapon.", 
		"price": 220, 
	}, 
}






const BAG_W: = 6
const BAG_H: = 6

const ITEM_DEFS: = {
	"health_potion": {
		"name": "Health Potion", "desc": "Restores 60 HP.", "kind": "consumable", 
		"w": 1, "h": 1, "stackable": true, "price": 25, "sell": 10, 
		"icon": "res://assets/ui/icon_potion.png", "glb": "", 
		"color": Color(0.75, 0.18, 0.22), 
	}, 
	"mana_potion": {
		"name": "Mana Potion", "desc": "Restores 40 MP.", "kind": "consumable", 
		"w": 1, "h": 1, "stackable": true, "price": 25, "sell": 10, 
		"icon": "res://assets/ui/icon_mana.png", "glb": "", 
		"color": Color(0.22, 0.35, 0.78), 
	}, 
	"hephaestus": {
		"name": "Papyrus of Hephaestus", "desc": "Tempers at the base forge rate.", 
		"kind": "scroll", "w": 1, "h": 1, "stackable": true, "price": 60, "sell": 22, 
		"icon": "res://assets/ui/icon_scroll.png", "glb": "", 
		"color": Color(0.72, 0.55, 0.25), 
	}, 
	"titan": {
		"name": "Titan's Ember", "desc": "Locks temper chance at a fixed 75%.", 
		"kind": "scroll", "w": 1, "h": 1, "stackable": true, "price": 150, "sell": 55, 
		"icon": "res://assets/ui/icon_gem.png", "glb": "", 
		"color": Color(0.55, 0.35, 0.75), 
	}, 
	"oracle": {
		"name": "Pythia's Ward", "desc": "Failure cannot downgrade or shatter the blade.", 
		"kind": "scroll", "w": 1, "h": 1, "stackable": true, "price": 220, "sell": 80, 
		"icon": "res://assets/ui/icon_scroll.png", "glb": "", 
		"color": Color(0.35, 0.65, 0.55), 
	}, 
	"mat_wolf_pelt": {
		"name": "Wolf Pelt", "desc": "Rough hide from a wild wolf.", 
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 18, 
		"icon": "res://assets/ui/items/icon_mat_wolf_pelt.png", "glb": "", 
		"color": Color(0.45, 0.38, 0.32), 
	}, 
	"mat_boar_tusk": {
		"name": "Boar Tusk", "desc": "Curved ivory from a boar.", 
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 28, 
		"icon": "res://assets/ui/items/icon_mat_boar_tusk.png", "glb": "", 
		"color": Color(0.82, 0.76, 0.62), 
	}, 
	"mat_satyr_horn": {
		"name": "Satyr Horn", "desc": "Trophy of a vineyard raider.", 
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 42, 
		"icon": "res://assets/ui/items/icon_mat_satyr_horn.png", "glb": "", 
		"color": Color(0.55, 0.42, 0.22), 
	}, 
	"mat_harpy_feather": {
		"name": "Harpy Feather", "desc": "Iridescent wing feather.", 
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 48, 
		"icon": "res://assets/ui/items/icon_mat_harpy_feather.png", "glb": "", 
		"color": Color(0.55, 0.62, 0.78), 
	}, 
	"mat_centaur_hoof": {
		"name": "Centaur Hoof", "desc": "Hardened hoof of a warrior.", 
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 85, 
		"icon": "res://assets/ui/items/icon_mat_centaur_hoof.png", "glb": "", 
		"color": Color(0.35, 0.28, 0.22), 
	}, 
	"mat_gorgon_venom": {
		"name": "Gorgon Venom", "desc": "Vial of petrifying venom.", 
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 110, 
		"icon": "res://assets/ui/icon_gem.png", "glb": "", 
		"color": Color(0.25, 0.65, 0.35), 
	}, 
	"mat_minotaur_horn": {
		"name": "Minotaur Horn", "desc": "Horn of the Labyrinth beast.", 
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 180, 
		"icon": "res://assets/ui/icon_skull.png", "glb": "", 
		"color": Color(0.55, 0.18, 0.15), 
	}, 
	"xiphos": {
		"name": "Xiphos", "desc": "Short leaf-blade sword. Vendor trash or trophy.", 
		"kind": "weapon", "w": 1, "h": 2, "stackable": false, "price": 240, "sell": 110, 
		"icon": "res://assets/ui/items/icon_xiphos.png", 
		"glb": "res://assets/props/gear/xiphos_sword.glb", 
		"color": Color(0.7, 0.72, 0.78), 
	}, 
	"bronze_knife": {
		"name": "Bronze Machaira", "desc": "Curved fighting knife.", 
		"kind": "weapon", "w": 1, "h": 2, "stackable": false, "price": 90, "sell": 45, 
		"icon": "res://assets/ui/items/icon_machaira.png", 
		"glb": "res://assets/props/gear/xiphos_sword.glb", 
		"color": Color(0.72, 0.52, 0.28), 
	}, 
	"kontos": {
		"name": "Kontos Lance", "desc": "Long cavalry spear.", 
		"kind": "weapon", "w": 1, "h": 2, "stackable": false, "price": 280, "sell": 130, 
		"icon": "res://assets/ui/items/icon_kontos.png", 
		"glb": "res://assets/props/gear/kontos_spear.glb", 
		"color": Color(0.62, 0.55, 0.4), 
	}, 
	"hunting_bow": {
		"name": "Cretan Bow", "desc": "Hunting bow recovered from the wilds.", 
		"kind": "weapon", "w": 1, "h": 2, "stackable": false, "price": 210, "sell": 95, 
		"icon": "res://assets/ui/items/icon_bow.png", 
		"glb": "res://assets/props/weapons/cretan_bow.glb", 
		"color": Color(0.45, 0.32, 0.2), 
	}, 
	"aspis": {
		"name": "Aspis (Hoplon)", "desc": "Round bronze-rimmed shield.", 
		"kind": "shield", "w": 1, "h": 1, "stackable": false, "price": 180, "sell": 85, 
		"icon": "res://assets/ui/items/icon_aspis.png", 
		"glb": "res://assets/props/gear/aspis_shield.glb", 
		"color": Color(0.75, 0.55, 0.2), 
	}, 
	"tower_shield": {
		"name": "Tower Aspis", "desc": "Heavy rectangular shield.", 
		"kind": "shield", "w": 1, "h": 1, "stackable": false, "price": 320, "sell": 150, 
		"icon": "res://assets/ui/items/icon_tower_shield.png", 
		"glb": "res://assets/props/gear/tower_shield.glb", 
		"color": Color(0.55, 0.45, 0.3), 
	}, 
	"corinthian_helm": {
		"name": "Corinthian Helmet", "desc": "Bronze helm with crest.", 
		"kind": "helmet", "w": 1, "h": 1, "stackable": false, "price": 200, "sell": 100, 
		"icon": "res://assets/ui/items/icon_corinthian_helm.png", 
		"glb": "res://assets/props/gear/corinthian_helmet.glb", 
		"color": Color(0.78, 0.58, 0.22), 
	}, 
	"leather_cuirass": {
		"name": "Leather Cuirass", "desc": "Boiled-leather torso armor.", 
		"kind": "armor", "w": 1, "h": 1, "stackable": false, "price": 160, "sell": 70, 
		"icon": "res://assets/ui/items/icon_leather_cuirass.png", "glb": "", 
		"color": Color(0.42, 0.28, 0.18), 
	}, 
	"bronze_thorax": {
		"name": "Bronze Thorax", "desc": "Muscle cuirass of polished bronze.", 
		"kind": "armor", "w": 1, "h": 1, "stackable": false, "price": 380, "sell": 175, 
		"icon": "res://assets/ui/items/icon_bronze_thorax.png", "glb": "", 
		"color": Color(0.7, 0.5, 0.22), 
		"min_level": 8, 
	}, 
	"leather_boots": {
		"name": "Leather Sandals", "desc": "Traveler's boots bound with rawhide.", 
		"kind": "boots", "w": 1, "h": 1, "stackable": false, "price": 70, "sell": 30, 
		"icon": "res://assets/ui/items/icon_leather_sandals.png", "glb": "", 
		"color": Color(0.48, 0.32, 0.18), 
		"min_level": 1, "def": 2.0, "hp": 4.0, 
	}, 
	"bronze_greaves": {
		"name": "Bronze Greaves", "desc": "Shin-guards of hammered bronze.", 
		"kind": "boots", "w": 1, "h": 1, "stackable": false, "price": 190, "sell": 85, 
		"icon": "res://assets/ui/items/icon_bronze_greaves.png", "glb": "", 
		"color": Color(0.72, 0.52, 0.24), 
		"min_level": 5, "def": 5.0, "hp": 10.0, 
	}, 
	"olive_necklace": {
		"name": "Olive Pendant", "desc": "Athena's leaf on a leather cord.", 
		"kind": "necklace", "w": 1, "h": 1, "stackable": false, "price": 120, "sell": 50, 
		"icon": "res://assets/ui/items/icon_olive_necklace.png", "glb": "", 
		"color": Color(0.55, 0.7, 0.35), 
		"min_level": 2, "hp": 12.0, "atk": 1.0, 
	}, 
	"gold_torque": {
		"name": "Gold Torque", "desc": "Heavy neck-ring of beaten gold.", 
		"kind": "necklace", "w": 1, "h": 1, "stackable": false, "price": 340, "sell": 150, 
		"icon": "res://assets/ui/items/icon_gold_torque.png", "glb": "", 
		"color": Color(0.9, 0.75, 0.28), 
		"min_level": 8, "hp": 22.0, "atk": 3.0, 
	}, 
	"bronze_earring": {
		"name": "Bronze Earring", "desc": "A soldier's simple bronze hoop.", 
		"kind": "earring", "w": 1, "h": 1, "stackable": false, "price": 55, "sell": 22, 
		"icon": "res://assets/ui/items/icon_bronze_earring.png", "glb": "", 
		"color": Color(0.7, 0.5, 0.25), 
		"min_level": 1, "atk": 1.5, 
	}, 
	"silver_earring": {
		"name": "Silver Earring", "desc": "Temple silver, cold to the touch.", 
		"kind": "earring", "w": 1, "h": 1, "stackable": false, "price": 160, "sell": 70, 
		"icon": "res://assets/ui/items/icon_silver_earring.png", "glb": "", 
		"color": Color(0.78, 0.8, 0.85), 
		"min_level": 5, "atk": 3.0, "hp": 6.0, 
	}, 
	"leather_bracelet": {
		"name": "Leather Bracelet", "desc": "Wrist-wrap for a spearman.", 
		"kind": "bracelet", "w": 1, "h": 1, "stackable": false, "price": 45, "sell": 18, 
		"icon": "res://assets/ui/items/icon_leather_bracelet.png", "glb": "", 
		"color": Color(0.5, 0.35, 0.2), 
		"min_level": 1, "def": 1.5, 
	}, 
	"bronze_bracelet": {
		"name": "Bronze Bracelet", "desc": "Coiled bronze for the sword-arm.", 
		"kind": "bracelet", "w": 1, "h": 1, "stackable": false, "price": 140, "sell": 60, 
		"icon": "res://assets/ui/items/icon_bronze_bracelet.png", "glb": "", 
		"color": Color(0.68, 0.48, 0.22), 
		"min_level": 4, "def": 3.0, "atk": 1.5, 
	}, 
	"gold_coin": {
		"name": "Drachmae", "desc": "Loose coins from a fallen foe.", 
		"kind": "gold", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 0, 
		"icon": "res://assets/ui/icon_gold.png", "glb": "", 
		"color": Color(1.0, 0.84, 0.28), 
	}, 
}


const SHOP_ITEMS: = {
	"health_potion": {"name": "Health Potion", "desc": "Restores 60 HP.", "price": 25, "icon": "res://assets/ui/icon_potion.png"},
	"mana_potion": {"name": "Mana Potion", "desc": "Restores 40 MP.", "price": 25, "icon": "res://assets/ui/icon_mana.png"},
	"hephaestus": {"name": "Papyrus of Hephaestus", "desc": "Tempers at the base forge rate.", "price": 60, "icon": "res://assets/ui/icon_scroll.png"},
	"titan": {"name": "Titan's Ember", "desc": "Locks temper chance at a fixed 75%.", "price": 150, "icon": "res://assets/ui/icon_gem.png"},
	"oracle": {"name": "Pythia's Ward", "desc": "Failure cannot downgrade or shatter the blade.", "price": 220, "icon": "res://assets/ui/icon_scroll.png"},
}

## Plaza merchant stock (npc shop_id -> item ids from ITEM_DEFS / SHOP_ITEMS).
const MERCHANT_SHOPS: = {
	"oil": {
		"title": "Hesiod's Oils",
		"quote": "Finest olive oil — and a flask for the road.",
		"items": ["health_potion", "mana_potion", "olive_necklace"],
	},
	"potter": {
		"title": "Kleon's Amphorae",
		"quote": "Clay for the living, bronze for the brave.",
		"items": ["leather_bracelet", "bronze_earring", "aspis"],
	},
	"fruit": {
		"title": "Xanthos's Stall",
		"quote": "Figs, dates, and a little luck.",
		"items": ["health_potion", "leather_boots", "bronze_knife"],
	},
}

## Material sinks — craft at the smith.
const CRAFT_RECIPES: = {
	"craft_cuirass": {
		"name": "Boiled Cuirass Kit",
		"desc": "Turn wolf pelts into a leather cuirass.",
		"result": "leather_cuirass",
		"cost_gold": 40,
		"mats": {"mat_wolf_pelt": 3},
	},
	"craft_greaves": {
		"name": "Tusk Greaves",
		"desc": "Boar ivory bound into bronze greaves.",
		"result": "bronze_greaves",
		"cost_gold": 80,
		"mats": {"mat_boar_tusk": 2, "mat_wolf_pelt": 1},
	},
	"craft_bow": {
		"name": "Feathered Bowstring",
		"desc": "Harpy feathers and satyr horn restring a Cretan bow.",
		"result": "hunting_bow",
		"cost_gold": 120,
		"mats": {"mat_harpy_feather": 2, "mat_satyr_horn": 1},
	},
	"craft_thorax": {
		"name": "Hero's Thorax",
		"desc": "Centaur hoof and gorgon venom temper a bronze thorax.",
		"result": "bronze_thorax",
		"cost_gold": 220,
		"mats": {"mat_centaur_hoof": 2, "mat_gorgon_venom": 1},
	},
	"craft_torque": {
		"name": "Labyrinth Torque",
		"desc": "A Minotaur horn melted into a gold torque.",
		"result": "gold_torque",
		"cost_gold": 300,
		"mats": {"mat_minotaur_horn": 1, "mat_centaur_hoof": 1},
	},
}


const MATERIAL_ITEM: = {
	"Wolf Pelt": "mat_wolf_pelt", 
	"Boar Tusk": "mat_boar_tusk", 
	"Satyr Horn": "mat_satyr_horn", 
	"Harpy Feather": "mat_harpy_feather", 
	"Centaur Hoof": "mat_centaur_hoof", 
	"Gorgon Venom": "mat_gorgon_venom", 
	"Minotaur Horn": "mat_minotaur_horn", 
}


const LOOT_TABLE: = [
	{"id": "bronze_knife", "weight": 22, "min_level": 1}, 
	{"id": "leather_boots", "weight": 18, "min_level": 1}, 
	{"id": "bronze_earring", "weight": 16, "min_level": 1}, 
	{"id": "leather_bracelet", "weight": 16, "min_level": 1}, 
	{"id": "leather_cuirass", "weight": 12, "min_level": 2}, 
	{"id": "olive_necklace", "weight": 10, "min_level": 2}, 
	{"id": "aspis", "weight": 12, "min_level": 3}, 
	{"id": "xiphos", "weight": 10, "min_level": 3}, 
	{"id": "hunting_bow", "weight": 9, "min_level": 3}, 
	{"id": "corinthian_helm", "weight": 9, "min_level": 4}, 
	{"id": "bronze_bracelet", "weight": 8, "min_level": 4}, 
	{"id": "bronze_greaves", "weight": 8, "min_level": 5}, 
	{"id": "silver_earring", "weight": 7, "min_level": 5}, 
	{"id": "kontos", "weight": 6, "min_level": 6}, 
	{"id": "tower_shield", "weight": 5, "min_level": 7}, 
	{"id": "bronze_thorax", "weight": 4, "min_level": 8}, 
	{"id": "gold_torque", "weight": 3, "min_level": 8}, 
]


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


var materials: Dictionary = {}


var bag: Array = []



var equipped: Dictionary = {
	"helmet": "", 
	"armor": "", 
	"weapon": "", 
	"shield": "", 
	"boots": "", 
	"necklace": "", 
	"earring": "", 
	"bracelet": "", 
}


var quest_index: int = 0

## Side quest: Psifidoto of the agora (not part of Melite's Trials chain).
## Stages: none → accepted → complete
var mosaic_quest_stage: String = "none"
var mosaic_tiles: PackedByteArray = PackedByteArray()
var mosaic_rewarded: bool = false

const MOSAIC_QUEST: = {
	"id": "agora_mosaic",
	"title": "Psifidoto of the Agora",
	"brief": "Old Myrrine remembers when the square's pebble mosaic shone for every feast. Restore the circular Psifidoto by hand — each tessera set like the old craftsmen — then seal it forever for Athena's court. On a hosted world, friends see the same sealed art.",
	"reward_gold": 650,
	"reward_xp": 480,
}
var quest_kills: Dictionary = {}
var omphaloi_destroyed: int = 0
var minotaur_slain: bool = false

## 0 = not started, then steps advance; 99 = finished.
var tutorial_step: int = 0

## Host-authoritative shared world (peer-to-peer save). Personal gear stays per account.
var world_host_account: String = ""
var world_host_name: String = ""
## peer_id(str) -> {name, empire, level, account, class}
var world_peers: Dictionary = {}

var clan_name: String = ""
var clan_rank: String = ""

func _ready() -> void :
	_seed_starter_bag()

func xp_needed() -> int:
	return 60 + (level - 1) * 45 + (level - 1) * (level - 1) * 6

func reset_run() -> void :
	level = 1
	xp = 0
	gold = 50
	weapon_refine = 0
	health_potions = 0
	mana_potions = 0
	scrolls = {"hephaestus": 0, "titan": 0, "oracle": 0}
	materials = {}
	bag.clear()
	equipped = {
		"helmet": "", "armor": "", "weapon": "", "shield": "", 
		"boots": "", "necklace": "", "earring": "", "bracelet": "", 
	}
	quest_index = 0
	quest_kills = {}
	omphaloi_destroyed = 0
	minotaur_slain = false
	tutorial_step = 0
	world_host_account = ""
	world_host_name = ""
	world_peers.clear()
	mosaic_quest_stage = "none"
	mosaic_tiles = PackedByteArray()
	mosaic_rewarded = false
	clan_name = ""
	clan_rank = ""
	_seed_starter_bag()
	stats_changed.emit()
	inventory_changed.emit()
	potions_changed.emit()
	mosaic_changed.emit()



func to_save_dict() -> Dictionary:
	var bag_copy: Array = []
	for e in bag:
		if typeof(e) == TYPE_DICTIONARY:
			bag_copy.append({
				"id": String(e.get("id", "")), 
				"count": int(e.get("count", 1)), 
				"x": int(e.get("x", 0)), 
				"y": int(e.get("y", 0)), 
			})
	var eq: = {}
	for k in equipped:
		eq[String(k)] = String(equipped[k])
	var qk: = {}
	for k in quest_kills:
		qk[String(k)] = int(quest_kills[k])
	return {
		"v": 2,
		"empire": empire,
		"player_class": player_class,
		"player_name": player_name,
		"level": level,
		"xp": xp,
		"gold": gold,
		"weapon_refine": weapon_refine,
		"bag": bag_copy,
		"equipped": eq,
		"quest_index": quest_index,
		"quest_kills": qk,
		"omphaloi_destroyed": omphaloi_destroyed,
		"minotaur_slain": minotaur_slain,
		"tutorial_step": tutorial_step,
		"world_host_account": world_host_account,
		"world_host_name": world_host_name,
		"world_peers": world_peers.duplicate(true),
		"clan_name": clan_name,
		"clan_rank": clan_rank,
		"mosaic_quest_stage": mosaic_quest_stage,
		"mosaic_tiles": MosaicArt.tiles_to_array(mosaic_tiles),
		"mosaic_rewarded": mosaic_rewarded,
	}



func apply_save_dict(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	empire = String(data.get("empire", empire))
	player_class = String(data.get("player_class", player_class))
	player_name = String(data.get("player_name", player_name))
	level = maxi(1, int(data.get("level", 1)))
	xp = maxi(0, int(data.get("xp", 0)))
	gold = maxi(0, int(data.get("gold", 0)))
	weapon_refine = maxi(0, int(data.get("weapon_refine", 0)))
	bag.clear()
	var raw_bag = data.get("bag", [])
	if typeof(raw_bag) == TYPE_ARRAY:
		for e in raw_bag:
			if typeof(e) != TYPE_DICTIONARY:
				continue
			var id: = String(e.get("id", ""))
			if id == "":
				continue
			bag.append({
				"id": id, 
				"count": maxi(1, int(e.get("count", 1))), 
				"x": int(e.get("x", 0)), 
				"y": int(e.get("y", 0)), 
			})
	equipped = {
		"helmet": "", "armor": "", "weapon": "", "shield": "", 
		"boots": "", "necklace": "", "earring": "", "bracelet": "", 
	}
	var raw_eq = data.get("equipped", {})
	if typeof(raw_eq) == TYPE_DICTIONARY:
		for k in equipped.keys():
			if raw_eq.has(k):
				equipped[k] = String(raw_eq[k])
	quest_index = maxi(0, int(data.get("quest_index", 0)))
	quest_kills = {}
	var raw_qk = data.get("quest_kills", {})
	if typeof(raw_qk) == TYPE_DICTIONARY:
		for k in raw_qk:
			quest_kills[String(k)] = int(raw_qk[k])
	omphaloi_destroyed = maxi(0, int(data.get("omphaloi_destroyed", 0)))
	minotaur_slain = bool(data.get("minotaur_slain", false))
	tutorial_step = maxi(0, int(data.get("tutorial_step", 0)))
	world_host_account = String(data.get("world_host_account", ""))
	world_host_name = String(data.get("world_host_name", ""))
	world_peers = {}
	var raw_peers = data.get("world_peers", {})
	if typeof(raw_peers) == TYPE_DICTIONARY:
		for k in raw_peers:
			var row = raw_peers[k]
			if typeof(row) == TYPE_DICTIONARY:
				world_peers[String(k)] = row.duplicate(true)
	clan_name = String(data.get("clan_name", ""))
	clan_rank = String(data.get("clan_rank", ""))
	mosaic_quest_stage = String(data.get("mosaic_quest_stage", "none"))
	if mosaic_quest_stage != "accepted" and mosaic_quest_stage != "complete":
		mosaic_quest_stage = "none"
	mosaic_tiles = MosaicArt.tiles_from_array(data.get("mosaic_tiles", []))
	mosaic_rewarded = bool(data.get("mosaic_rewarded", false))
	_resync_derived_counts()
	stats_changed.emit()
	inventory_changed.emit()
	potions_changed.emit()
	var q: = current_quest()
	quest_advanced.emit(String(q.get("id", "")), quest_index)
	clan_changed.emit()
	mosaic_changed.emit()
	return true


func _seed_starter_bag() -> void :
	bag.clear()
	try_add_to_bag("health_potion", 3)
	try_add_to_bag("mana_potion", 2)
	try_add_to_bag("hephaestus", 1)

	try_add_to_bag("leather_boots", 1)
	_resync_derived_counts()

func empire_data() -> Dictionary:
	return EMPIRES.get(empire, EMPIRES["sparta"])

func class_data() -> Dictionary:
	return CLASSES.get(player_class, CLASSES["hoplite"])


func attack_damage() -> float:
	var cd: = class_data()
	var base: float = cd["base_dmg"] * (1.0 + weapon_refine * REFINE_DMG_BONUS)
	base *= 1.0 + (level - 1) * 0.08
	if cd["ranged"] and player_class == "magos":
		base *= empire_data().get("spell_mult", 1.0)
	else:
		base *= empire_data().get("dmg_mult", 1.0)
	base += _equip_stat("atk")
	return base

func skill_damage() -> float:
	var cd: = class_data()
	var d: float = attack_damage() * float(cd.get("skill_mult", 2.0)) * empire_data().get("spell_mult", 1.0)
	return d


func skill2_damage() -> float:
	var cd: = class_data()
	var d: float = attack_damage() * float(cd.get("skill2_mult", 1.5)) * empire_data().get("spell_mult", 1.0)
	return d


func ensure_world_host_identity() -> void:
	if world_host_account != "" and world_host_name != "":
		return
	var acct: = ""
	if AccountSystem != null:
		acct = String(AccountSystem.username)
	if acct.strip_edges() == "":
		acct = "host"
	world_host_account = acct
	world_host_name = String(player_name) if String(player_name) != "" else "Champion"
	var pid: = 1
	if PartyShare != null:
		pid = PartyShare.local_peer_id()
	add_world_peer(pid, {
		"name": world_host_name,
		"empire": empire,
		"level": level,
		"account": world_host_account,
		"class": player_class,
	})


func to_world_sync_dict() -> Dictionary:
	## Shared host world — guests adopt this; personal bag/equip/level stay local.
	var qk: = {}
	for k in quest_kills:
		qk[String(k)] = int(quest_kills[k])
	return {
		"v": 2,
		"world_host_account": world_host_account,
		"world_host_name": world_host_name,
		"world_peers": world_peers.duplicate(true),
		"quest_index": quest_index,
		"quest_kills": qk,
		"omphaloi_destroyed": omphaloi_destroyed,
		"minotaur_slain": minotaur_slain,
		"tutorial_step": tutorial_step,
		"mosaic_quest_stage": mosaic_quest_stage,
		"mosaic_tiles": MosaicArt.tiles_to_array(mosaic_tiles),
		"mosaic_rewarded": mosaic_rewarded,
	}


func apply_world_sync_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	world_host_account = String(data.get("world_host_account", world_host_account))
	world_host_name = String(data.get("world_host_name", world_host_name))
	world_peers = {}
	var raw_peers = data.get("world_peers", {})
	if typeof(raw_peers) == TYPE_DICTIONARY:
		for k in raw_peers:
			var row = raw_peers[k]
			if typeof(row) == TYPE_DICTIONARY:
				world_peers[String(k)] = row.duplicate(true)
	quest_index = maxi(0, int(data.get("quest_index", quest_index)))
	quest_kills = {}
	var raw_qk = data.get("quest_kills", {})
	if typeof(raw_qk) == TYPE_DICTIONARY:
		for k in raw_qk:
			quest_kills[String(k)] = int(raw_qk[k])
	omphaloi_destroyed = maxi(0, int(data.get("omphaloi_destroyed", omphaloi_destroyed)))
	minotaur_slain = bool(data.get("minotaur_slain", minotaur_slain))
	## Guests keep their own tutorial if further along; otherwise adopt host.
	tutorial_step = maxi(tutorial_step, int(data.get("tutorial_step", tutorial_step)))
	mosaic_quest_stage = String(data.get("mosaic_quest_stage", mosaic_quest_stage))
	if mosaic_quest_stage != "accepted" and mosaic_quest_stage != "complete":
		mosaic_quest_stage = "none"
	mosaic_tiles = MosaicArt.tiles_from_array(data.get("mosaic_tiles", []))
	mosaic_rewarded = bool(data.get("mosaic_rewarded", mosaic_rewarded))
	quest_advanced.emit(current_quest().get("id", ""), quest_index)
	mosaic_changed.emit()
	stats_changed.emit()


## Partial world mutation (guest → host → broadcast). Host state is canonical.
func apply_world_patch(patch: Dictionary) -> void:
	if patch.is_empty():
		return
	var touched_quest: = false
	var touched_mosaic: = false
	if patch.has("quest_index"):
		quest_index = maxi(0, int(patch["quest_index"]))
		touched_quest = true
	if patch.has("quest_kills"):
		quest_kills = {}
		var raw_qk = patch["quest_kills"]
		if typeof(raw_qk) == TYPE_DICTIONARY:
			for k in raw_qk:
				quest_kills[String(k)] = int(raw_qk[k])
		touched_quest = true
	if patch.has("omphaloi_destroyed"):
		omphaloi_destroyed = maxi(0, int(patch["omphaloi_destroyed"]))
		touched_quest = true
	if patch.has("minotaur_slain"):
		minotaur_slain = bool(patch["minotaur_slain"])
		touched_quest = true
	if patch.has("mosaic_quest_stage"):
		mosaic_quest_stage = String(patch["mosaic_quest_stage"])
		if mosaic_quest_stage != "accepted" and mosaic_quest_stage != "complete":
			mosaic_quest_stage = "none"
		touched_mosaic = true
	if patch.has("mosaic_tiles"):
		mosaic_tiles = MosaicArt.tiles_from_array(patch["mosaic_tiles"])
		touched_mosaic = true
	if patch.has("mosaic_rewarded"):
		mosaic_rewarded = bool(patch["mosaic_rewarded"])
		touched_mosaic = true
	if touched_quest:
		quest_advanced.emit(current_quest().get("id", ""), quest_index)
	if touched_mosaic:
		ensure_mosaic_tiles()
		mosaic_changed.emit()
	if touched_quest or touched_mosaic:
		stats_changed.emit()
	if AccountSystem != null and AccountSystem.is_logged_in():
		AccountSystem.save_game()


func add_world_peer(peer_id: int, data: Dictionary) -> void:
	world_peers[str(peer_id)] = {
		"name": String(data.get("name", "Champion")),
		"empire": String(data.get("empire", "sparta")),
		"level": int(data.get("level", 1)),
		"account": String(data.get("account", "")),
		"class": String(data.get("class", data.get("player_class", "hoplite"))),
	}


func remove_world_peer(peer_id: int) -> void:
	world_peers.erase(str(peer_id))


func craft_recipe(recipe_id: String) -> Dictionary:
	var rec = CRAFT_RECIPES.get(recipe_id, {})
	if typeof(rec) != TYPE_DICTIONARY or rec.is_empty():
		return {"ok": false, "reason": "unknown"}
	var gold_cost: = int(rec.get("cost_gold", 0))
	if gold < gold_cost:
		return {"ok": false, "reason": "gold"}
	var mats: Dictionary = rec.get("mats", {})
	for mat_id in mats:
		var need: = int(mats[mat_id])
		var have: = _count_item(String(mat_id))
		if have < need:
			return {"ok": false, "reason": "mats", "missing": String(mat_id)}
	for mat_id in mats:
		_consume_item(String(mat_id), int(mats[mat_id]))
	gold -= gold_cost
	gold_changed.emit(gold)
	var result_id: = String(rec.get("result", ""))
	if result_id != "":
		try_add_to_bag(result_id, 1)
	inventory_changed.emit()
	stats_changed.emit()
	return {"ok": true, "result": result_id, "name": String(rec.get("name", result_id))}


func _count_item(item_id: String) -> int:
	var n: = 0
	for e in bag:
		if typeof(e) == TYPE_DICTIONARY and String(e.get("id", "")) == item_id:
			n += int(e.get("count", 1))
	return n


func _consume_item(item_id: String, amount: int) -> void:
	var left: = amount
	var i: = 0
	while i < bag.size() and left > 0:
		var e = bag[i]
		if typeof(e) != TYPE_DICTIONARY or String(e.get("id", "")) != item_id:
			i += 1
			continue
		var c: = int(e.get("count", 1))
		if c <= left:
			left -= c
			bag.remove_at(i)
			continue
		e["count"] = c - left
		left = 0
		i += 1
	_resync_derived_counts()


func advance_tutorial(step: int) -> void:
	if step <= tutorial_step:
		return
	tutorial_step = step
	quest_advanced.emit("tutorial", tutorial_step)


func buy_merchant_item(shop_id: String, item_id: String) -> bool:
	var shop = MERCHANT_SHOPS.get(shop_id, {})
	if typeof(shop) != TYPE_DICTIONARY:
		return false
	var items: Array = shop.get("items", [])
	if not items.has(item_id):
		return false
	if SHOP_ITEMS.has(item_id):
		return buy_item(item_id)
	var def: = item_def(item_id)
	var price: = int(def.get("price", 0))
	if price <= 0 or not can_fit(item_id):
		return false
	if not spend_gold(price):
		return false
	if not try_add_to_bag(item_id):
		add_gold(price)
		return false
	return true

func max_hp() -> int:
	return int(class_data()["base_hp"] + (level - 1) * 14 + _equip_stat("hp"))

func max_mp() -> int:
	return int(class_data()["base_mp"] + (level - 1) * 8)

func damage_taken_mult() -> float:
	var def_bonus: float = 1.0 + _equip_stat("def") * 0.01
	return 1.0 / (empire_data().get("def_mult", 1.0) * def_bonus)

func move_speed_mult() -> float:
	return empire_data().get("speed_mult", 1.0)

func mana_regen_mult() -> float:
	return empire_data().get("mana_regen", 1.0)


func add_xp(amount: int) -> void :
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		level_up.emit(level)
	xp_changed.emit(xp, xp_needed(), level)
	stats_changed.emit()

func add_gold(amount: int) -> void :
	gold += int(amount * empire_data().get("gold_mult", 1.0))
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true



func item_def(item_id: String) -> Dictionary:
	var d: Dictionary = ITEM_DEFS.get(item_id, {})
	if d.is_empty():
		return {"id": item_id, "name": item_id, "kind": "junk", "w": 1, "h": 1, 
			"stackable": true, "price": 0, "sell": 5, "icon": "", "glb": "", 
			"color": Color(0.7, 0.7, 0.7)}
	var out: = d.duplicate()
	out["id"] = item_id
	return out


func item_name(item_id: String) -> String:
	return String(item_def(item_id).get("name", item_id))


func item_cells(item_id: String) -> Vector2i:
	var d: = item_def(item_id)
	return Vector2i(int(d.get("w", 1)), int(d.get("h", 1)))


func item_sell_price(item_id: String) -> int:
	return int(item_def(item_id).get("sell", 5))


func bag_count(item_id: String) -> int:
	var n: = 0
	for e in bag:
		if String(e.get("id", "")) == item_id:
			n += int(e.get("count", 1))
	return n


func _resync_derived_counts() -> void :
	health_potions = bag_count("health_potion")
	mana_potions = bag_count("mana_potion")
	for sid in SCROLLS.keys():
		scrolls[sid] = bag_count(String(sid))
	materials.clear()
	for e in bag:
		var id: String = String(e.get("id", ""))
		var def: = item_def(id)
		if String(def.get("kind", "")) == "material":
			materials[String(def.get("name", id))] = int(e.get("count", 1))


func _occupancy() -> Array:

	var grid: Array = []
	for _y in BAG_H:
		var row: Array = []
		row.resize(BAG_W)
		row.fill(-1)
		grid.append(row)
	for i in bag.size():
		var e: Dictionary = bag[i]
		var cells: = item_cells(String(e.get("id", "")))
		var ox: int = int(e.get("x", 0))
		var oy: int = int(e.get("y", 0))
		for dy in cells.y:
			for dx in cells.x:
				var cx: int = ox + dx
				var cy: int = oy + dy
				if cx >= 0 and cy >= 0 and cx < BAG_W and cy < BAG_H:
					grid[cy][cx] = i
	return grid


func can_fit(item_id: String, count: int = 1) -> bool:
	var def: = item_def(item_id)
	if bool(def.get("stackable", false)):
		for e in bag:
			if String(e.get("id", "")) == item_id:
				return true
	return _find_free_origin(item_id) != Vector2i(-1, -1) or count <= 0


func _find_free_origin(item_id: String) -> Vector2i:
	var cells: = item_cells(item_id)
	var grid: = _occupancy()
	for y in BAG_H - cells.y + 1:
		for x in BAG_W - cells.x + 1:
			var ok: = true
			for dy in cells.y:
				for dx in cells.x:
					if int(grid[y + dy][x + dx]) != -1:
						ok = false
						break
				if not ok:
					break
			if ok:
				return Vector2i(x, y)
	return Vector2i(-1, -1)



func try_add_to_bag(item_id: String, count: int = 1) -> bool:
	if count <= 0:
		return true
	if not ITEM_DEFS.has(item_id) and not item_id.begins_with("mat_"):

		pass
	var def: = item_def(item_id)
	if bool(def.get("stackable", false)):
		for e in bag:
			if String(e.get("id", "")) == item_id:
				e["count"] = int(e.get("count", 1)) + count
				_resync_derived_counts()
				inventory_changed.emit()
				if item_id == "health_potion" or item_id == "mana_potion":
					potions_changed.emit()
				return true
	var origin: = _find_free_origin(item_id)
	if origin.x < 0:
		return false
	bag.append({"id": item_id, "count": count, "x": origin.x, "y": origin.y})
	_resync_derived_counts()
	inventory_changed.emit()
	if item_id == "health_potion" or item_id == "mana_potion":
		potions_changed.emit()
	return true


func remove_bag_entry(index: int, amount: int = -1) -> bool:
	if index < 0 or index >= bag.size():
		return false
	var e: Dictionary = bag[index]
	var have: int = int(e.get("count", 1))
	if amount < 0 or amount >= have:
		bag.remove_at(index)
	else:
		e["count"] = have - amount
	_resync_derived_counts()
	inventory_changed.emit()
	potions_changed.emit()
	return true


func remove_one_from_bag(item_id: String) -> bool:
	for i in bag.size():
		if String(bag[i].get("id", "")) == item_id:
			return remove_bag_entry(i, 1)
	return false



func sell_bag_entry(index: int, amount: int = 1) -> int:
	if index < 0 or index >= bag.size():
		return 0
	var e: Dictionary = bag[index]
	var id: String = String(e.get("id", ""))
	var have: int = int(e.get("count", 1))
	var n: int = clampi(amount, 1, have)
	var gained: int = item_sell_price(id) * n
	remove_bag_entry(index, n)

	gold += gained
	gold_changed.emit(gold)
	return gained





func item_tooltip_text(item_id: String) -> String:
	if item_id == "":
		return ""
	var def: = item_def(item_id)
	var lines: PackedStringArray = []
	lines.append(str(def.get("name", item_id)))
	var desc: = str(def.get("desc", "")).strip_edges()
	if desc != "":
		lines.append(desc)
	var kind: = str(def.get("kind", ""))
	var slot: = slot_for_kind(kind)
	if slot != "":
		lines.append("Slot: %s" % slot.capitalize())
	var bonus: = _equip_bonus_for(item_id)
	var bits: PackedStringArray = []
	if float(bonus.get("atk", 0.0)) != 0.0:
		bits.append("ATK +%d" % int(bonus["atk"]))
	if float(bonus.get("def", 0.0)) != 0.0:
		bits.append("DEF +%d" % int(bonus["def"]))
	if float(bonus.get("hp", 0.0)) != 0.0:
		bits.append("HP +%d" % int(bonus["hp"]))
	if not bits.is_empty():
		lines.append(" · ".join(bits))
	var min_lv: = int(def.get("min_level", 0))
	if min_lv > 1:
		lines.append("Requires level %d" % min_lv)
	var sell: = item_sell_price(item_id)
	if sell > 0:
		lines.append("Sell: %d δ" % sell)
	return "\n".join(lines)


func slot_for_kind(kind: String) -> String:
	match kind:
		"helmet":
			return "helmet"
		"armor":
			return "armor"
		"weapon":
			return "weapon"
		"shield":
			return "shield"
		"boots":
			return "boots"
		"necklace":
			return "necklace"
		"earring":
			return "earring"
		"bracelet":
			return "bracelet"
		_:
			return ""


func _equip_bonus_for(item_id: String) -> Dictionary:
	var def: = item_def(item_id)
	var atk: = float(def.get("atk", 0))
	var defense: = float(def.get("def", 0))
	var hp: = float(def.get("hp", 0))
	if atk == 0.0 and defense == 0.0 and hp == 0.0:
		match String(def.get("kind", "")):
			"weapon":
				atk = 4.0 + float(def.get("sell", 40)) * 0.02
			"shield":
				defense = 6.0
			"helmet":
				defense = 3.0
				hp = 8.0
			"armor":
				defense = 5.0
				hp = 16.0
			"boots":
				defense = 2.0
				hp = 6.0
			"necklace":
				hp = 10.0
				atk = 1.0
			"earring":
				atk = 2.0
			"bracelet":
				defense = 2.0
	return {"atk": atk, "def": defense, "hp": hp}


func _equip_stat(stat: String) -> float:
	var total: = 0.0
	for slot in equipped.keys():
		var id: String = String(equipped[slot])
		if id == "":
			continue
		total += float(_equip_bonus_for(id).get(stat, 0.0))
	return total



func equip_from_bag(index: int) -> bool:
	if index < 0 or index >= bag.size():
		return false
	var e: Dictionary = bag[index]
	var id: String = String(e.get("id", ""))
	var def: = item_def(id)
	var slot: String = slot_for_kind(String(def.get("kind", "")))
	if slot == "":
		return false
	return equip_from_bag_to_slot(index, slot)



func equip_from_bag_to_slot(index: int, slot: String) -> bool:
	if index < 0 or index >= bag.size():
		return false
	if not equipped.has(slot):
		return false
	var e: Dictionary = bag[index]
	var id: String = String(e.get("id", ""))
	var def: = item_def(id)
	var want: String = slot_for_kind(String(def.get("kind", "")))
	if want == "" or want != slot:
		return false
	var previous: String = String(equipped.get(slot, ""))
	if not remove_bag_entry(index, 1):
		return false
	if previous != "":
		if not try_add_to_bag(previous, 1):
			try_add_to_bag(id, 1)
			return false
	equipped[slot] = id
	inventory_changed.emit()
	stats_changed.emit()
	return true


func unequip_slot(slot: String) -> bool:
	if not equipped.has(slot):
		return false
	var id: String = String(equipped[slot])
	if id == "":
		return false
	if not try_add_to_bag(id, 1):
		return false
	equipped[slot] = ""
	inventory_changed.emit()
	stats_changed.emit()
	return true


func equipped_name(slot: String) -> String:
	var id: String = String(equipped.get(slot, ""))
	if id == "":
		return "—"
	return item_name(id)



func equipped_glb(slot: String) -> String:
	var key: = slot
	if key == "sidearm":
		key = "weapon"
	var id: String = String(equipped.get(key, ""))
	if id == "":
		return ""
	return String(item_def(id).get("glb", ""))



func item_icon_path(item_id: String) -> String:
	if item_id == "gold_coin" or item_id.begins_with("gold_"):
		return "res://assets/ui/icon_gold.png"
	var def: = item_def(item_id)
	var icon: = String(def.get("icon", ""))
	if icon != "" and ResourceLoader.exists(icon):
		return icon
	match String(def.get("kind", "")):
		"weapon":
			return "res://assets/ui/icon_sword.png"
		"shield":
			return "res://assets/ui/icon_shield.png"
		"helmet", "armor", "boots":
			return "res://assets/ui/icon_boot.png"
		"necklace", "earring":
			return "res://assets/ui/icon_gem.png"
		"bracelet":
			return "res://assets/ui/icon_anvil.png"
		"consumable":
			return "res://assets/ui/icon_potion.png"
		"scroll":
			return "res://assets/ui/icon_scroll.png"
		"material":
			return "res://assets/ui/icon_skull.png"
		"gold":
			return "res://assets/ui/icon_gold.png"
		_:
			return "res://assets/ui/icon_laurel.png"


func add_material(mat: String, count: int = 1) -> void :
	var item_id: String = String(MATERIAL_ITEM.get(mat, ""))
	if item_id == "":

		item_id = "mat_" + mat.to_lower().replace(" ", "_")
	if not try_add_to_bag(item_id, count):

		materials[mat] = materials.get(mat, 0) + count
		inventory_changed.emit()


func material_item_id(mat_name: String) -> String:
	return String(MATERIAL_ITEM.get(mat_name, ""))


func buy_item(item_id: String) -> bool:
	var item: Dictionary = SHOP_ITEMS.get(item_id, {})
	if item.is_empty():
		return false
	if not can_fit(item_id):
		return false
	if not spend_gold(item["price"]):
		return false
	if not try_add_to_bag(item_id):

		add_gold(item["price"])
		return false
	return true


func use_health_potion() -> bool:
	if not remove_one_from_bag("health_potion"):
		return false
	potions_changed.emit()
	return true


func use_mana_potion() -> bool:
	if not remove_one_from_bag("mana_potion"):
		return false
	potions_changed.emit()
	return true



func roll_loot_drop(chance: float = 0.28, boss: bool = false, enemy_level: int = 1) -> String:
	var c: = chance * (1.55 if boss else 1.0)
	if randf() > clampf(c, 0.0, 0.92):
		return ""
	var lvl: = maxi(enemy_level, 1)
	var pool: Array = []
	var total: = 0.0
	for row in LOOT_TABLE:
		var need: = int(row.get("min_level", 1))

		if need > lvl + (2 if boss else 0):
			continue

		var w: = float(row.get("weight", 1))
		var dist: = absf(float(need) - float(lvl))
		w *= clampf(1.35 - dist * 0.18, 0.35, 1.35)
		pool.append({"id": row.get("id", ""), "weight": w})
		total += w
	if total <= 0.0 or pool.is_empty():
		return ""
	var pick: = randf() * total
	var acc: = 0.0
	for row in pool:
		acc += float(row.get("weight", 1))
		if pick <= acc:
			return String(row.get("id", ""))
	return String(pool.back().get("id", ""))




func take_pvp_death_drops(max_equipped: int = 2, max_bag: int = 3) -> Array:
	var drops: Array = []

	var worn: Array = []
	for slot in equipped.keys():
		var id: = String(equipped[slot])
		if id != "":
			worn.append(slot)
	worn.shuffle()
	var eq_n: = mini(max_equipped, worn.size())

	if worn.size() > 0:
		eq_n = maxi(1, eq_n)
	eq_n = mini(eq_n, worn.size())
	for i in eq_n:
		var slot: String = String(worn[i])
		var id: = String(equipped[slot])
		if id == "":
			continue
		equipped[slot] = ""
		drops.append(id)

	var bag_idx: Array = []
	for i in range(bag.size()):
		bag_idx.append(i)
	bag_idx.shuffle()
	var bag_taken: = 0
	var remove_plan: Array = []
	for i in bag_idx:
		if bag_taken >= max_bag:
			break
		var e: Dictionary = bag[i]
		var id: = String(e.get("id", ""))
		if id == "" or id == "gold_coin":
			continue
		var kind: = String(item_def(id).get("kind", ""))
		if kind in ["consumable", "scroll"] and randf() < 0.45:
			continue
		remove_plan.append({"index": i, "id": id})
		bag_taken += 1

	remove_plan.sort_custom( func(a, b): return int(a["index"]) > int(b["index"]))
	for row in remove_plan:
		var idx: = int(row["index"])
		var id: = String(row["id"])
		if idx < 0 or idx >= bag.size():
			continue
		if String(bag[idx].get("id", "")) != id:
			continue
		var count: = int(bag[idx].get("count", 1))
		if count > 1:
			bag[idx]["count"] = count - 1
		else:
			bag.remove_at(idx)
		drops.append(id)
	if not drops.is_empty():
		inventory_changed.emit()
		stats_changed.emit()
	return drops



func roll_gold_drop(base_min: int, base_max: int, enemy_level: int = 1) -> int:
	var lvl: = maxi(enemy_level, 1)
	var lo: = maxi(1, int(float(base_min) * (1.0 + float(lvl) * 0.1)))
	var hi: = maxi(lo, int(float(base_max) * (1.0 + float(lvl) * 0.12)))
	return randi_range(lo, hi)



func refine_weapon(scroll_id: String) -> Dictionary:
	if weapon_refine >= REFINE_MAX:
		return {"success": false, "destroyed": false, "downgraded": false, 
			"new_level": weapon_refine, "message": "Already at +%d perfection." % REFINE_MAX}
	if bag_count(scroll_id) <= 0:
		return {"success": false, "destroyed": false, "downgraded": false, 
			"new_level": weapon_refine, "message": "You lack the required scroll."}
	var cost: int = REFINE_GOLD_COST[weapon_refine]
	if gold < cost:
		return {"success": false, "destroyed": false, "downgraded": false, 
			"new_level": weapon_refine, "message": "Not enough gold (%d needed)." % cost}

	if not remove_one_from_bag(scroll_id):
		return {"success": false, "destroyed": false, "downgraded": false, 
			"new_level": weapon_refine, "message": "You lack the required scroll."}
	spend_gold(cost)

	var rate: float = REFINE_BASE_RATES[weapon_refine]
	var protected: = false
	match scroll_id:
		"titan":
			rate = 0.75
		"oracle":
			protected = true

	var roll: = randf()
	var result: = {"success": false, "destroyed": false, "downgraded": false, 
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

			if randf() < 0.3:
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


const QUESTS: = [
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
		"brief": "Three cursed Omphaloi poison the land. Destroy them all.", 
		"stones": 3, 
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
	{
		"id": "aftermath",
		"title": "Ashes of the Labyrinth",
		"brief": "The curse broke — but satyrs and harpies still stalk the wilds. Cull them for Melite.",
		"kills": {"satyr_enemy": 5, "harpy_enemy": 4},
		"reward_gold": 700, "reward_xp": 900,
		"turn_in": "The wilds quiet. Yet centaur banners gather to the south…",
	},
	{
		"id": "champions",
		"title": "Trial of Champions",
		"brief": "Prove the Labyrinth did not make you soft — fell centaur elites and a gorgon.",
		"kills": {"centaur_enemy": 4, "gorgon_enemy": 2},
		"reward_gold": 900, "reward_xp": 1200,
		"turn_in": "Athena's court names you Champion of the Agora. Walk free — refine, craft, and host friends.",
	},
]

func current_quest() -> Dictionary:
	if quest_index >= QUESTS.size():
		return {}
	return QUESTS[quest_index]

func quest_progress_text() -> String:
	var q: = current_quest()
	if q.is_empty():
		return "All trials complete. Legend achieved."
	var lines: Array[String] = [q["title"]]
	if q.has("kills"):
		for enemy_id in q["kills"]:
			var need: int = q["kills"][enemy_id]
			var have: int = quest_kills.get(enemy_id, 0)
			lines.append("  %s: %d/%d" % [prettify_enemy(enemy_id), mini(have, need), need])
	if q.has("stones"):
		lines.append("  Omphaloi: %d/3" % mini(omphaloi_destroyed, 3))
	if q.has("boss"):
		lines.append("  Minotaur: %s" % ("slain" if minotaur_slain else "alive"))
	return "\n".join(lines)

func prettify_enemy(enemy_id: String) -> String:
	return enemy_id.replace("_enemy", "").capitalize()

func register_kill(enemy_id: String) -> void :
	quest_kills[enemy_id] = quest_kills.get(enemy_id, 0) + 1
	_check_quest_completion()

func register_stone_destroyed() -> void :
	omphaloi_destroyed += 1
	_check_quest_completion()

func register_minotaur_kill() -> void :
	minotaur_slain = true
	_check_quest_completion()

func _check_quest_completion() -> void :
	var q: = current_quest()
	if q.is_empty():
		return
	var done: = true
	if q.has("kills"):
		for enemy_id in q["kills"]:
			if quest_kills.get(enemy_id, 0) < q["kills"][enemy_id]:
				done = false
	if q.has("stones") and omphaloi_destroyed < q["stones"]:
		done = false
	if q.has("boss") and not minotaur_slain:
		done = false
	if done:
		quest_advanced.emit(q["id"], quest_index)


func turn_in_quest() -> bool:
	var q: = current_quest()
	if q.is_empty():
		return false
	## Personal turn-in rewards; quest index advances on the host world.
	add_gold(q["reward_gold"])
	add_xp(q["reward_xp"])
	var next_idx: = quest_index + 1
	var patch: = {
		"quest_index": next_idx,
		"quest_kills": {},
	}
	if NetSession != null and NetSession.is_online():
		NetSession.propose_world_patch(patch)
	else:
		apply_world_patch(patch)
	return true

func is_quest_objective_done() -> bool:
	var q: = current_quest()
	if q.is_empty():
		return false
	if q.has("kills"):
		for enemy_id in q["kills"]:
			if quest_kills.get(enemy_id, 0) < q["kills"][enemy_id]:
				return false
	if q.has("stones") and omphaloi_destroyed < q["stones"]:
		return false
	if q.has("boss") and not minotaur_slain:
		return false
	return true


func ensure_mosaic_tiles() -> void:
	mosaic_tiles = MosaicArt.ensure_tiles(mosaic_tiles)


func accept_mosaic_quest() -> bool:
	if mosaic_quest_stage != "none":
		return false
	ensure_mosaic_tiles()
	var patch: = {
		"mosaic_quest_stage": "accepted",
		"mosaic_tiles": MosaicArt.tiles_to_array(mosaic_tiles),
	}
	## Guest → host applies + broadcasts; host save is superior.
	if NetSession != null and NetSession.is_online():
		NetSession.propose_world_patch(patch)
	else:
		apply_world_patch(patch)
	return true


func has_mosaic_art() -> bool:
	ensure_mosaic_tiles()
	return MosaicArt.painted_count(mosaic_tiles) > 0


func mosaic_progress_text() -> String:
	if mosaic_quest_stage == "none":
		return ""
	ensure_mosaic_tiles()
	var painted: = MosaicArt.painted_count(mosaic_tiles)
	if mosaic_quest_stage == "complete":
		return "%s — sealed forever (%d tesserae)" % [MOSAIC_QUEST["title"], painted]
	if painted <= 0:
		return "%s\nSpeak with the agora women to begin." % MOSAIC_QUEST["title"]
	return "%s — %d tesserae laid (need %d to seal)\nSaved — return anytime to continue." % [
		MOSAIC_QUEST["title"], painted, MosaicArt.SEAL_MIN,
	]


func save_mosaic_progress(tiles: PackedByteArray = PackedByteArray()) -> bool:
	## Persist draft without sealing. Artwork stays on the shared plaza (host save).
	if mosaic_quest_stage == "none":
		return false
	if tiles.size() > 0:
		mosaic_tiles = MosaicArt.ensure_tiles(tiles)
	else:
		ensure_mosaic_tiles()
	var patch: = {
		"mosaic_quest_stage": mosaic_quest_stage,
		"mosaic_tiles": MosaicArt.tiles_to_array(mosaic_tiles),
		"mosaic_rewarded": mosaic_rewarded,
	}
	if NetSession != null and NetSession.is_online():
		NetSession.propose_world_patch(patch)
	else:
		apply_world_patch(patch)
	return true


func seal_mosaic_artwork() -> Dictionary:
	## Returns {ok, first_reward, gold, xp}. Requires some painted tiles.
	ensure_mosaic_tiles()
	if mosaic_quest_stage == "none":
		return {"ok": false, "reason": "not_accepted"}
	if MosaicArt.painted_count(mosaic_tiles) < MosaicArt.SEAL_MIN:
		return {"ok": false, "reason": "too_sparse"}
	var first: = not mosaic_rewarded
	var gold_amt: = 0
	var xp_amt: = 0
	## Personal reward stays with the sealer; plaza seal syncs via host.
	if first:
		gold_amt = int(MOSAIC_QUEST["reward_gold"])
		xp_amt = int(MOSAIC_QUEST["reward_xp"])
		add_gold(gold_amt)
		add_xp(xp_amt)
	var patch: = {
		"mosaic_quest_stage": "complete",
		"mosaic_tiles": MosaicArt.tiles_to_array(mosaic_tiles),
		"mosaic_rewarded": true,
	}
	if NetSession != null and NetSession.is_online():
		NetSession.propose_world_patch(patch)
	else:
		apply_world_patch(patch)
	return {"ok": true, "first_reward": first, "gold": gold_amt, "xp": xp_amt}


func mosaic_floor_texture() -> Texture2D:
	ensure_mosaic_tiles()
	if not has_mosaic_art():
		return null
	return MosaicArt.build_texture(mosaic_tiles, 10)

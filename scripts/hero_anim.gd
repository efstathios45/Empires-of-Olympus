class_name HeroAnim
extends RefCounted
## Maps gameplay actions (idle, walk, attack, …) onto a class's real clips.
## Toxotes and Magos stay on the shared KayKit/UAL library. The hoplite uses
## the PS1/PSX Hoplite Chan clips that ship inside her GLB.

const PROFILES := {
	"kaykit": {
		"idle": "ual1_Idle",
		"walk": "ual1_Walk",
		"sprint": "ual1_Sprint",
		"jump": "ual1_Jump",
		"block": "ual2_Sword_Block",
		"roll": "ual1_Roll",
		"hit": "ual1_Hit_Chest",
		"death": "ual1_Death01",
		"skill": "ual1_Sword_Attack",
		"heavy": "ual2_Sword_Heavy_A",
		"light": "ual1_Sword_Attack",
		"combo": ["ual2_Sword_Light_A", "ual2_Sword_Light_B", "ual2_Sword_Light_C"],
		"light_time": 0.5,
		"heavy_time": 0.85,
		"ranged_time": 0.55,
		"oneshot": [],
	},
	# Clip names are the model's, including the author's spellings
	# (STANDIND, ATACK, UNEQUIPEP, EQUIPED).
	"hoplite_chan": {
		"idle": "STANDIND STILL",
		"walk": "WALK 1",
		"sprint": "RUN EQUIPPED",
		"jump": "STANDIND STILL",
		# No block, flinch, or death clip on this rig. Holding the
		# spear-and-shield idle keeps her out of the bind pose.
		"block": "STANDIND STILL",
		"roll": "RUN 1 LEAN LEFT EQUIPPED",
		"hit": "STANDIND STILL",
		"death": "STANDIND STILL",
		"skill": "DORY ATACK",
		"heavy": "XIPHOS side SLASH",
		"light": "DORY ATACK",
		"combo": ["DORY ATACK", "XIPHOS side SLASH", "DORY ATACK"],
		"light_time": 0.85,
		"heavy_time": 0.88,
		"ranged_time": 0.85,
		"oneshot": ["DORY ATACK", "XIPHOS side SLASH", "XIPHOS UNSHEATH", "BOW FIRING"],
	},
}


static func clip(profile_id: String, action: String) -> String:
	var profile: Dictionary = PROFILES.get(profile_id, PROFILES["kaykit"])
	return str(profile.get(action, ""))


static func combo(profile_id: String) -> PackedStringArray:
	var profile: Dictionary = PROFILES.get(profile_id, PROFILES["kaykit"])
	var raw: Array = profile.get("combo", [])
	var out := PackedStringArray()
	for item in raw:
		out.append(str(item))
	return out


static func duration(profile_id: String, kind: String) -> float:
	var profile: Dictionary = PROFILES.get(profile_id, PROFILES["kaykit"])
	return float(profile.get(kind, 0.5))


## Locomotion loops. Attacks on the hoplite rig are one-shot even though
## their names don't contain the word "attack" (the file says "ATACK").
static func apply_loops(anim_player: AnimationPlayer, profile_id: String) -> void:
	if anim_player == null:
		return
	var profile: Dictionary = PROFILES.get(profile_id, PROFILES["kaykit"])
	var oneshot: Array = profile.get("oneshot", [])
	if oneshot.is_empty():
		ModelUtils.set_animation_loops(anim_player)
		return
	var oneshot_names := {}
	for entry in oneshot:
		oneshot_names[str(entry)] = true
	for anim_name in anim_player.get_animation_list():
		var anim := anim_player.get_animation(anim_name)
		if anim == null:
			continue
		var bare := anim_name
		if "/" in anim_name:
			bare = anim_name.get_slice("/", 1)
		if oneshot_names.has(anim_name) or oneshot_names.has(bare):
			anim.loop_mode = Animation.LOOP_NONE
		else:
			anim.loop_mode = Animation.LOOP_LINEAR

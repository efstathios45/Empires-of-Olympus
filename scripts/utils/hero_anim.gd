extends RefCounted
## Resolve gameplay clip aliases to whatever the loaded hero mesh actually has.
## Prefer KayKit Adventurers names; fall back to legacy UAL clip names.


## Prefer UAL hoplite clips first (Greek hero); KayKit names kept as fallback only.
const ALIASES := {
	"idle": ["ual1_Idle", "ual1_Sword_Idle", "Idle", "Unarmed_Idle"],
	"walk": ["ual1_Walk", "Walking_A", "Walking_B", "Walking_C"],
	"sprint": ["ual1_Sprint", "Running_A", "Running_B"],
	"jump": ["ual1_Jump", "Jump_Start", "Jump_Full_Short", "Jump_Full_Long"],
	"dodge": ["ual1_Roll", "Dodge_Forward", "Dodge_Left"],
	"hit": ["ual1_Hit_Chest", "Hit_A", "Hit_B"],
	"death": ["ual1_Death01", "Death_A", "Death_B"],
	"block": ["ual2_Sword_Block", "Blocking", "Block"],
	"block_hit": ["ual1_Hit_Chest", "Block_Hit", "Hit_A"],
	"attack_1": ["ual2_Sword_Light_A", "ual1_Sword_Attack", "1H_Melee_Attack_Chop"],
	"attack_2": ["ual2_Sword_Light_B", "ual1_Sword_Attack", "1H_Melee_Attack_Slice_Diagonal"],
	"attack_3": ["ual2_Sword_Light_C", "ual1_Sword_Attack", "1H_Melee_Attack_Stab"],
	"attack_heavy": ["ual2_Sword_Heavy_A", "ual1_Sword_Attack", "2H_Melee_Attack_Chop"],
	"attack_ranged": ["ual1_Sword_Attack", "1H_Ranged_Shoot", "Spellcast_Shoot"],
}


static func resolve(anim: AnimationPlayer, alias: String) -> String:
	if anim == null:
		return ""
	var opts: Array = ALIASES.get(alias, [alias])
	for name in opts:
		var clip := String(name)
		if anim.has_animation(clip):
			return clip
	## Last resort: exact alias if present.
	if anim.has_animation(alias):
		return alias
	return ""


static func play(anim: AnimationPlayer, alias: String, loop_ok: bool = true) -> String:
	var clip := resolve(anim, alias)
	if clip == "" or anim == null:
		return ""
	if loop_ok and anim.current_animation == clip and anim.is_playing():
		return clip
	anim.play(clip)
	return clip


static func is_kaykit(model: Node3D) -> bool:
	if model == null:
		return false
	var nlow := String(model.name).to_lower()
	if "knight" in nlow or "barbarian" in nlow or "rogue" in nlow or "mage" in nlow:
		return true
	for n in model.find_children("*", "Skeleton3D", true, false):
		var skel := n as Skeleton3D
		if skel != null and skel.find_bone("handslot.r") >= 0:
			return true
	return false

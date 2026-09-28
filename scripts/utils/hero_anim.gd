extends RefCounted
## Resolve gameplay clip aliases to whatever the loaded hero mesh actually has.
## Prefer KayKit Adventurers names; fall back to legacy UAL clip names.


const ALIASES := {
	"idle": ["Idle", "Unarmed_Idle", "ual1_Idle", "ual1_Sword_Idle"],
	"walk": ["Walking_A", "Walking_B", "Walking_C", "ual1_Walk"],
	"sprint": ["Running_A", "Running_B", "ual1_Sprint"],
	"jump": ["Jump_Start", "Jump_Full_Short", "Jump_Full_Long", "ual1_Jump"],
	"dodge": ["Dodge_Forward", "Dodge_Left", "ual1_Roll"],
	"hit": ["Hit_A", "Hit_B", "ual1_Hit_Chest"],
	"death": ["Death_A", "Death_B", "ual1_Death01"],
	"block": ["Blocking", "Block", "ual2_Sword_Block"],
	"block_hit": ["Block_Hit", "Hit_A", "ual1_Hit_Chest"],
	"attack_1": ["1H_Melee_Attack_Chop", "1H_Melee_Attack_Slice_Diagonal", "ual2_Sword_Light_A", "ual1_Sword_Attack"],
	"attack_2": ["1H_Melee_Attack_Slice_Diagonal", "1H_Melee_Attack_Slice_Horizontal", "ual2_Sword_Light_B", "ual1_Sword_Attack"],
	"attack_3": ["1H_Melee_Attack_Stab", "1H_Melee_Attack_Chop", "ual2_Sword_Light_C", "ual1_Sword_Attack"],
	"attack_heavy": ["2H_Melee_Attack_Chop", "1H_Melee_Attack_Chop", "ual2_Sword_Heavy_A", "ual1_Sword_Attack"],
	"attack_ranged": ["1H_Ranged_Shoot", "Spellcast_Shoot", "ual1_Sword_Attack"],
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

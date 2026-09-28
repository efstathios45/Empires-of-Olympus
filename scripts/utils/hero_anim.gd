extends RefCounted
## Resolve gameplay clip aliases to whatever the loaded hero mesh actually has.
## Prefer Quaternius Ultimate Modular clips; fall back to KayKit / legacy UAL.


## Quaternius first (real human proportions + authored Walk/Sword_Slash/Idle_Sword).
const ALIASES := {
	## Idle_Neutral looks straight ahead; Idle_Sword is the raised-guard (block) pose.
	"idle": ["Idle_Neutral", "Idle", "Idle_Sword", "ual1_Idle", "ual1_Sword_Idle", "Unarmed_Idle"],
	"walk": ["Walk", "ual1_Walk", "Walking_A", "Walking_B", "Walking_C"],
	"sprint": ["Run", "ual1_Sprint", "Running_A", "Running_B"],
	"jump": ["Jump_Start", "Jump_Full_Short", "ual1_Jump", "Roll"],
	"dodge": ["Roll", "ual1_Roll", "Dodge_Forward", "Dodge_Left"],
	"hit": ["HitRecieve", "HitRecieve_2", "ual1_Hit_Chest", "Hit_A", "Hit_B"],
	"death": ["Death", "ual1_Death01", "Death_A", "Death_B"],
	## No dedicated Block clip in Quaternius — Idle_Sword is the raised-guard stance.
	"block": ["Idle_Sword", "Blocking", "Block", "ual2_Sword_Block"],
	"block_hit": ["HitRecieve", "HitRecieve_2", "Block_Hit", "ual1_Hit_Chest", "Hit_A"],
	"attack_1": ["Sword_Slash", "Punch_Right", "ual2_Sword_Light_A", "ual1_Sword_Attack", "1H_Melee_Attack_Chop"],
	"attack_2": ["Sword_Slash", "Punch_Left", "ual2_Sword_Light_B", "ual1_Sword_Attack", "1H_Melee_Attack_Slice_Diagonal"],
	"attack_3": ["Kick_Right", "Sword_Slash", "ual2_Sword_Light_C", "ual1_Sword_Attack", "1H_Melee_Attack_Stab"],
	"attack_heavy": ["Sword_Slash", "Kick_Left", "ual2_Sword_Heavy_A", "ual1_Sword_Attack", "2H_Melee_Attack_Chop"],
	"attack_ranged": ["Gun_Shoot", "Idle_Gun_Shoot", "ual1_Sword_Attack", "1H_Ranged_Shoot", "Spellcast_Shoot"],
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


static func is_quaternius(model: Node3D) -> bool:
	if model == null:
		return false
	var nlow := String(model.name).to_lower()
	if "quaternius" in nlow or "hero_king" in nlow or "guard_adventurer" in nlow \
			or "smith_worker" in nlow or "merchant_farmer" in nlow \
			or "oracle_witch" in nlow or "woman_medieval" in nlow \
			or "woman_formal" in nlow or "woman_worker" in nlow \
			or "citizen_casual" in nlow or "guard_soldier" in nlow:
		return true
	for n in model.find_children("*", "Skeleton3D", true, false):
		var skel := n as Skeleton3D
		## Quaternius Ultimate Modular: Wrist.R + Foot.L, no UAL LeftUpperArm.
		if skel != null and skel.find_bone("Wrist.R") >= 0 and skel.find_bone("Foot.L") >= 0 \
				and skel.find_bone("LeftUpperArm") < 0:
			return true
	return false

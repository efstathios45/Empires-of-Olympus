extends RefCounted
## Per-gear grip tuning for the player paperdoll (helmet, shield, weapons).
## WeaponGrip stays provisioned; this layer only supplies overrides and head attach.

const WeaponGrip = preload("res://scripts/weapon_grip.gd")

# Position is metres in bone space. Rotation is Euler degrees on the grip holder.
# Prefer LeftLowerArm for shields (WeaponGrip default) — LeftHand + wild eulers
# twisted the forearm and made the champion look broken.
const GRIP_BY_GLB := {
	## Hellenic / Quaternius — Wrist.L / Wrist.R (tuned on hero_king).
	"res://assets/props/gear/aspis_shield.glb": {
		"bone": "Wrist.L",
		"position": Vector3(0.0, 0.04, 0.08),
		"rotation_deg": Vector3(-90.0, 0.0, 90.0),
		"scale": 1.0,
	},
	"res://assets/props/gear/tower_shield.glb": {
		"bone": "Wrist.L",
		"position": Vector3(0.0, 0.04, 0.08),
		"rotation_deg": Vector3(-90.0, 0.0, 90.0),
		"scale": 1.08,
	},
	## KayKit Adventurers — sockets handslot.l / Round_Shield / 1H_Sword.
	"res://assets/props/kaykit/shield_round.glb": {
		"bone": "Round_Shield",
		"position": Vector3.ZERO,
		"rotation_deg": Vector3.ZERO,
		"scale": 1.0,
		"skip_normalize": true,
	},
	"res://assets/props/kaykit/shield_round_color.glb": {
		"bone": "Round_Shield",
		"position": Vector3.ZERO,
		"rotation_deg": Vector3.ZERO,
		"scale": 1.0,
		"skip_normalize": true,
	},
	"res://assets/props/kaykit/shield_square.glb": {
		"bone": "Rectangle_Shield",
		"position": Vector3.ZERO,
		"rotation_deg": Vector3.ZERO,
		"scale": 1.0,
		"skip_normalize": true,
	},
	"res://assets/props/kaykit/sword_1handed.glb": {
		"bone": "1H_Sword",
		"position": Vector3.ZERO,
		"rotation_deg": Vector3.ZERO,
		"scale": 1.0,
		"skip_normalize": true,
	},
	"res://assets/props/gear/xiphos_sword.glb": {
		"bone": "Wrist.R",
		"position": Vector3(0.0, 0.05, 0.0),
		"rotation_deg": Vector3(0.0, 0.0, -90.0),
		"scale": 0.98,
	},
	"res://assets/props/gear/kontos_spear.glb": {
		"bone": "Wrist.R",
		"position": Vector3(0.0, 0.05, 0.0),
		"rotation_deg": Vector3(0.0, 0.0, -90.0),
		"scale": 1.12,
	},
	"res://assets/props/weapons/dory_spear.glb": {
		"bone": "Wrist.R",
		"position": Vector3(0.0, 0.05, 0.0),
		"rotation_deg": Vector3(0.0, 0.0, -90.0),
		"scale": 1.05,
	},
	"res://assets/props/weapons/cretan_bow.glb": {
		"position": Vector3(-0.06, 0.02, 0.0),
		"rotation_deg": Vector3(-68.0, 6.0, -92.0),
		"scale": 1.05,
	},
	"res://assets/props/weapons/theurgist_staff.glb": {
		"position": Vector3(0.0, -0.18, 0.0),
		"rotation_deg": Vector3(-90.0, -90.0, 0.0),
		"scale": 1.08,
	},
}

# Helmets are NOT run through WeaponGrip.normalize (melee/shield frames twist them).
const HELMET_BY_GLB := {
	"res://assets/props/gear/corinthian_helmet.glb": {
		"position": Vector3(0.0, 0.035, 0.01),
		"rotation_deg": Vector3(0.0, 0.0, 0.0),
		"target_extent": 0.26,
	},
}


static func grip_for_glb(glb_path: String) -> Dictionary:
	var g: Dictionary = GRIP_BY_GLB.get(glb_path, {})
	return g.duplicate(true)


static func weapon_class_for(glb_path: String) -> String:
	var lower := glb_path.to_lower()
	if lower.find("shield") >= 0 or lower.find("aspis") >= 0:
		return "shield"
	if lower.find("bow") >= 0:
		return "gun"
	return "melee"


static func attach_weapon(model: Node3D, glb_path: String) -> Node3D:
	if glb_path == "" or not ResourceLoader.exists(glb_path):
		return null
	var wclass := weapon_class_for(glb_path)
	return WeaponGrip.attach(model, glb_path, wclass, grip_for_glb(glb_path))


static func attach_shield(model: Node3D, glb_path: String) -> Node3D:
	if glb_path == "" or not ResourceLoader.exists(glb_path):
		return null
	return WeaponGrip.attach(model, glb_path, "shield", grip_for_glb(glb_path))


static func attach_helmet(model: Node3D, glb_path: String) -> Node3D:
	if glb_path == "" or not ResourceLoader.exists(glb_path):
		return null
	var skel: Skeleton3D = _find_skeleton(model)
	if skel == null:
		return null
	var cfg: Dictionary = HELMET_BY_GLB.get(glb_path, {
		"position": Vector3(0.0, 0.04, 0.01),
		"rotation_deg": Vector3.ZERO,
		"target_extent": 0.26,
	})
	var att := BoneAttachment3D.new()
	att.name = "HelmetBone"
	att.bone_name = "Head"
	if skel.find_bone("Head") < 0 and skel.find_bone("head") >= 0:
		att.bone_name = "head"
	skel.add_child(att)
	var holder := Node3D.new()
	holder.name = "HelmetMount"
	att.add_child(holder)
	var inst: Node3D = load(glb_path).instantiate()
	holder.add_child(inst)
	ModelUtils.scale_to_max_extent(inst, float(cfg.get("target_extent", 0.26)))
	inst.rotation_degrees = cfg.get("rotation_deg", Vector3.ZERO)
	inst.position = cfg.get("position", Vector3.ZERO)
	return att


static func _find_skeleton(model: Node3D) -> Skeleton3D:
	for node in model.find_children("*", "Skeleton3D", true, false):
		return node as Skeleton3D
	return null

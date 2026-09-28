extends RefCounted
## Per-gear grip tuning for the player paperdoll (helmet, shield, weapons).
## WeaponGrip stays provisioned; this layer only supplies overrides and head attach.

const WeaponGrip = preload("res://scripts/weapon_grip.gd")

# Position is metres in bone space. Rotation is Euler degrees on the grip holder.
# Prefer LeftLowerArm for shields (WeaponGrip default) — LeftHand + wild eulers
# twisted the forearm and made the champion look broken.
const GRIP_BY_GLB := {
	## Achilles hang-rest: mesh palms ~0.40 m along Wrist +Z (bones sit inboard).
	## Aspis on Wrist.L at the palm; center_prop recenters after Tesana low-end grip.
	"res://assets/props/gear/aspis_shield.glb": {
		"bone": "Wrist.L",
		"position": Vector3(0.08, -0.02, 0.40),
		"rotation_deg": Vector3(0.0, 0.0, 0.0),
		"scale": 1.0,
		"center_prop": true,
	},
	"res://assets/props/gear/tower_shield.glb": {
		"bone": "Wrist.L",
		"position": Vector3(0.08, -0.02, 0.40),
		"rotation_deg": Vector3(0.0, 0.0, 0.0),
		"scale": 1.08,
		"center_prop": true,
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
	## Palm/outer hand in Wrist.R hang-rest ≈ (−0.08, −0.02, 0.40).
	## Bone +Y is world-down — slightly negative Y lifts the mount into the fist.
	## Rx(90) maps aim +Z → bone −Y (tip up). spear_hold_along_aim: Tesana melee
	## grip is the butt; dory is held mid-shaft (~0.34 m toward tip).
	"res://assets/props/gear/xiphos_sword.glb": {
		"bone": "Wrist.R",
		"position": Vector3(-0.08, -0.02, 0.40),
		"rotation_deg": Vector3(90.0, 0.0, 0.0),
		"scale": 0.98,
	},
	"res://assets/props/gear/kontos_spear.glb": {
		"bone": "Wrist.R",
		"position": Vector3(-0.08, -0.02, 0.40),
		"rotation_deg": Vector3(90.0, 0.0, 0.0),
		"scale": 1.12,
		"spear_hold_along_aim": 0.34,
	},
	"res://assets/props/weapons/dory_spear.glb": {
		"bone": "Wrist.R",
		"position": Vector3(-0.08, -0.02, 0.40),
		"rotation_deg": Vector3(90.0, 0.0, 0.0),
		"scale": 1.05,
		"spear_hold_along_aim": 0.34,
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
	var grip := grip_for_glb(glb_path)
	var wclass := weapon_class_for(glb_path)
	var att := WeaponGrip.attach(model, glb_path, wclass, grip)
	if att == null:
		return null
	_apply_hold_tweaks(att, grip)
	return att


static func attach_shield(model: Node3D, glb_path: String) -> Node3D:
	if glb_path == "" or not ResourceLoader.exists(glb_path):
		return null
	var grip := grip_for_glb(glb_path)
	var att := WeaponGrip.attach(model, glb_path, "shield", grip)
	if att == null:
		return null
	_apply_hold_tweaks(att, grip)
	return att


## Post-attach fixes that WeaponGrip's sword-centric normalize cannot express.
static func _apply_hold_tweaks(attachment: Node3D, grip: Dictionary) -> void:
	var held := attachment.get_node_or_null("Grip/Normalized") as Node3D
	if held == null:
		held = attachment.find_child("Normalized", true, false) as Node3D
	if held == null:
		return
	var along := float(grip.get("spear_hold_along_aim", 0.0))
	if along != 0.0:
		## Move mesh so a point `along` metres toward the tip lands at the palm.
		held.position.z -= along
	if bool(grip.get("center_prop", false)):
		var aabb := _held_aabb(held)
		held.position -= aabb.position + aabb.size * 0.5


static func _held_aabb(root: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := Transform3D.IDENTITY
		var cur: Node = mi
		while cur != null and cur != root:
			if cur is Node3D:
				xf = (cur as Node3D).transform * xf
			cur = cur.get_parent()
		var local: AABB = xf * mi.get_aabb()
		if first:
			aabb = local
			first = false
		else:
			aabb = aabb.merge(local)
	return aabb


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

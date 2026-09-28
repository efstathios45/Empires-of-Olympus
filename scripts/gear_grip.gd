extends RefCounted
## Per-gear grip tuning for the player paperdoll (helmet, shield, weapons).
## WeaponGrip stays provisioned; this layer only supplies overrides and head attach.

const WeaponGrip = preload("res://scripts/weapon_grip.gd")

# Euler degrees in bone space; positions in metres (pre character-scale compensation).
const GRIP_BY_GLB := {
	"res://assets/props/gear/aspis_shield.glb": {
		"bone": "LeftHand",
		"position": Vector3(0.06, -0.02, 0.04),
		"rotation_deg": Vector3(-58.0, -102.0, 18.0),
		"scale": 0.92,
	},
	"res://assets/props/gear/tower_shield.glb": {
		"bone": "LeftHand",
		"position": Vector3(0.05, -0.04, 0.06),
		"rotation_deg": Vector3(-62.0, -98.0, 14.0),
		"scale": 1.0,
	},
	"res://assets/props/gear/xiphos_sword.glb": {
		"position": Vector3(0.006, -0.118, 0.0),
		"rotation_deg": Vector3(-90.0, -90.0, 0.0),
		"scale": 0.98,
	},
	"res://assets/props/gear/kontos_spear.glb": {
		"position": Vector3(0.004, -0.15, -0.001),
		"rotation_deg": Vector3(-90.0, -90.0, 0.0),
		"scale": 1.18,
	},
	"res://assets/props/weapons/dory_spear.glb": {
		"position": Vector3(0.003, -0.138, -0.0005),
		"rotation_deg": Vector3(-90.0, -90.0, 0.0),
		"scale": 1.06,
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

const HELMET_BY_GLB := {
	"res://assets/props/gear/corinthian_helmet.glb": {
		"bone": "Head",
		"position": Vector3(0.0, 0.04, 0.025),
		"rotation_deg": Vector3(-90.0, 180.0, 0.0),
		"scale": 0.46,
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
	var cfg: Dictionary = HELMET_BY_GLB.get(glb_path, {
		"bone": "Head",
		"position": Vector3(0.0, 0.03, 0.02),
		"rotation_deg": Vector3(-90.0, 180.0, 0.0),
		"scale": 0.48,
	})
	var grip: Dictionary = cfg.duplicate(true)
	grip["bone"] = String(grip.get("bone", "Head"))
	var mount := WeaponGrip.attach(model, glb_path, "shield", grip)
	if mount != null:
		mount.name = "HelmetBone"
	return mount


static func _find_skeleton(model: Node3D) -> Skeleton3D:
	for node in model.find_children("*", "Skeleton3D", true, false):
		return node as Skeleton3D
	return null

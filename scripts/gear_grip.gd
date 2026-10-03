extends RefCounted



const WeaponGrip = preload("res://scripts/weapon_grip.gd")




const GRIP_BY_GLB: = {


	"res://assets/props/gear/aspis_shield.glb": {
		"bone": "LowerArm_L", 
		"position": Vector3(0.0, 0.0, 0.08), 
		"rotation_deg": Vector3(90.0, 0.0, 0.0), 
		"scale": 1.5, 
		"center_prop": true, 
	}, 
	"res://assets/props/gear/tower_shield.glb": {
		"bone": "Wrist.L", 
		"position": Vector3(0.08, -0.02, 0.4), 
		"rotation_deg": Vector3(0.0, 0.0, 0.0), 
		"scale": 1.08, 
		"center_prop": true, 
	}, 

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
		"position": Vector3(-0.08, -0.02, 0.4), 
		"rotation_deg": Vector3(90.0, 0.0, 0.0), 
		"scale": 0.98, 
	}, 
	"res://assets/props/gear/kontos_spear.glb": {
		"bone": "Wrist.R", 
		"position": Vector3(-0.08, -0.02, 0.4), 
		"rotation_deg": Vector3(90.0, 0.0, 0.0), 
		"scale": 1.12, 
		"spear_hold_along_aim": 0.34, 
	}, 
	"res://assets/props/weapons/dory_spear.glb": {
		"bone": "Wrist_R", 
		"position": Vector3(0.0, 0.0, 0.0), 
		"rotation_deg": Vector3(180.0, 0.0, 0.0), 
		"scale": 1.8, 
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


const HELMET_BY_GLB: = {
	"res://assets/props/gear/corinthian_helmet.glb": {
		"position": Vector3(0.0, 0.035, 0.01), 
		"rotation_deg": Vector3(0.0, 0.0, 0.0), 
		"target_extent": 0.26, 
	}, 
}


# KayKit rigs (knight/rogue/mage) expose dedicated hand-attach bones
# ("handslot_r"/"handslot_l") plus weapon-holder sockets. Props mounted there
# need their own hold tuning because the hand bone's rest orientation differs
# from the greek/quaternius rigs. These are normalized to a canonical frame
# first, then nudged into a believable grip.
# Mounted on KayKit's dedicated weapon-holder sockets (1H_Sword, Round_Shield,
# 1H_Crossbow, 2H_Staff ...). The animations keep those sockets oriented for the
# weapon through every clip, so a +Y-authored prop sits correctly with identity
# rotation. skip_normalize avoids compounding the model's ~1.52x skeleton scale.
# Scales/offsets are derived from the measured raw prop sizes; +Y position moves
# the hand grip from the prop's centre toward its butt.
const GRIP_BY_GLB_KAYKIT: = {
	"res://assets/props/weapons/dory_spear.glb": {
		"bone": "1H_Sword", 
		"position": Vector3(0.0, 0.85, 0.0), 
		"rotation_deg": Vector3(0.0, 0.0, 0.0), 
		"scale": 1.7, 
		"skip_normalize": true, 
	}, 
	"res://assets/props/gear/kontos_spear.glb": {
		"bone": "1H_Sword", 
		"position": Vector3(0.0, 1.0, 0.0), 
		"rotation_deg": Vector3(0.0, 0.0, 0.0), 
		"scale": 2.0, 
		"skip_normalize": true, 
	}, 
	"res://assets/props/gear/aspis_shield.glb": {
		"bone": "Round_Shield", 
		"position": Vector3(0.0, 0.0, 0.0), 
		"rotation_deg": Vector3(0.0, 0.0, 0.0), 
		"scale": 0.78, 
		"skip_normalize": true, 
	}, 
	"res://assets/props/gear/tower_shield.glb": {
		"bone": "Rectangle_Shield", 
		"position": Vector3(0.0, 0.0, 0.0), 
		"rotation_deg": Vector3(0.0, 0.0, 0.0), 
		"scale": 0.8, 
		"skip_normalize": true, 
	}, 
	"res://assets/props/weapons/cretan_bow.glb": {
		"bone": "1H_Crossbow", 
		"position": Vector3(0.0, 0.0, 0.0), 
		"rotation_deg": Vector3(0.0, 0.0, 0.0), 
		"scale": 1.1, 
		"skip_normalize": true, 
	}, 
	"res://assets/props/weapons/theurgist_staff.glb": {
		"bone": "2H_Staff", 
		"position": Vector3(0.0, 0.85, 0.0), 
		"rotation_deg": Vector3(0.0, 0.0, 0.0), 
		"scale": 1.7, 
		"skip_normalize": true, 
	}, 
	"res://assets/props/gear/xiphos_sword.glb": {
		"bone": "1H_Sword", 
		"position": Vector3(0.0, 0.0, 0.0), 
		"rotation_deg": Vector3(0.0, 0.0, 0.0), 
		"scale": 0.9, 
		"skip_normalize": true, 
	}, 
}


static func _is_kaykit(model: Node3D) -> bool:
	if model == null:
		return false
	var nlow: = String(model.name).to_lower()
	if "knight" in nlow or "rogue" in nlow or "mage" in nlow or "barbarian" in nlow:
		return true
	var skel: = _find_skeleton(model)
	return skel != null and skel.find_bone("handslot_r") >= 0


static func grip_for_glb(glb_path: String, model: Node3D = null) -> Dictionary:
	if model != null and _is_kaykit(model) and GRIP_BY_GLB_KAYKIT.has(glb_path):
		return (GRIP_BY_GLB_KAYKIT[glb_path] as Dictionary).duplicate(true)
	var g: Dictionary = GRIP_BY_GLB.get(glb_path, {})
	return g.duplicate(true)


static func weapon_class_for(glb_path: String) -> String:
	var lower: = glb_path.to_lower()
	if lower.find("shield") >= 0 or lower.find("aspis") >= 0:
		return "shield"
	if lower.find("bow") >= 0:
		return "gun"
	return "melee"


static func attach_weapon(model: Node3D, glb_path: String) -> Node3D:
	if glb_path == "" or not ResourceLoader.exists(glb_path):
		return null
	var grip: = grip_for_glb(glb_path, model)
	var wclass: = weapon_class_for(glb_path)
	var att: = WeaponGrip.attach(model, glb_path, wclass, grip)
	if att == null:
		return null
	_apply_hold_tweaks(att, grip)
	return att


static func attach_shield(model: Node3D, glb_path: String) -> Node3D:
	if glb_path == "" or not ResourceLoader.exists(glb_path):
		return null
	var grip: = grip_for_glb(glb_path, model)
	var att: = WeaponGrip.attach(model, glb_path, "shield", grip)
	if att == null:
		return null
	_apply_hold_tweaks(att, grip)
	return att



static func _apply_hold_tweaks(attachment: Node3D, grip: Dictionary) -> void :
	var held: = attachment.get_node_or_null("Grip/Normalized") as Node3D
	if held == null:
		held = attachment.find_child("Normalized", true, false) as Node3D
	if held == null:
		return
	var along: = float(grip.get("spear_hold_along_aim", 0.0))
	if along != 0.0:

		held.position.z -= along
	if bool(grip.get("center_prop", false)):
		var aabb: = _held_aabb(held)
		held.position -= aabb.position + aabb.size * 0.5


static func _held_aabb(root: Node3D) -> AABB:
	var aabb: = AABB()
	var first: = true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi: = n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf: = Transform3D.IDENTITY
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
	var att: = BoneAttachment3D.new()
	att.name = "HelmetBone"
	att.bone_name = "Head"
	if skel.find_bone("Head") < 0 and skel.find_bone("head") >= 0:
		att.bone_name = "head"
	skel.add_child(att)
	var holder: = Node3D.new()
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

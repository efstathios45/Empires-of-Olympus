


extends RefCounted

const TESANA_WEAPON_GRIP_VERSION: = 3

const CLASS_LENGTH: = {
	"gun": 0.8, 
	"pistol": 0.26, 
	"melee": 0.95, 
	"shield": 0.55, 
}





const CLASS_FRAME: = {
	"gun": {"aim_axis": 0, "aim_sign": -1.0, "up_axis": 1, "up_sign": 1.0, "grip_mode": "rear_lower"}, 
	"pistol": {"aim_axis": 0, "aim_sign": -1.0, "up_axis": 1, "up_sign": 1.0, "grip_mode": "rear_lower"}, 
	"melee": {"aim_axis": 1, "aim_sign": 1.0, "up_axis": 0, "up_sign": 1.0, "grip_mode": "low_end", "grip_axis": 1, "grip_fraction": 0.15}, 
	"shield": {"aim_axis": 1, "aim_sign": 1.0, "up_axis": 0, "up_sign": 1.0, "grip_mode": "low_end", "grip_axis": 1, "grip_fraction": 0.15}, 
}



const CLASS_GRIP: = {
	"gun": {"bone": "RightHand", "position": Vector3(-0.1, 0.0, 0.0), "rotation_deg": Vector3(-79, 0, -90), "scale": 1.0}, 
	"pistol": {"bone": "RightHand", "position": Vector3(-0.035, 0.0, 0.0), "rotation_deg": Vector3(-90, 0, -90), "scale": 1.0}, 
	"melee": {"bone": "RightHand", "position": Vector3(0.003, -0.134, -0.0005), "rotation_deg": Vector3(-90, -90, 0), "scale": 1.0}, 
	"shield": {"bone": "LeftLowerArm", "position": Vector3(0.0, 0.0, 0.0), "rotation_deg": Vector3(0, 0, 0), "scale": 1.0}, 
}





static func attach(
	model: Node3D, 
	weapon_glb_path: String, 
	weapon_class: String = "gun", 
	grip: Dictionary = {}
) -> Node3D:
	var skel: = _find_skeleton(model)
	if skel == null:
		push_warning("WeaponGrip: no skeleton on %s" % model.name)
		return null

	var g: Dictionary = (
		CLASS_GRIP.get(weapon_class, CLASS_GRIP["gun"]) as Dictionary
	).duplicate(true)
	for key in grip:
		g[key] = grip[key]

	if not ResourceLoader.exists(weapon_glb_path):
		push_warning("WeaponGrip: missing weapon " + weapon_glb_path)
		return null

	var scene: = load(weapon_glb_path) as PackedScene
	if scene == null:
		push_warning("WeaponGrip: weapon is not a PackedScene " + weapon_glb_path)
		return null
	var inst: = scene.instantiate() as Node3D


	var skip_norm: = bool(g.get("skip_normalize", false))
	var held: Node3D = inst if skip_norm else normalize(inst, weapon_class)





	var comp: = 1.0 / maxf(0.0001, model.scale.x)
	var attachment: = BoneAttachment3D.new()
	attachment.name = "WeaponMount"
	attachment.bone_name = _resolve_bone(skel, String(g.get("bone", "RightHand")), weapon_class)
	skel.add_child(attachment)

	var holder: = Node3D.new()
	holder.name = "Grip"
	attachment.add_child(holder)

	var rotation_degrees: Vector3 = g.get("rotation_deg", Vector3.ZERO)
	var basis: = Basis.from_euler(Vector3(
		deg_to_rad(rotation_degrees.x), 
		deg_to_rad(rotation_degrees.y), 
		deg_to_rad(rotation_degrees.z)
	))
	var scale_factor: = float(g.get("scale", 1.0))
	var pos_scale: = 1.0
	if not skip_norm:
		scale_factor *= comp
		pos_scale = comp
	basis = basis.scaled(Vector3.ONE * scale_factor)
	holder.transform = Transform3D(
		basis, 
		(g.get("position", Vector3.ZERO) as Vector3) * pos_scale
	)
	holder.add_child(held)
	return attachment








static func normalize(prop: Node3D, weapon_class: String = "gun") -> Node3D:
	var holder: = Node3D.new()
	holder.name = "Normalized"
	if prop == null:
		return holder

	var verts: = _gather_verts(prop)
	if verts.is_empty():
		holder.add_child(prop)
		return holder

	var min_bounds: = verts[0]
	var max_bounds: = verts[0]
	for vertex in verts:
		min_bounds = Vector3(
			minf(min_bounds.x, vertex.x), 
			minf(min_bounds.y, vertex.y), 
			minf(min_bounds.z, vertex.z)
		)
		max_bounds = Vector3(
			maxf(max_bounds.x, vertex.x), 
			maxf(max_bounds.y, vertex.y), 
			maxf(max_bounds.z, vertex.z)
		)

	var size: = max_bounds - min_bounds
	var frame: Dictionary = CLASS_FRAME.get(
		weapon_class, 
		CLASS_FRAME["gun"]
	)
	var aim_axis_index: = int(frame["aim_axis"])
	var aim_sign: = float(frame["aim_sign"])
	var up_axis_index: = int(frame["up_axis"])
	var up_sign: = float(frame["up_sign"])
	var grip: Vector3
	if String(frame["grip_mode"]) == "rear_lower":
		grip = _rear_lower_grip_centroid(
			verts, 
			min_bounds, 
			max_bounds, 
			aim_axis_index, 
			up_axis_index
		)
	else:
		grip = _low_end_centroid(
			verts, 
			min_bounds, 
			max_bounds, 
			int(frame["grip_axis"]), 
			float(frame["grip_fraction"])
		)

	var aim: = _unit(aim_axis_index) * aim_sign
	var up: = _unit(up_axis_index) * up_sign
	var right: = up.cross(aim)
	var rotation: = Basis(right, up, aim).transposed()
	var aim_length: float = size[aim_axis_index]
	var target_length: float = CLASS_LENGTH.get(weapon_class, 0.8)
	var scale_factor: = (
		target_length / aim_length if aim_length > 1e-05 else 1.0
	)
	var basis: = rotation.scaled(Vector3.ONE * scale_factor)
	prop.transform = Transform3D(basis, - (basis * grip))
	holder.add_child(prop)
	return holder


static func _find_skeleton(model: Node3D) -> Skeleton3D:
	var named: = model.find_child("GeneralSkeleton", true, false)
	if named is Skeleton3D:
		return named
	for node in model.find_children("*", "Skeleton3D", true, false):
		return node as Skeleton3D
	return null



static func _resolve_bone(skel: Skeleton3D, preferred: String, weapon_class: String) -> String:
	if skel == null:
		return preferred
	if skel.find_bone(preferred) >= 0:
		return preferred
	var alts: Array = []
	var wclass: = weapon_class.to_lower()
	if wclass == "shield" or preferred in ["LeftLowerArm", "LeftHand", "LeftUpperArm", "LowerArm.L", "Wrist.L"]:
		alts = [
			"LowerArm.L", "Wrist.L", "hand.l", "wrist.l", 
			"Round_Shield", "handslot.l", "Badge_Shield", "Rectangle_Shield", 
		]
	elif preferred in ["RightHand", "RightLowerArm", "RightUpperArm", "Wrist.R", "LowerArm.R"]\
	or wclass in ["melee", "gun", "pistol"]:
		alts = [
			"Wrist.R", "LowerArm.R", "hand.r", "wrist.r", 
			"1H_Sword", "handslot.r", "2H_Sword", 
		]
	elif preferred == "Head":
		alts = ["head", "Head", "Knight_Helmet"]
	for name in alts:
		if skel.find_bone(String(name)) >= 0:
			return String(name)
	return preferred


static func _xf_to_root(node: Node3D, root: Node3D) -> Transform3D:
	var transform: = Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		if current is Node3D:
			transform = (current as Node3D).transform * transform
		current = current.get_parent()
	return transform


static func _gather_verts(root: Node3D) -> PackedVector3Array:
	var output: = PackedVector3Array()
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: = node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var transform: = _xf_to_root(mesh_instance, root)
		for surface_index in mesh_instance.mesh.get_surface_count():
			var arrays: = mesh_instance.mesh.surface_get_arrays(surface_index)
			if arrays.size() <= Mesh.ARRAY_VERTEX:
				continue
			for vertex in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				output.push_back(transform * vertex)
	return output


static func _unit(index: int) -> Vector3:
	if index == 0:
		return Vector3.RIGHT
	if index == 1:
		return Vector3.UP
	return Vector3.BACK


static func _low_end_centroid(
	verts: PackedVector3Array, 
	min_bounds: Vector3, 
	max_bounds: Vector3, 
	axis: int, 
	fraction: float
) -> Vector3:
	var span: float = max_bounds[axis] - min_bounds[axis]
	var cutoff: = min_bounds[axis] + span * fraction
	var center: = Vector3.ZERO
	var count: = 0
	for vertex in verts:
		if vertex[axis] <= cutoff:
			center += vertex
			count += 1
	if count > 0:
		center /= count
	return center






static func _rear_lower_grip_centroid(
	verts: PackedVector3Array, 
	min_bounds: Vector3, 
	max_bounds: Vector3, 
	aim_axis: int, 
	up_axis: int
) -> Vector3:
	var aim_span: float = max_bounds[aim_axis] - min_bounds[aim_axis]
	var up_span: float = max_bounds[up_axis] - min_bounds[up_axis]
	var aim_low: = min_bounds[aim_axis] + aim_span * 0.55
	var aim_high: = min_bounds[aim_axis] + aim_span * 0.85
	var up_cutoff: = min_bounds[up_axis] + up_span * 0.35
	var center: = Vector3.ZERO
	var count: = 0
	for vertex in verts:
		if (
			vertex[aim_axis] >= aim_low
			and vertex[aim_axis] <= aim_high
			and vertex[up_axis] <= up_cutoff
		):
			center += vertex
			count += 1
	if count > 0:
		return center / count


	return _low_end_centroid(
		verts, 
		min_bounds, 
		max_bounds, 
		up_axis, 
		0.3
	)

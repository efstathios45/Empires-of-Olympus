extends RefCounted
## Ancient Greek city curtain-walls: ashlar segments, towers, gate arches.


const GATE_ARCH: = "res://assets/environment/structures/city_gate_arch.glb"
const COLUMN: = "res://assets/environment/structures/marble_column.glb"
const BRAZIER: = "res://assets/environment/structures/brazier_flame.glb"
const ROCK_TEX: = "res://assets/textures/stone/terrain_rock.png"
const MARBLE_TEX: = "res://assets/textures/stone/white_marble.png"


## theme: athens | sparta | thebes — tint only; layout is shared.
static func build(world, center: Vector2, radius: float = 38.0, theme: String = "athens") -> void:
	var mat: = _wall_material(theme)
	var cap_mat: = _cap_material(theme)
	## Dodecagon curtain with south + north gate gaps.
	var sides: = 14
	var gate_half_angle: = deg_to_rad(16.0)
	var south: = Vector2(0.0, 1.0)
	var north: = Vector2(0.0, -1.0)
	for i in sides:
		var a0: float = TAU * float(i) / float(sides) - PI * 0.5
		var a1: float = TAU * float(i + 1) / float(sides) - PI * 0.5
		var mid: float = (a0 + a1) * 0.5
		var dir: = Vector2(cos(mid), sin(mid))
		if absf(dir.angle_to(south)) < gate_half_angle:
			continue
		if absf(dir.angle_to(north)) < gate_half_angle:
			continue
		_wall_segment(world, center, radius, a0, a1, mat, cap_mat)
	## Interval towers (skip gate mouths)
	for i in sides:
		var a: float = TAU * float(i) / float(sides) - PI * 0.5
		var dir: = Vector2(cos(a), sin(a))
		if absf(dir.angle_to(south)) < gate_half_angle * 0.9:
			continue
		if absf(dir.angle_to(north)) < gate_half_angle * 0.9:
			continue
		## Only every other vertex → fewer chunky towers.
		if i % 2 != 0:
			continue
		var p: = center + dir * (radius + 0.35)
		_tower(world, p.x, p.y, mat, cap_mat)
	_gate(world, center + Vector2(0.0, radius - 0.5), 0.0)
	_gate(world, center + Vector2(0.0, -(radius - 0.5)), 180.0)
	_brazier(world, center.x - 5.2, center.y + radius - 2.0)
	_brazier(world, center.x + 5.2, center.y + radius - 2.0)
	_column(world, center.x - 4.0, center.y - (radius - 1.5))
	_column(world, center.x + 4.0, center.y - (radius - 1.5))


static func _wall_material(theme: String) -> StandardMaterial3D:
	var mat: = StandardMaterial3D.new()
	## Prefer marble/limestone ashlar over orange rock brick.
	match theme:
		"sparta":
			mat.albedo_color = Color(0.92, 0.78, 0.68)
		"thebes":
			mat.albedo_color = Color(0.86, 0.88, 0.72)
		_:
			mat.albedo_color = Color(0.94, 0.9, 0.82)
	if ResourceLoader.exists(MARBLE_TEX):
		mat.albedo_texture = load(MARBLE_TEX)
	elif ResourceLoader.exists(ROCK_TEX):
		mat.albedo_texture = load(ROCK_TEX)
	mat.uv1_scale = Vector3(0.9, 0.7, 0.9)
	mat.uv1_triplanar = true
	mat.uv1_triplanar_sharpness = 6.0
	mat.roughness = 0.9
	mat.metallic = 0.0
	return mat


static func _cap_material(theme: String) -> StandardMaterial3D:
	var mat: = StandardMaterial3D.new()
	match theme:
		"sparta":
			mat.albedo_color = Color(0.85, 0.7, 0.58)
		"thebes":
			mat.albedo_color = Color(0.78, 0.82, 0.62)
		_:
			mat.albedo_color = Color(0.9, 0.86, 0.76)
	if ResourceLoader.exists(MARBLE_TEX):
		mat.albedo_texture = load(MARBLE_TEX)
	mat.uv1_scale = Vector3(1.2, 0.9, 1.2)
	mat.uv1_triplanar = true
	mat.roughness = 0.82
	return mat


static func _wall_segment(world, center: Vector2, radius: float, a0: float, a1: float, mat: Material, cap_mat: Material) -> void:
	var p0: = center + Vector2(cos(a0), sin(a0)) * radius
	var p1: = center + Vector2(cos(a1), sin(a1)) * radius
	var mid: = (p0 + p1) * 0.5
	var span: = p0.distance_to(p1)
	var yaw: = atan2(p1.x - p0.x, p1.y - p0.y)
	var gy: float = world.sample_height(mid.x, mid.y)
	var height: = 4.4
	var thick: = 1.55
	var body: = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: = CollisionShape3D.new()
	var box: = BoxShape3D.new()
	box.size = Vector3(thick, height, span + 0.12)
	shape.shape = box
	shape.position.y = height * 0.5
	body.add_child(shape)
	var mesh_i: = MeshInstance3D.new()
	var mesh: = BoxMesh.new()
	mesh.size = box.size
	mesh_i.mesh = mesh
	mesh_i.material_override = mat
	mesh_i.position.y = height * 0.5
	body.add_child(mesh_i)
	## Crenellation blocks along the top (Greek battlement look, not one slab).
	var merlons: = maxi(2, int(span / 1.8))
	for mi in merlons:
		if mi % 2 == 1:
			continue
		var t: = (float(mi) + 0.5) / float(merlons) - 0.5
		var cap: = MeshInstance3D.new()
		var cap_mesh: = BoxMesh.new()
		cap_mesh.size = Vector3(thick + 0.2, 0.7, span / float(merlons) * 0.85)
		cap.mesh = cap_mesh
		cap.material_override = cap_mat
		cap.position = Vector3(0.0, height + 0.35, t * span)
		body.add_child(cap)
	world.add_child(body)
	body.global_position = Vector3(mid.x, gy - 0.15, mid.y)
	body.rotation.y = yaw


static func _tower(world, wx: float, wz: float, mat: Material, cap_mat: Material) -> void:
	var gy: float = world.sample_height(wx, wz)
	var body: = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var h: = 6.4
	var w: = 2.8
	var shape: = CollisionShape3D.new()
	var box: = BoxShape3D.new()
	box.size = Vector3(w, h, w)
	shape.shape = box
	shape.position.y = h * 0.5
	body.add_child(shape)
	var mesh_i: = MeshInstance3D.new()
	var mesh: = BoxMesh.new()
	mesh.size = box.size
	mesh_i.mesh = mesh
	mesh_i.material_override = mat
	mesh_i.position.y = h * 0.5
	body.add_child(mesh_i)
	var roof: = MeshInstance3D.new()
	var roof_mesh: = BoxMesh.new()
	roof_mesh.size = Vector3(w + 0.45, 0.45, w + 0.45)
	roof.mesh = roof_mesh
	roof.material_override = cap_mat
	roof.position.y = h + 0.2
	body.add_child(roof)
	world.add_child(body)
	body.global_position = Vector3(wx, gy - 0.15, wz)


static func _gate(world, pos: Vector2, yaw_deg: float) -> void:
	if not world.has_method("_place_glb"):
		return
	var gate = world._place_glb(GATE_ARCH, pos.x, pos.y, 9.0, yaw_deg, 0)
	if gate != null:
		world._add_box_collider(gate, Vector3(2.6, 8.5, 2.2), Vector3(3.2, 4.25, 0.0))
		world._add_box_collider(gate, Vector3(2.6, 8.5, 2.2), Vector3(-3.2, 4.25, 0.0))


static func _brazier(world, wx: float, wz: float) -> void:
	if not world.has_method("_place_glb"):
		return
	var b = world._place_glb(BRAZIER, wx, wz, 1.6, 0.0, 0)
	if b != null:
		world._add_pillar_collider(b, 0.42, 1.6, Vector3.ZERO)


static func _column(world, wx: float, wz: float) -> void:
	if not world.has_method("_place_glb"):
		return
	var c = world._place_glb(COLUMN, wx, wz, 6.2, 0.0, 0)
	if c != null:
		world._add_pillar_collider(c, 0.52, 6.2, Vector3.ZERO)

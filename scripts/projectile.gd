extends Node3D
## Projectile — arrows and magic bolts. Travels straight, damages the first
## enemy in its path, dies on hit or after a timeout.

var direction := Vector3.FORWARD
var speed := 24.0
var damage := 10.0
var is_magic := false
var life := 2.2

static func spawn(parent: Node, origin: Vector3, dir: Vector3, spd: float, dmg: float, magic: bool) -> Node3D:
	var p := Node3D.new()
	p.set_script(load("res://scripts/projectile.gd"))
	p.direction = dir.normalized()
	p.speed = spd
	p.damage = dmg
	p.is_magic = magic
	parent.add_child(p)
	p.global_position = origin
	p._build()
	return p

func _build() -> void:
	var mesh_inst := MeshInstance3D.new()
	if is_magic:
		var sphere := SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		mesh_inst.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.75, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.45, 0.7, 1.0)
		mat.emission_energy_multiplier = 2.4
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_inst.material_override = mat
	else:
		# Arrow: thin stretched box aligned to travel direction.
		var box := BoxMesh.new()
		box.size = Vector3(0.05, 0.05, 0.7)
		mesh_inst.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.32, 0.18)
		mesh_inst.material_override = mat
	add_child(mesh_inst)
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	global_position += direction * speed * delta

	# Terrain clip.
	var world := get_tree().get_first_node_in_group("game_world")
	if world and world.has_method("sample_height"):
		var ground_y: float = world.sample_height(global_position.x, global_position.z)
		if global_position.y < ground_y - 0.2:
			queue_free()
			return

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get("dead"):
			continue
		if enemy.global_position.distance_to(global_position) < 1.1:
			if enemy.has_method("take_damage"):
				var player := get_tree().get_first_node_in_group("player")
				var from_pos: Vector3 = player.global_position if player else global_position
				enemy.take_damage(damage, from_pos)
			## Distinct impact — different from the fire/swing whoosh.
			AudioManager.play_sfx(
				"thunderbolt" if is_magic else "bronze_hit",
				-2.5 if is_magic else -1.5,
				randf_range(0.9, 1.12))
			var vfx := preload("res://scripts/vfx_helper.gd")
			vfx.spawn_hit(global_position, get_parent())
			queue_free()
			return

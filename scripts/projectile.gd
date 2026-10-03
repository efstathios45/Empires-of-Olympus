extends Node3D



var direction: = Vector3.FORWARD
var speed: = 24.0
var damage: = 10.0
var is_magic: = false
var life: = 2.2

static func spawn(parent: Node, origin: Vector3, dir: Vector3, spd: float, dmg: float, magic: bool) -> Node3D:
	var p: = Node3D.new()
	p.set_script(load("res://scripts/projectile.gd"))
	p.direction = dir.normalized()
	p.speed = spd
	p.damage = dmg
	p.is_magic = magic
	parent.add_child(p)
	p.global_position = origin
	p._build()
	return p

func _build() -> void :
	var mesh_inst: = MeshInstance3D.new()
	if is_magic:
		var sphere: = SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		mesh_inst.mesh = sphere
		var mat: = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.75, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.45, 0.7, 1.0)
		mat.emission_energy_multiplier = 2.4
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_inst.material_override = mat
	else:

		var box: = BoxMesh.new()
		box.size = Vector3(0.05, 0.05, 0.7)
		mesh_inst.mesh = box
		var mat: = StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.32, 0.18)
		mesh_inst.material_override = mat
	add_child(mesh_inst)
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void :
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	global_position += direction * speed * delta


	var world: = get_tree().get_first_node_in_group("game_world")
	if world and world.has_method("sample_height"):
		var ground_y: float = world.sample_height(global_position.x, global_position.z)
		if global_position.y < ground_y - 0.2:
			queue_free()
			return

	var shooter: = _find_shooter()
	var from_pos: Vector3 = shooter.global_position if shooter else global_position
	var targets: Array = []
	targets.append_array(get_tree().get_nodes_in_group("enemies"))
	for p in get_tree().get_nodes_in_group("player"):
		if shooter != null and shooter.has_method("is_rival_player") and shooter.is_rival_player(p):
			targets.append(p)
		elif shooter == null and p.is_in_group("remote_player"):
			targets.append(p)
	for enemy in targets:
		if not is_instance_valid(enemy) or enemy.get("dead"):
			continue
		if enemy.global_position.distance_to(global_position) < 1.1:
			if shooter != null and shooter.has_method("_deal_pvp_hit") and enemy.is_in_group("player"):
				shooter.call("_deal_pvp_hit", enemy, damage)
			elif enemy.has_method("take_damage"):
				enemy.take_damage(damage, from_pos)

			AudioManager.play_sfx(
				"thunderbolt" if is_magic else "bronze_hit", 
				-2.5 if is_magic else -1.5, 
				randf_range(0.9, 1.12))
			var vfx: = preload("res://scripts/vfx_helper.gd")
			vfx.spawn_hit(global_position, get_parent())
			queue_free()
			return


func _find_shooter() -> Node:
	for p in get_tree().get_nodes_in_group("player"):
		if p.is_in_group("remote_player"):
			continue
		return p
	return null

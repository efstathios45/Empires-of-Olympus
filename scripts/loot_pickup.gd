extends Area3D
## LootPickup — ground drop that pops out of a slain foe and can be collected.
## Shows a floating name; walking into it (or pressing E nearby) loots it.

const GearPaint = preload("res://scripts/gear_paint.gd")

var item_id: String = ""
var _label: Label3D
var _bob_t: float = 0.0
var _settled: bool = false
var _velocity: Vector3 = Vector3.ZERO


func setup(id: String, from: Vector3) -> void:
	item_id = id
	global_position = from + Vector3(0, 0.6, 0)
	# Burst outward so drops are readable on the ground.
	var dir := Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1))
	if dir.length_squared() < 0.01:
		dir = Vector3.RIGHT
	dir = dir.normalized()
	_velocity = dir * randf_range(2.2, 3.6) + Vector3.UP * randf_range(3.5, 5.0)

	collision_layer = 0
	collision_mask = 0
	monitoring = true
	monitorable = false
	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.1
	cs.shape = sphere
	add_child(cs)

	var item: Dictionary = GameState.SHOP_ITEMS.get(item_id, {})
	var glb: String = String(item.get("glb", ""))
	var mesh_root := Node3D.new()
	mesh_root.name = "Mesh"
	add_child(mesh_root)
	if glb != "" and ResourceLoader.exists(glb):
		var inst: Node3D = load(glb).instantiate()
		mesh_root.add_child(inst)
		# Pocket-size world drop.
		mesh_root.scale = Vector3.ONE * 0.55
		GearPaint.paint_attached(inst, glb)
	else:
		var stub := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.35, 0.35, 0.35)
		stub.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.7, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(0.5, 0.35, 0.1)
		mat.emission_energy_multiplier = 0.6
		stub.material_override = mat
		mesh_root.add_child(stub)

	_label = Label3D.new()
	_label.text = String(item.get("name", item_id))
	_label.font_size = 42
	_label.modulate = Color(1.0, 0.92, 0.55)
	_label.outline_modulate = Color(0, 0, 0, 0.85)
	_label.outline_size = 8
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 0.85, 0)
	_label.no_depth_test = true
	add_child(_label)

	body_entered.connect(_on_body)
	set_collision_mask_value(1, true)
	# Brief delay before auto-collect so the burst is visible.
	var tree := get_tree()
	if tree:
		tree.create_timer(0.35).timeout.connect(func() -> void: _settled = true)


func _physics_process(delta: float) -> void:
	_bob_t += delta
	if not _settled:
		_velocity.y -= 18.0 * delta
		global_position += _velocity * delta
		if global_position.y < 0.35:
			global_position.y = 0.35
			_velocity = Vector3.ZERO
			_settled = true
	else:
		# Gentle hover.
		if has_node("Mesh"):
			$Mesh.position.y = 0.15 + sin(_bob_t * 3.0) * 0.08
			$Mesh.rotate_y(delta * 1.4)
		# Auto-loot when player is close.
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player != null and is_instance_valid(player):
			if global_position.distance_to(player.global_position) < 1.6:
				_collect()


func _on_body(body: Node3D) -> void:
	if body.is_in_group("player"):
		_collect()


func _collect() -> void:
	if item_id == "":
		return
	var id := item_id
	item_id = ""  # prevent double collect
	var ok := GameState.grant_gear(id)
	if ok:
		AudioManager.play_sfx("gold_pickup", -4.0, randf_range(0.95, 1.08))
		var am := get_node_or_null("/root/AudioManager")
		if am == null:
			pass
	else:
		# Already owned — convert to gold consolation.
		GameState.add_gold(randi_range(12, 28))
		AudioManager.play_sfx("gold_pickup", -6.0)
	queue_free()

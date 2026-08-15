extends Area3D
## LootPickup — ground drop that pops from a slain foe.
## Meshes are AABB-fitted to a pocket size so Tripo/Kenney GLBs never spawn as
## screen-covering giant blocks (the classic unscaled import bug).

const TARGET_EXTENT := 0.42

var item_id: String = ""
var _label: Label3D
var _mesh_root: Node3D
var _bob_t: float = 0.0
var _settled: bool = false
var _velocity: Vector3 = Vector3.ZERO
var _collecting: bool = false


func setup(id: String, from: Vector3) -> void:
	item_id = id
	collision_layer = 0
	collision_mask = 0
	monitoring = true
	monitorable = false

	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	cs.shape = sphere
	add_child(cs)

	_mesh_root = Node3D.new()
	_mesh_root.name = "Mesh"
	add_child(_mesh_root)
	_build_visual(id)

	_label = Label3D.new()
	_label.text = GameState.item_name(id)
	_label.font_size = 64
	_label.pixel_size = 0.0036
	_label.modulate = Color(1.0, 0.92, 0.55)
	_label.outline_modulate = Color(0, 0, 0, 0.9)
	_label.outline_size = 18
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = false
	_label.position = Vector3(0, 0.75, 0)
	add_child(_label)

	# Place AFTER visual so we sit on terrain, not at y=0 underground.
	global_position = from + Vector3(0, 0.55, 0)
	_snap_to_ground()

	var dir := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	if dir.length_squared() < 0.01:
		dir = Vector3.RIGHT
	dir = dir.normalized()
	_velocity = dir * randf_range(2.0, 3.4) + Vector3.UP * randf_range(3.2, 4.8)

	body_entered.connect(_on_body)
	set_collision_mask_value(2, true)  # player layer
	var tree := get_tree()
	if tree:
		tree.create_timer(0.4).timeout.connect(func() -> void: _settled = true)


func _build_visual(id: String) -> void:
	var def: Dictionary = GameState.item_def(id)
	var glb: String = String(def.get("glb", ""))
	if glb != "" and ResourceLoader.exists(glb):
		var scene: PackedScene = load(glb) as PackedScene
		if scene != null:
			var inst: Node3D = scene.instantiate()
			_mesh_root.add_child(inst)
			# Critical: fit to pocket size using AABB, not a blind multiplier.
			ModelUtils.scale_to_max_extent(inst, TARGET_EXTENT)
			ModelUtils.ground_model(inst, 0.0)
			return
	_build_stub(def)


func _build_stub(def: Dictionary) -> void:
	var stub := MeshInstance3D.new()
	var box := BoxMesh.new()
	var cells: Vector2i = GameState.item_cells(String(def.get("id", item_id)))
	if cells.y >= 2:
		box.size = Vector3(0.18, 0.48, 0.12)
	else:
		box.size = Vector3(0.28, 0.28, 0.28)
	stub.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = def.get("color", Color(0.85, 0.7, 0.3))
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.55
	mat.emission_energy_multiplier = 0.55
	stub.material_override = mat
	stub.position.y = box.size.y * 0.5
	_mesh_root.add_child(stub)


func _snap_to_ground() -> void:
	var world := get_tree().get_first_node_in_group("game_world")
	if world != null and world.has_method("sample_height"):
		var gy: float = world.sample_height(global_position.x, global_position.z)
		global_position.y = gy + 0.35


func _physics_process(delta: float) -> void:
	_bob_t += delta
	if not _settled:
		_velocity.y -= 18.0 * delta
		global_position += _velocity * delta
		var floor_y := 0.35
		var world := get_tree().get_first_node_in_group("game_world")
		if world != null and world.has_method("sample_height"):
			floor_y = world.sample_height(global_position.x, global_position.z) + 0.35
		if global_position.y < floor_y:
			global_position.y = floor_y
			_velocity = Vector3.ZERO
			_settled = true
	else:
		if _mesh_root != null:
			_mesh_root.position.y = 0.12 + sin(_bob_t * 3.0) * 0.06
			_mesh_root.rotate_y(delta * 1.35)
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player != null and is_instance_valid(player):
			if global_position.distance_to(player.global_position) < 1.55:
				_collect()


func _on_body(body: Node3D) -> void:
	if body.is_in_group("player"):
		_collect()


func _collect() -> void:
	if _collecting or item_id == "":
		return
	_collecting = true
	var id := item_id
	if GameState.try_add_to_bag(id):
		item_id = ""
		AudioManager.play_sfx("gold_pickup", -4.0, randf_range(0.95, 1.08))
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("show_announcement"):
			hud.show_announcement("Looted: %s" % GameState.item_name(id))
		queue_free()
	else:
		_collecting = false
		# Bag full — leave on ground; soft ping once.
		var hud2 := get_tree().get_first_node_in_group("hud")
		if hud2 != null and hud2.has_method("show_announcement"):
			hud2.show_announcement("Bag full — sell spoils to Kyros.")

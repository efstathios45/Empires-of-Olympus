extends Area3D



const GearPaint = preload("res://scripts/gear_paint.gd")


const EXTENT_BY_KIND: = {
	"weapon": 0.7, 
	"shield": 0.55, 
	"helmet": 0.32, 
	"armor": 0.4, 
	"boots": 0.28, 
	"necklace": 0.22, 
	"earring": 0.18, 
	"bracelet": 0.2, 
	"consumable": 0.18, 
	"scroll": 0.2, 
	"material": 0.16, 
	"gold": 0.22, 
}

var item_id: String = ""

var gold_amount: int = 0
var _label: Label3D
var _mesh_root: Node3D
var _icon: Sprite3D
var _bob_t: float = 0.0
var _settled: bool = false
var _velocity: Vector3 = Vector3.ZERO
var _collecting: bool = false


func setup(id: String, from: Vector3, gold_value: int = 0) -> void :
	item_id = id
	gold_amount = gold_value
	collision_layer = 0
	collision_mask = 0
	monitoring = true
	monitorable = false

	var cs: = CollisionShape3D.new()
	var sphere: = SphereShape3D.new()
	sphere.radius = 1.05
	cs.shape = sphere
	add_child(cs)

	_mesh_root = Node3D.new()
	_mesh_root.name = "Mesh"
	add_child(_mesh_root)
	_build_visual(id)

	_label = Label3D.new()
	if id == "gold_coin" and gold_amount > 0:
		_label.text = "%d δ" % gold_amount
	else:
		_label.text = GameState.item_name(id)
	_label.font_size = 42
	_label.pixel_size = 0.003
	_label.modulate = Color(1.0, 0.92, 0.55) if id != "gold_coin" else Color(1.0, 0.88, 0.3)
	_label.outline_modulate = Color(0, 0, 0, 0.9)
	_label.outline_size = 12
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 0.55, 0)
	add_child(_label)

	global_position = from + Vector3(0, 0.35, 0)
	_snap_to_ground()

	var dir: = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	if dir.length_squared() < 0.01:
		dir = Vector3.RIGHT
	dir = dir.normalized()
	_velocity = dir * randf_range(1.6, 2.8) + Vector3.UP * randf_range(2.2, 3.4)

	body_entered.connect(_on_body)
	set_collision_mask_value(2, true)
	call_deferred("_refit_visual")
	var tree: = get_tree()
	if tree:
		tree.create_timer(0.35).timeout.connect( func() -> void : _settled = true)


func _target_extent(def: Dictionary) -> float:
	var kind: = String(def.get("kind", ""))
	return float(EXTENT_BY_KIND.get(kind, 0.35))


func _build_visual(id: String) -> void :
	var def: Dictionary = GameState.item_def(id)

	_add_icon_billboard(id)

	var glb: String = String(def.get("glb", ""))
	if glb != "" and ResourceLoader.exists(glb):
		var scene: PackedScene = load(glb) as PackedScene
		if scene != null:
			var inst: Node3D = scene.instantiate()
			_mesh_root.add_child(inst)
			GearPaint.paint_attached(inst, glb)
			_fit_instance(inst, _target_extent(def))
			return
	_build_marker(def)


func _add_icon_billboard(id: String) -> void :
	var path: String = GameState.item_icon_path(id)
	if path == "" or not ResourceLoader.exists(path):
		return
	_icon = Sprite3D.new()
	_icon.texture = load(path)
	_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_icon.pixel_size = 0.0042
	_icon.position = Vector3(0, 0.32, 0)
	_icon.shaded = false
	_icon.double_sided = true
	add_child(_icon)


func _fit_instance(inst: Node3D, target: float) -> void :
	if inst == null or target <= 0.0:
		return
	ModelUtils.scale_to_max_extent(inst, target)
	var extent: = ModelUtils.measure_max_extent(inst)
	if extent > target * 1.15 or extent < 0.02:
		ModelUtils.scale_to_max_extent(inst, target)
	if inst.is_inside_tree():
		ModelUtils.ground_model(inst, 0.02)
	extent = ModelUtils.measure_max_extent(inst)
	if extent > 1.1:
		inst.scale *= 1.1 / extent
		if inst.is_inside_tree():
			ModelUtils.ground_model(inst, 0.02)


func _refit_visual() -> void :
	if _mesh_root == null:
		return
	var def: Dictionary = GameState.item_def(item_id)
	for child in _mesh_root.get_children():
		if child is MeshInstance3D:
			var mesh: Mesh = (child as MeshInstance3D).mesh
			if mesh is SphereMesh or mesh is CylinderMesh or mesh is BoxMesh:
				continue
		if child is Node3D:
			_fit_instance(child as Node3D, _target_extent(def))


func _build_marker(def: Dictionary) -> void :

	var stub: = MeshInstance3D.new()
	var kind: = String(def.get("kind", ""))
	var mesh: Mesh
	var y_lift: = 0.08
	match kind:
		"gold":
			var cyl: = CylinderMesh.new()
			cyl.top_radius = 0.09
			cyl.bottom_radius = 0.09
			cyl.height = 0.05
			mesh = cyl
			y_lift = 0.04
		"consumable":
			var cyl2: = CylinderMesh.new()
			cyl2.top_radius = 0.05
			cyl2.bottom_radius = 0.05
			cyl2.height = 0.14
			mesh = cyl2
		"material":
			var sph: = SphereMesh.new()
			sph.radius = 0.07
			sph.height = 0.14
			mesh = sph
		_:
			var sph2: = SphereMesh.new()
			sph2.radius = 0.08
			sph2.height = 0.16
			mesh = sph2
	stub.mesh = mesh
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = def.get("color", Color(0.85, 0.7, 0.3))
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.5
	mat.emission_energy_multiplier = 0.55
	stub.material_override = mat
	stub.position.y = y_lift
	_mesh_root.add_child(stub)


func _snap_to_ground() -> void :
	var world: = get_tree().get_first_node_in_group("game_world")
	if world != null and world.has_method("sample_height"):
		var gy: float = world.sample_height(global_position.x, global_position.z)
		global_position.y = gy + 0.12


func _physics_process(delta: float) -> void :
	_bob_t += delta
	if not _settled:
		_velocity.y -= 18.0 * delta
		global_position += _velocity * delta
		var floor_y: = 0.12
		var world: = get_tree().get_first_node_in_group("game_world")
		if world != null and world.has_method("sample_height"):
			floor_y = world.sample_height(global_position.x, global_position.z) + 0.12
		if global_position.y < floor_y:
			global_position.y = floor_y
			_velocity = Vector3.ZERO
			_settled = true
	else:
		if _mesh_root != null:
			_mesh_root.position.y = 0.04 + sin(_bob_t * 2.4) * 0.03
			_mesh_root.rotate_y(delta * 0.9)
		if _icon != null:
			_icon.position.y = 0.32 + sin(_bob_t * 2.4) * 0.04
		var player: = get_tree().get_first_node_in_group("player") as Node3D
		if player != null and is_instance_valid(player):
			if global_position.distance_to(player.global_position) < 1.55:
				_collect()


func _on_body(body: Node3D) -> void :
	if body.is_in_group("player"):
		_collect()


func _collect() -> void :
	if _collecting or item_id == "":
		return
	_collecting = true
	var id: = item_id
	var hud: = get_tree().get_first_node_in_group("hud")


	if id == "gold_coin" or String(GameState.item_def(id).get("kind", "")) == "gold":
		var amt: = gold_amount if gold_amount > 0 else 1
		GameState.add_gold(amt)
		item_id = ""
		AudioManager.play_sfx("gold_pickup", -3.0, randf_range(0.95, 1.1))
		if hud != null and hud.has_method("show_announcement"):
			hud.show_announcement("+%d δ" % amt)
		queue_free()
		return

	if GameState.try_add_to_bag(id):
		item_id = ""
		AudioManager.play_sfx("gold_pickup", -4.0, randf_range(0.95, 1.08))
		if hud != null and hud.has_method("show_announcement"):
			hud.show_announcement("Looted: %s" % GameState.item_name(id))
		queue_free()
	else:
		_collecting = false
		if hud != null and hud.has_method("show_announcement"):
			hud.show_announcement("Bag full — sell spoils to Kyros.")

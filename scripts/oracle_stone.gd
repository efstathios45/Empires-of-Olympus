extends StaticBody3D
## Oracle Stone — a cursed whispering monolith. Shatter it to cleanse the land.

const VfxHelper = preload("res://scripts/vfx_helper.gd")

var destroyed: bool = false
var _model: Node3D
var _glow_time: float = 0.0

static func create(at: Vector3) -> StaticBody3D:
	var s := StaticBody3D.new()
	s.set_script(load("res://scripts/oracle_stone.gd"))
	s.position = at
	return s

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 2.6, 1.4)
	shape.shape = box
	shape.position.y = 1.3
	add_child(shape)

	var path := "res://assets/props/items/oracle_stone.glb"
	if ResourceLoader.exists(path):
		_model = load(path).instantiate()
		add_child(_model)
		ModelUtils.scale_to_height(_model, 2.6)
		ModelUtils.ground_model(_model, 0.0)
		# Cursed violet glow.
		for mi in _model.find_children("*", "MeshInstance3D"):
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.35, 0.2, 0.45)
			mat.emission_enabled = true
			mat.emission = Color(0.6, 0.25, 0.9)
			mat.emission_energy_multiplier = 1.4
			(mi as MeshInstance3D).material_override = mat

	var light := OmniLight3D.new()
	light.light_color = Color(0.65, 0.3, 0.95)
	light.light_energy = 0.8
	light.omni_range = 6.0
	light.position.y = 1.6
	add_child(light)

func _process(delta: float) -> void:
	if destroyed or _model == null:
		return
	_glow_time += delta
	_model.rotation.y += delta * 0.25
	_model.position.y = sin(_glow_time * 1.4) * 0.06

func get_prompt() -> String:
	return "Shatter the Cursed Stone"

func interact() -> void:
	if destroyed:
		return
	destroyed = true
	GameState.register_stone_destroyed()
	GameState.add_gold(randi_range(25, 55))
	AudioManager.play_sfx("oracle_pulse")
	AudioManager.play_sfx("oracle_whisper", -6.0)
	VfxHelper.spawn_explosion(global_position + Vector3(0, 1.2, 0), get_parent())
	if is_instance_valid(_model):
		_model.visible = false
	var world := get_tree().get_first_node_in_group("game_world")
	if world and world.has_method("remove_interactable"):
		world.remove_interactable(self)
	# Leave only fading shards behind.
	var t := get_tree().create_timer(1.5)
	t.timeout.connect(queue_free)

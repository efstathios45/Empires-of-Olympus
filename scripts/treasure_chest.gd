extends StaticBody3D
## Treasure Chest — forgotten hero's gold hidden in the wilds. One-shot loot.

const VfxHelper = preload("res://scripts/vfx_helper.gd")

var opened: bool = false

static func create(at: Vector3) -> StaticBody3D:
	var c := StaticBody3D.new()
	c.set_script(load("res://scripts/treasure_chest.gd"))
	c.position = at
	return c

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.1, 0.9, 0.8)
	shape.shape = box
	shape.position.y = 0.45
	add_child(shape)

	var path := "res://assets/props/containers/treasure_chest.glb"
	if ResourceLoader.exists(path):
		var model: Node3D = load(path).instantiate()
		add_child(model)
		ModelUtils.scale_to_height(model, 0.95)
		ModelUtils.ground_model(model, 0.0)
		model.rotation.y = randf() * TAU

func get_prompt() -> String:
	return "Open the Ancient Chest"

func interact() -> void:
	if opened:
		return
	opened = true
	var gold := randi_range(45, 90)
	GameState.add_gold(gold)
	GameState.health_potions += 1
	GameState.potions_changed.emit()
	AudioManager.play_sfx("gold_pickup")
	VfxHelper.spawn_hit(global_position + Vector3(0, 0.8, 0), get_parent())
	DamageNumbers.spawn(get_parent(), global_position + Vector3(0, 1.4, 0), gold, Color(1.0, 0.85, 0.3))
	var world := get_tree().get_first_node_in_group("game_world")
	if world and world.has_method("remove_interactable"):
		world.remove_interactable(self)

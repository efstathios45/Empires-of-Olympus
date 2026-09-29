extends Node




const HIT_SCENE: PackedScene = preload("res://assets/3d_vfx/StylizedHitFX/effects/hit/vfx_hit_01.tscn")
const STRIKE_SCENE: PackedScene = preload("res://assets/3d_vfx/StylizedHitFX/effects/strike/vfx_strike_01.tscn")
const EXPLOSION_SCENE: PackedScene = preload("res://assets/3d_vfx/impact_explosions/effects/explosion/vfx_explosion_01.tscn")

static func _spawn(scene: PackedScene, at: Vector3, dir: Vector3, parent: Node) -> Node3D:
	if scene == null or parent == null:
		return null
	var inst: = scene.instantiate()
	if "autoplay" in inst:
		inst.set("autoplay", false)
	if "proximity_fade" in inst:
		inst.set("proximity_fade", false)
	parent.add_child(inst)
	inst.global_position = at

	if dir.length_squared() > 0.0001:
		var d: = dir.normalized()
		var up: = Vector3.UP if absf(d.dot(Vector3.UP)) < 0.999 else Vector3.FORWARD
		inst.look_at(inst.global_position + d, up)
		inst.rotate_object_local(Vector3.UP, PI * 0.5)
	if inst.has_node("AnimationPlayer") and inst.has_method("play"):
		inst.call("play")

	var tree: = parent.get_tree()
	if tree:
		var timer: = tree.create_timer(4.0)
		timer.timeout.connect( func(): if is_instance_valid(inst): inst.queue_free())
	return inst

static func spawn_hit(at: Vector3, parent: Node) -> Node3D:
	return _spawn(HIT_SCENE, at, Vector3.ZERO, parent)

static func spawn_strike(at: Vector3, dir: Vector3, parent: Node) -> Node3D:
	return _spawn(STRIKE_SCENE, at, dir, parent)

static func spawn_explosion(at: Vector3, parent: Node) -> Node3D:
	return _spawn(EXPLOSION_SCENE, at, Vector3.ZERO, parent)

extends SceneTree
## Smoke: Ancient Greek Tripo hoplite walk/slash/block + gear attach.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.set("player_class", "hoplite")
	var PlayerScript = load("res://scripts/player.gd")
	var player = PlayerScript.new()
	root.add_child(player)
	await process_frame
	await process_frame
	var anim: AnimationPlayer = player.get("anim") as AnimationPlayer
	var HeroAnim = load("res://scripts/utils/hero_anim.gd")
	var walk: String = String(HeroAnim.resolve(anim, "walk"))
	var atk: String = String(HeroAnim.resolve(anim, "attack_1"))
	var block: String = String(HeroAnim.resolve(anim, "block"))
	var idle: String = String(HeroAnim.resolve(anim, "idle"))
	var shield = player.get("shield_node")
	var weapon = player.get("weapon_node")
	var model: Node3D = null
	var mesh_root = player.get("mesh_root")
	if mesh_root != null and mesh_root.get_child_count() > 0:
		model = mesh_root.get_child(0) as Node3D
	var nlow := ""
	if model != null:
		nlow = model.name.to_lower()
	print("name=", nlow, " idle=", idle, " walk=", walk,
		" attack=", atk, " block=", block,
		" shield=", shield != null, " weapon=", weapon != null)
	var ok: bool = model != null and "spartan" in nlow \
		and idle != "" and walk != "" and atk != "" and block != "" \
		and shield != null and weapon != null
	print("SMOKE_ANCIENT_GREEK=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

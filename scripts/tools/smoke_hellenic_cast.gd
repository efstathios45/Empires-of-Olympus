extends SceneTree
## Smoke: greek_hoplite hero — Quaternius Walk/Slash, NO LegPlant.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var PlayerScript = load("res://scripts/player.gd")
	var player = PlayerScript.new()
	root.add_child(player)
	await process_frame
	await process_frame
	var anim: AnimationPlayer = player.get("anim") as AnimationPlayer
	var HeroAnim = load("res://scripts/utils/hero_anim.gd")
	var walk: String = String(HeroAnim.resolve(anim, "walk"))
	var atk: String = String(HeroAnim.resolve(anim, "attack_1"))
	var idle: String = String(HeroAnim.resolve(anim, "idle"))
	var block: String = String(HeroAnim.resolve(anim, "block"))
	var model: Node3D = null
	var mesh_root = player.get("mesh_root")
	if mesh_root != null and mesh_root.get_child_count() > 0:
		model = mesh_root.get_child(0) as Node3D
	var plant := false
	var nlow := ""
	if model != null:
		plant = model.find_child("LegPlantFix", true, false) != null
		nlow = model.name.to_lower()
	print("name=", nlow, " idle=", idle, " walk=", walk, " attack=", atk,
		" block=", block, " plant=", plant)
	var ok: bool = model != null and ("greek" in nlow or "hoplite" in nlow) \
		and walk == "Walk" \
		and (idle == "Idle" or idle == "Idle_Neutral") \
		and block == "Idle_Sword" and not plant \
		and atk != ""
	print("SMOKE_HELLENIC_CAST=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

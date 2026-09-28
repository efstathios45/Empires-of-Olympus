extends SceneTree
## Compile + resolve Quaternius hero walk/slash/block + shield attach.


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
	var block: String = String(HeroAnim.resolve(anim, "block"))
	var idle: String = String(HeroAnim.resolve(anim, "idle"))
	var shield = player.get("shield_node")
	var weapon = player.get("weapon_node")
	var model: Node3D = null
	var mesh_root = player.get("mesh_root")
	if mesh_root != null and mesh_root.get_child_count() > 0:
		model = mesh_root.get_child(0) as Node3D
	var plant := false
	var helm := false
	var pack_vis := false
	if model != null:
		plant = model.find_child("LegPlantFix", true, false) != null
		helm = model.find_child("CorinthianHelmMount", true, false) != null
		var bp = model.find_child("Backpack", true, false)
		pack_vis = bp != null and bp.visible
	var nlow := ""
	if model != null:
		nlow = model.name.to_lower()
	print("name=", nlow, " idle=", idle, " walk=", walk,
		" attack=", atk, " block=", block,
		" shield=", shield != null, " weapon=", weapon != null,
		" plant=", plant, " greek_helm=", helm, " pack_vis=", pack_vis)
	var ok: bool = model != null and ("king" in nlow or "hero" in nlow) \
		and idle == "Idle_Neutral" and walk == "Walk" and atk == "Sword_Slash" \
		and block == "Idle_Sword" \
		and shield != null and weapon != null and not plant and helm and not pack_vis
	print("SMOKE_QUATERNIUS=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

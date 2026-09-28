extends SceneTree
## Smoke: Quaternius+GreekLook hero — Walk/Idle_Sword, arms present, no LegPlant.


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
	var helm := false
	var wrists_ok := false
	if model != null:
		plant = model.find_child("LegPlantFix", true, false) != null
		nlow = model.name.to_lower()
		helm = model.find_child("CorinthianHelmMount", true, false) != null
		var skel: Skeleton3D = model.find_child("Skeleton3D", true, false)
		if skel != null:
			var wr := skel.get_bone_global_pose(skel.find_bone("Wrist.R")).origin
			var wl := skel.get_bone_global_pose(skel.find_bone("Wrist.L")).origin
			wrists_ok = wr.y > 0.6 and wl.y > 0.6
	var shield_ok: bool = player.get("shield_node") != null
	var weapon_ok: bool = player.get("weapon_node") != null
	print("name=", nlow, " idle=", idle, " walk=", walk, " attack=", atk,
		" block=", block, " plant=", plant, " helm=", helm,
		" wrists_ok=", wrists_ok, " weapon=", weapon_ok, " shield=", shield_ok)
	var ok: bool = model != null and ("guard" in nlow or "adventurer" in nlow or "quaternius" in nlow) \
		and walk == "Walk" and block == "Idle_Sword" and not plant \
		and helm and wrists_ok and weapon_ok and shield_ok and atk != ""
	print("SMOKE_HELLENIC_FIX=", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

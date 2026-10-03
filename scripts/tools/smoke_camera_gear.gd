extends SceneTree



func _init() -> void :
	call_deferred("_run")


func _run() -> void :
	var gs: = get_root().get_node_or_null("GameState")
	if gs == null:
		push_error("GameState missing")
		quit(1)
		return
	var paths: PackedStringArray = [
		gs.call("item_icon_path", "xiphos"), 
		gs.call("item_icon_path", "aspis"), 
		gs.call("item_icon_path", "corinthian_helm"), 
		gs.call("item_icon_path", "leather_boots"), 
		gs.call("item_icon_path", "bronze_greaves"), 
	]
	var uniq: = {}
	for p in paths:
		var s: = str(p)
		if s == "" or not ResourceLoader.exists(s):
			push_error("missing icon: " + s)
			quit(1)
			return
		if uniq.has(s):
			push_error("duplicate icon path: " + s)
			quit(1)
			return
		uniq[s] = true

	const GearGrip = preload("res://scripts/gear_grip.gd")
	var glb: = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate() as Node3D
	var root: = Node3D.new()
	root.add_child(glb)
	ModelUtils.setup_character_for_movement(glb, 1.85)
	var helm: = GearGrip.attach_helmet(glb, "res://assets/props/gear/corinthian_helmet.glb")
	var shield: = GearGrip.attach_shield(glb, "res://assets/props/gear/aspis_shield.glb")
	var weapon: = GearGrip.attach_weapon(glb, "res://assets/props/gear/xiphos_sword.glb")
	if helm == null or shield == null or weapon == null:
		push_error("gear attach failed")
		quit(1)
		return
	print("SMOKE_CAMERA_GEAR_OK icons+attach")
	quit(0)

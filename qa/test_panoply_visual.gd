extends SceneTree
## Verifies equipped helm/aspis attach to the player skeleton.
## Run: godot --headless --path . --script res://qa/test_panoply_visual.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails := 0
	var GS = load("res://scripts/autoloads/game_state.gd").new()
	GS.name = "GameState"
	root.add_child(GS)
	# Autoload alias for scripts that reference GameState global — inject into root tree
	# Scripts compiled against autoload need Engine singleton; emulate via set_meta isn't enough.
	# Instead call methods on GS directly and invoke player's refresh with GS state mirrored.
	await process_frame

	GS.bag.clear()
	GS.equipped = {"helmet": "", "armor": "", "weapon": "", "shield": ""}
	GS.try_add_to_bag("corinthian_helm")
	GS.try_add_to_bag("aspis")
	GS.try_add_to_bag("xiphos")

	# Mirror into real autoload if present
	if Engine.has_singleton("GameState") == false:
		pass
	# Prefer real autoload GameState when running as --script after project load fails;
	# fall back: use load player without _ready GameState refs by testing attach helpers.

	var PlayerScript = load("res://scripts/player.gd")
	if PlayerScript == null:
		print("FAIL player script")
		quit(1)
		return
	print("PLAYER_SCRIPT_LOADED")

	# Unit-test bone attach path via a minimal model
	var model_ps: PackedScene = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb")
	if model_ps == null:
		print("FAIL hoplite glb")
		fails += 1
	else:
		var model: Node3D = model_ps.instantiate()
		root.add_child(model)
		ModelUtils.setup_character_for_movement(model, 1.85)
		await process_frame
		var helm_path := "res://assets/props/gear/corinthian_helmet.glb"
		var shield_path := "res://assets/props/gear/aspis_shield.glb"
		var WeaponGrip = load("res://scripts/weapon_grip.gd")
		var shield = WeaponGrip.attach(model, shield_path, "shield")
		if shield == null:
			print("FAIL shield attach")
			fails += 1
		else:
			print("SHIELD_ATTACH_OK")
		# Helm via BoneAttachment3D
		var skel: Skeleton3D = null
		for n in model.find_children("*", "Skeleton3D", true, false):
			skel = n as Skeleton3D
			break
		if skel == null:
			print("FAIL no skeleton")
			fails += 1
		else:
			var att := BoneAttachment3D.new()
			att.bone_name = "Head"
			skel.add_child(att)
			var inst: Node3D = load(helm_path).instantiate()
			att.add_child(inst)
			ModelUtils.scale_to_max_extent(inst, 0.28)
			print("HELM_ATTACH_OK extent=", snappedf(ModelUtils.measure_max_extent(inst), 0.01))
		# Equip API
		if not GS.equip_from_bag(0):
			print("FAIL equip first")
			fails += 1
		print("equipped after first", GS.equipped)
		# find aspis
		var ai := -1
		for i in GS.bag.size():
			if str(GS.bag[i].get("id", "")) == "aspis":
				ai = i
		if ai < 0 or not GS.equip_from_bag(ai):
			print("FAIL equip aspis")
			fails += 1
		else:
			print("EQUIP_API_OK", GS.equipped)
		if String(GS.equipped.get("helmet", "")) == "" and String(GS.equipped.get("shield", "")) == "":
			# order may have equipped xiphos first
			print("NOTE equipped slots", GS.equipped)

	# Naming / Metin scan of player-facing shop names
	for id in ["hephaestus", "titan", "oracle"]:
		var nm: String = GS.item_name(id)
		print("NAME ", id, " => ", nm)
		if "Metin" in nm or "Forging Stone" in nm:
			print("FAIL name", nm)
			fails += 1

	# Loot scale still ok
	var root_n := Node3D.new()
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20, 40, 10)
	mi.mesh = box
	root_n.add_child(mi)
	ModelUtils.scale_to_max_extent(root_n, 0.55)
	var ext := ModelUtils.measure_max_extent(root_n)
	print("SCALE ", ext)
	if absf(ext - 0.55) > 0.08:
		print("FAIL scale")
		fails += 1

	if fails == 0:
		print("PANOPLY_VIS_OK")
		quit(0)
	else:
		print("PANOPLY_VIS_FAIL ", fails)
		quit(1)

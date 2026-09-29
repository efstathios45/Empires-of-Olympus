extends SceneTree
func _init(): call_deferred("run")
func run():
	for path in [
		"res://assets/characters/greek_hoplite/greek_hoplite.glb", 
		"res://assets/characters/citizen_merchant/citizen_merchant.glb", 
		"res://assets/characters/greek_merchant/greek_merchant.glb", 
		"res://assets/characters/greek_guard/greek_guard.glb", 
		"res://assets/characters/greek_citizen_woman/greek_citizen_woman.glb", 
	]:
		if not ResourceLoader.exists(path):
			print("MISSING ", path)
			continue
		var m: Node3D = load(path).instantiate()
		root.add_child(m)
		ModelUtils.setup_character_for_movement(m, 1.78)
		var ap: = m.find_child("AnimationPlayer", true) as AnimationPlayer
		var clips: PackedStringArray = ap.get_animation_list() if ap else PackedStringArray()
		print(path.get_file(), " clips=", clips, " n=", clips.size())
		if ap and ap.has_animation("Idle_Neutral"):
			var a: Animation = ap.get_animation("Idle_Neutral")
			print("  idle tracks before=", a.get_track_count())
			ModelUtils.strip_arm_animation_tracks(ap)
			var a2: Animation = ap.get_animation("Idle_Neutral")
			print("  idle tracks after=", a2.get_track_count())
		m.queue_free()
		await process_frame
	print("PROBE_NPC_OK")
	quit()

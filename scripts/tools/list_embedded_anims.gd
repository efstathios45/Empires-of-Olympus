extends SceneTree
func _init(): call_deferred("r")
func r():
	var m=load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	root.add_child(m)
	await process_frame
	print("CHILDREN:")
	for c in m.find_children("*","",true,false):
		if c is AnimationPlayer or c is AnimationMixer:
			print("  ", c.get_class(), " ", c.get_path())
			var ap=c as AnimationPlayer
			if ap:
				for libn in ap.get_animation_library_list():
					print("   lib=",libn," anims=",ap.get_animation_library(libn).get_animation_list())
	quit(0)

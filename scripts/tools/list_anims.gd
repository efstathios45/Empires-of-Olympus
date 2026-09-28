extends SceneTree
func _init() -> void:
	var lib := load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	for n in lib.get_animation_list():
		print("ANIM=", n)
	quit()

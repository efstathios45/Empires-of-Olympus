extends SceneTree
func _init() -> void:
	print("HAS_MOD=", ClassDB.class_exists("SkeletonModifier3D"))
	for s in ClassDB.class_get_signal_list("Skeleton3D"):
		var nm := String(s.name)
		if "update" in nm.to_lower() or "mod" in nm.to_lower():
			print("SIG ", nm)
	for m in ClassDB.class_get_method_list("Skeleton3D", true):
		var nm := String(m.name)
		if "modif" in nm.to_lower() or "skeleton_update" in nm.to_lower():
			print("METH ", nm)
	quit(0)

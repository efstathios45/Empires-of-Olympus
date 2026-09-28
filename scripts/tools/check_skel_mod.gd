extends SceneTree

func _init() -> void:
	print("HAS_CLASS=", ClassDB.class_exists("SkeletonModifier3D"))
	if ClassDB.class_exists("SkeletonModifier3D"):
		for m in ClassDB.class_get_method_list("SkeletonModifier3D", true):
			var n := str(m.get("name", ""))
			if "modif" in n.to_lower() or "process" in n.to_lower() or "skeleton" in n.to_lower():
				print("M=", n)
	print("PARENT=", ClassDB.get_parent_class("SkeletonModifier3D") if ClassDB.class_exists("SkeletonModifier3D") else "?")
	quit()

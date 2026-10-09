extends SceneTree
## Regress: remote Hoplite must use authored setup (not Maya-cm crush).


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var RemoteAvatar = load("res://scripts/remote_avatar.gd")
	var av: = CharacterBody3D.new()
	av.set_script(RemoteAvatar)
	av.call("setup", 2, "Leonidas", "sparta", 5, "hoplite")
	get_root().add_child(av)
	for _i in 8:
		await process_frame
	var mesh_root: Node3D = av.get_node_or_null("MeshRoot")
	if mesh_root == null or mesh_root.get_child_count() == 0:
		print("FAIL no model")
		quit(1)
		return
	var model: Node3D = mesh_root.get_child(0) as Node3D
	var sx: = float(model.scale.x)
	print("remote_root_scale=", sx)
	## Authored ≈ 0.95; broken movement crush ≈ 0.012
	if sx < 0.3 or sx > 3.0:
		print("FAIL scale looks crushed/blown — want ~1.0 authored, got ", sx)
		quit(1)
		return
	## No mesh should have been Maya-cm *100'd
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi: = n as MeshInstance3D
		if mi == null:
			continue
		if mi.scale.x >= 50.0:
			print("FAIL mesh ", mi.name, " has Maya-cm scale ", mi.scale)
			quit(1)
			return
	## Body mesh Object_14/15 should remain sizable in local AABB
	var body_ok: = false
	var body_opaque: = false
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi2: = n as MeshInstance3D
		if mi2 == null or mi2.mesh == null:
			continue
		if mi2.get_aabb().size.y > 1.0:
			body_ok = true
			var mat: = mi2.get_active_material(0)
			if mat is BaseMaterial3D \
			and (mat as BaseMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
				body_opaque = true
	if not body_ok:
		print("FAIL no full-body mesh AABB")
		quit(1)
		return
	if not body_opaque:
		print("FAIL body still has alpha transparency")
		quit(1)
		return
	print("SMOKE_REMOTE_AVATAR_SCALE_OK")
	quit(0)

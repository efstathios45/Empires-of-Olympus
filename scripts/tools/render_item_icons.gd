extends SceneTree
## Headless: render 256² icons from gear GLBs (transparent, studio lighting).

const OUT_DIR := "res://assets/ui/items/"
const SIZE := 256

const RENDERS := {
	"icon_xiphos.png": {"path": "res://assets/props/gear/xiphos_sword.glb", "extent": 0.95, "yaw": 40.0},
	"icon_machaira.png": {"path": "res://assets/props/gear/xiphos_sword.glb", "extent": 0.92, "yaw": -30.0, "tint": Color(1.08, 0.78, 0.55)},
	"icon_kontos.png": {"path": "res://assets/props/gear/kontos_spear.glb", "extent": 1.05, "yaw": 25.0},
	"icon_bow.png": {"path": "res://assets/props/weapons/cretan_bow.glb", "extent": 0.85, "yaw": 0.0},
	"icon_aspis.png": {"path": "res://assets/props/gear/aspis_shield.glb", "extent": 0.75, "yaw": 18.0},
	"icon_tower_shield.png": {"path": "res://assets/props/gear/tower_shield.glb", "extent": 0.82, "yaw": 12.0},
	"icon_corinthian_helm.png": {"path": "res://assets/props/gear/corinthian_helmet.glb", "extent": 0.42, "yaw": 30.0},
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := get_root()
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.05
	world.add_child(cam)
	await process_frame
	cam.position = Vector3(0.65, 0.28, 0.75)
	cam.look_at_from_position(cam.position, Vector3(0, 0.02, 0), Vector3.UP)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, 42, 0)
	key.light_energy = 1.45
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, -130, 0)
	fill.light_energy = 0.65
	world.add_child(fill)
	var pivot := Node3D.new()
	world.add_child(pivot)
	for fname in RENDERS.keys():
		var spec: Dictionary = RENDERS[fname]
		var glb: String = String(spec.get("path", ""))
		if not ResourceLoader.exists(glb):
			push_error("missing glb " + glb)
			quit(1)
			return
		for c in pivot.get_children():
			c.queue_free()
		await process_frame
		var inst: Node3D = load(glb).instantiate()
		pivot.add_child(inst)
		var ext := float(spec.get("extent", 0.9))
		ModelUtils.scale_to_max_extent(inst, ext)
		if spec.has("tint"):
			_tint_meshes(inst, spec["tint"])
		pivot.rotation_degrees = Vector3(-8, float(spec.get("yaw", 0.0)), 0)
		await process_frame
		await process_frame
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await process_frame
		var img: Image = vp.get_texture().get_image()
		var out_path: String = OUT_DIR + fname
		if img.save_png(out_path) != OK:
			push_error("save failed " + out_path)
			quit(1)
			return
	print("RENDER_ITEM_ICONS_OK ", RENDERS.size())
	quit(0)


func _tint_meshes(node: Node3D, tint: Color) -> void:
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := mi as MeshInstance3D
		if mesh == null:
			continue
		var base: Material = mesh.get_active_material(0)
		var mat := StandardMaterial3D.new()
		if base is StandardMaterial3D:
			mat = (base as StandardMaterial3D).duplicate()
		mat.albedo_color = mat.albedo_color * tint
		mesh.material_override = mat

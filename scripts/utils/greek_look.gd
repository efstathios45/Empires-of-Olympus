extends RefCounted
## Paint Quaternius modular humans to read as Hellenic — bronze, crimson,
## linen, olive — and hide modern/fantasy props (backpacks). Warriors get a
## procedural Corinthian helm (the stock GLB is an exploded placeholder).


const ROLE_COLORS := {
	## cuirass bronze / crimson tunic / olive leather / skin warm
	"hoplite": {
		"armor": Color(0.72, 0.55, 0.28),
		"cloth": Color(0.72, 0.16, 0.14),
		"leather": Color(0.42, 0.28, 0.16),
		"skin": Color(0.86, 0.68, 0.52),
		"metal": Color(0.78, 0.62, 0.35),
		"accent": Color(0.95, 0.88, 0.55),
	},
	"guard": {
		"armor": Color(0.65, 0.50, 0.26),
		"cloth": Color(0.55, 0.12, 0.12),
		"leather": Color(0.38, 0.26, 0.14),
		"skin": Color(0.84, 0.66, 0.50),
		"metal": Color(0.75, 0.60, 0.34),
		"accent": Color(0.9, 0.85, 0.5),
	},
	"smith": {
		"armor": Color(0.45, 0.42, 0.40),
		"cloth": Color(0.35, 0.28, 0.18),
		"leather": Color(0.40, 0.25, 0.12),
		"skin": Color(0.80, 0.60, 0.45),
		"metal": Color(0.55, 0.50, 0.45),
		"accent": Color(0.85, 0.55, 0.20),
	},
	"merchant": {
		"armor": Color(0.55, 0.45, 0.30),
		"cloth": Color(0.78, 0.70, 0.48),
		"leather": Color(0.40, 0.28, 0.16),
		"skin": Color(0.86, 0.70, 0.55),
		"metal": Color(0.70, 0.58, 0.35),
		"accent": Color(0.55, 0.35, 0.20),
	},
	"citizen": {
		"armor": Color(0.70, 0.65, 0.50),
		"cloth": Color(0.92, 0.88, 0.78),
		"leather": Color(0.45, 0.32, 0.18),
		"skin": Color(0.88, 0.72, 0.58),
		"metal": Color(0.75, 0.62, 0.40),
		"accent": Color(0.55, 0.35, 0.45),
	},
	"oracle": {
		"armor": Color(0.85, 0.78, 0.45),
		"cloth": Color(0.95, 0.93, 0.90),
		"leather": Color(0.55, 0.45, 0.25),
		"skin": Color(0.90, 0.75, 0.62),
		"metal": Color(0.90, 0.78, 0.35),
		"accent": Color(0.55, 0.35, 0.70),
	},
}


static func apply(model: Node3D, role: String = "citizen") -> void:
	if model == null:
		return
	_hide_anachronisms(model)
	var palette: Dictionary = ROLE_COLORS.get(role, ROLE_COLORS["citizen"])
	_paint_meshes(model, palette)
	if role in ["hoplite", "guard"]:
		_ensure_corinthian_helm(model)


static func _hide_anachronisms(model: Node3D) -> void:
	for n in model.find_children("*", "Node3D", true, false):
		var nm := String(n.name).to_lower()
		if "backpack" in nm or "pistol" in nm or "gun" in nm \
				or "hardhat" in nm or "hard_hat" in nm \
				or nm == "crown" or nm.ends_with("_crown"):
			n.visible = false
		if n is MeshInstance3D and "backpack" in nm:
			(n as MeshInstance3D).visible = false


static func _paint_meshes(model: Node3D, palette: Dictionary) -> void:
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var nm := String(mi.name).to_lower()
		if "backpack" in nm:
			mi.visible = false
			continue
		## Never recolor the procedural Corinthian (or inventory helm).
		if mi.get_parent() != null and "Corinthian" in String(mi.get_parent().name):
			continue
		if "corinthian" in nm or "helm_crest" in nm or "helm_cheek" in nm \
				or "helm_dome" in nm or "helm_nose" in nm:
			continue
		var key := "cloth"
		if "head" in nm:
			key = "skin"
		elif "feet" in nm or "boot" in nm:
			key = "leather"
		elif "pant" in nm or "leg" in nm:
			key = "cloth"
		elif "body" in nm:
			key = "armor"
		var col: Color = palette.get(key, palette["cloth"])
		var metal := 0.55 if key in ["armor", "metal"] else 0.05
		var rough := 0.45 if key in ["armor", "metal"] else 0.75
		## Non-warrior bodies read as linen / wool, not plate.
		if key == "armor" and not ("king" in nm or "adventurer" in nm or "soldier" in nm):
			if "witch" in nm or "formal" in nm or "casual" in nm \
					or "beach" in nm or "farmer" in nm or "worker" in nm \
					or "medieval" in nm:
				col = palette.get("cloth", col)
				metal = 0.04
				rough = 0.82
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.metallic = metal
		mat.roughness = rough
		var base: Material = mi.get_active_material(0)
		if base is StandardMaterial3D and (base as StandardMaterial3D).albedo_texture != null:
			mat.albedo_texture = (base as StandardMaterial3D).albedo_texture
			mat.albedo_color = col
		mi.material_override = mat


static func remove_corinthian_helm(model: Node3D) -> void:
	if model == null:
		return
	var helm := model.find_child("CorinthianHelmMount", true, false)
	if helm != null:
		helm.get_parent().remove_child(helm)
		helm.free()


static func _ensure_corinthian_helm(model: Node3D) -> void:
	if model.find_child("CorinthianHelmMount", true, false) != null:
		return
	if model.find_child("HelmetBone", true, false) != null:
		return
	var skel: Skeleton3D = null
	for node in model.find_children("*", "Skeleton3D", true, false):
		skel = node as Skeleton3D
		break
	if skel == null:
		return
	var bone := "Head"
	if skel.find_bone(bone) < 0:
		if skel.find_bone("head") >= 0:
			bone = "head"
		else:
			return
	var att := BoneAttachment3D.new()
	att.name = "CorinthianHelmMount"
	att.bone_name = bone
	skel.add_child(att)
	var helm := _build_corinthian_mesh()
	att.add_child(helm)


## Low-poly Corinthian: dome + cheek plates + nose + crimson crest.
## Sized for Quaternius modular heads (~0.35–0.4 m extent).
static func _build_corinthian_mesh() -> Node3D:
	var root := Node3D.new()
	root.name = "CorinthianHelm"
	## Sit above Quaternius Head bone so the dome covers hair, not the neck.
	root.position = Vector3(0.0, 0.08, 0.02)
	root.scale = Vector3(1.0, 1.0, 1.0)

	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color(0.74, 0.55, 0.28)
	bronze.metallic = 0.72
	bronze.roughness = 0.38

	var crest_mat := StandardMaterial3D.new()
	crest_mat.albedo_color = Color(0.78, 0.12, 0.12)
	crest_mat.roughness = 0.85
	crest_mat.metallic = 0.05

	## Skull dome
	var dome := MeshInstance3D.new()
	dome.name = "Helm_Dome"
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.22
	sphere.radial_segments = 10
	sphere.rings = 6
	dome.mesh = sphere
	dome.material_override = bronze
	dome.scale = Vector3(1.05, 0.85, 1.1)
	dome.position = Vector3(0.0, 0.02, 0.0)
	root.add_child(dome)

	## Brow / face bowl (slightly forward)
	var brow := MeshInstance3D.new()
	brow.name = "Helm_Brow"
	var brow_mesh := SphereMesh.new()
	brow_mesh.radius = 0.13
	brow_mesh.height = 0.18
	brow_mesh.radial_segments = 10
	brow_mesh.rings = 5
	brow.mesh = brow_mesh
	brow.material_override = bronze
	brow.scale = Vector3(1.0, 0.7, 0.85)
	brow.position = Vector3(0.0, -0.02, 0.04)
	root.add_child(brow)

	## Nose guard
	var nose := MeshInstance3D.new()
	nose.name = "Helm_Nose"
	var nose_box := BoxMesh.new()
	nose_box.size = Vector3(0.035, 0.12, 0.04)
	nose.mesh = nose_box
	nose.material_override = bronze
	nose.position = Vector3(0.0, -0.06, 0.13)
	root.add_child(nose)

	## Cheek plates
	for side in [-1.0, 1.0]:
		var cheek := MeshInstance3D.new()
		cheek.name = "Helm_Cheek_%s" % ("L" if side < 0.0 else "R")
		var cheek_box := BoxMesh.new()
		cheek_box.size = Vector3(0.05, 0.14, 0.1)
		cheek.mesh = cheek_box
		cheek.material_override = bronze
		cheek.position = Vector3(0.11 * side, -0.08, 0.06)
		cheek.rotation_degrees = Vector3(8.0, -18.0 * side, 6.0 * side)
		root.add_child(cheek)

	## Crimson horsehair crest
	var crest := MeshInstance3D.new()
	crest.name = "Helm_Crest"
	var crest_box := BoxMesh.new()
	crest_box.size = Vector3(0.04, 0.16, 0.28)
	crest.mesh = crest_box
	crest.material_override = crest_mat
	crest.position = Vector3(0.0, 0.16, -0.02)
	crest.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	root.add_child(crest)

	## Crest base ridge
	var ridge := MeshInstance3D.new()
	ridge.name = "Helm_CrestRidge"
	var ridge_box := BoxMesh.new()
	ridge_box.size = Vector3(0.03, 0.04, 0.22)
	ridge.mesh = ridge_box
	ridge.material_override = bronze
	ridge.position = Vector3(0.0, 0.1, -0.01)
	root.add_child(ridge)

	return root

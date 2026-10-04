extends RefCounted










const ROLE_COLORS: = {

	"hoplite": {
		"armor": Color(0.72, 0.55, 0.28), 
		"cloth": Color(0.72, 0.16, 0.14), 
		"leather": Color(0.42, 0.28, 0.16), 
		"skin": Color(0.86, 0.68, 0.52), 
		"metal": Color(0.78, 0.62, 0.35), 
		"accent": Color(0.95, 0.88, 0.55), 
		"hair": Color(0.25, 0.18, 0.12), 
	}, 
	"guard": {
		"armor": Color(0.65, 0.5, 0.26), 
		"cloth": Color(0.55, 0.12, 0.12), 
		"leather": Color(0.38, 0.26, 0.14), 
		"skin": Color(0.84, 0.66, 0.5), 
		"metal": Color(0.75, 0.6, 0.34), 
		"accent": Color(0.9, 0.85, 0.5), 
		"hair": Color(0.22, 0.16, 0.1), 
	}, 
	"smith": {
		"armor": Color(0.45, 0.42, 0.4), 
		"cloth": Color(0.35, 0.28, 0.18), 
		"leather": Color(0.4, 0.25, 0.12), 
		"skin": Color(0.8, 0.6, 0.45), 
		"metal": Color(0.55, 0.5, 0.45), 
		"accent": Color(0.85, 0.55, 0.2), 
		"hair": Color(0.2, 0.15, 0.1), 
	}, 
	"merchant": {
		"armor": Color(0.55, 0.45, 0.3), 
		"cloth": Color(0.78, 0.7, 0.48), 
		"leather": Color(0.4, 0.28, 0.16), 
		"skin": Color(0.86, 0.7, 0.55), 
		"metal": Color(0.7, 0.58, 0.35), 
		"accent": Color(0.55, 0.35, 0.2), 
		"hair": Color(0.28, 0.18, 0.1), 
	}, 
	"citizen": {
		"armor": Color(0.7, 0.65, 0.5), 
		"cloth": Color(0.92, 0.88, 0.78), 
		"leather": Color(0.45, 0.32, 0.18), 
		"skin": Color(0.88, 0.72, 0.58), 
		"metal": Color(0.75, 0.62, 0.4), 
		"accent": Color(0.55, 0.35, 0.45), 
		"hair": Color(0.3, 0.2, 0.12), 
	}, 
	"oracle": {
		"armor": Color(0.85, 0.78, 0.45), 
		"cloth": Color(0.95, 0.93, 0.9), 
		"leather": Color(0.55, 0.45, 0.25), 
		"skin": Color(0.9, 0.75, 0.62), 
		"metal": Color(0.9, 0.78, 0.35), 
		"accent": Color(0.55, 0.35, 0.7), 
		"hair": Color(0.85, 0.8, 0.7), 
	}, 
}


static func apply(model: Node3D, role: String = "citizen") -> void :
	if model == null:
		return
	_hide_anachronisms(model)
	var palette: Dictionary = ROLE_COLORS.get(role, ROLE_COLORS["citizen"])
	_paint_meshes(model, palette, role)
	if role in ["hoplite", "guard"]:
		_hide_stock_crown(model)
		_ensure_corinthian_helm(model)


static func _hide_anachronisms(model: Node3D) -> void :
	for n in model.find_children("*", "Node3D", true, false):
		var nm: = String(n.name).to_lower()
		if "backpack" in nm or "pistol" in nm or "gun" in nm\
		or "hardhat" in nm or "hard_hat" in nm\
		or nm == "crown" or nm.ends_with("_crown"):
			n.visible = false
		if n is MeshInstance3D and "backpack" in nm:
			(n as MeshInstance3D).visible = false




static func _hide_stock_crown(model: Node3D) -> void :
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi: = n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		if not ("head" in String(mi.name).to_lower()):
			continue
		for s in mi.mesh.get_surface_count():
			var mat: Material = mi.mesh.surface_get_material(s)
			var mname: = ""
			if mat != null:
				mname = String(mat.resource_name).to_lower()
				if mname == "" and mat is Resource:
					mname = String(mat.resource_path).get_file().to_lower()

			var active: Material = mi.get_active_material(s)
			var aname: = String(active.resource_name).to_lower() if active else ""
			if "gold" in mname or "gold" in aname or mname == "gold" or aname == "gold":
				var hide: = StandardMaterial3D.new()
				hide.albedo_color = Color(0, 0, 0, 0)
				hide.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				hide.cull_mode = BaseMaterial3D.CULL_DISABLED
				mi.set_surface_override_material(s, hide)


static func _paint_meshes(model: Node3D, palette: Dictionary, role: String) -> void :
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi: = n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var nm: = String(mi.name).to_lower()
		if "backpack" in nm:
			mi.visible = false
			continue

		if mi.get_parent() != null and "Corinthian" in String(mi.get_parent().name):
			continue
		if "corinthian" in nm or "helm_crest" in nm or "helm_cheek" in nm\
		or "helm_dome" in nm or "helm_nose" in nm:
			continue

		mi.material_override = null
		var surf_count: = mi.mesh.get_surface_count()
		if surf_count <= 0:
			continue

		if surf_count > 1 or _surface_has_named_mat(mi, 0):
			for s in range(surf_count):
				var key: = _surface_palette_key(mi, s, nm, role)
				if key == "hide":
					var hide: = StandardMaterial3D.new()
					hide.albedo_color = Color(0, 0, 0, 0)
					hide.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mi.set_surface_override_material(s, hide)
					continue
				mi.set_surface_override_material(s, _make_mat(palette, key))
		else:
			var key: = _mesh_name_palette_key(nm, role)
			mi.set_surface_override_material(0, _make_mat(palette, key))


static func _surface_has_named_mat(mi: MeshInstance3D, surface: int) -> bool:
	var mat: Material = mi.mesh.surface_get_material(surface)
	if mat == null:
		mat = mi.get_active_material(surface)
	return mat != null and String(mat.resource_name) != ""


static func _surface_mat_name(mi: MeshInstance3D, surface: int) -> String:
	var mat: Material = mi.mesh.surface_get_material(surface)
	if mat == null:
		mat = mi.get_active_material(surface)
	if mat == null:
		return ""
	return String(mat.resource_name).to_lower()


static func _surface_palette_key(mi: MeshInstance3D, surface: int, mesh_name: String, role: String) -> String:
	var mname: = _surface_mat_name(mi, surface)

	if mname == "gold" and ("head" in mesh_name) and role in ["hoplite", "guard"]:
		return "hide"
	if mname in ["skin"]:
		return "skin"
	if mname in ["blue", "beige", "darkbrown", "dark_brown"]:
		return "cloth"
	if mname in ["metal", "metal_dark", "metal dark"]:
		return "armor" if role in ["hoplite", "guard", "smith"] else "leather"
	if mname in ["gold"]:
		return "accent"
	if "hair" in mname:
		return "hair"
	if mname in ["eye"]:
		return "skin"

	return _mesh_name_palette_key(mesh_name, role)


static func _mesh_name_palette_key(nm: String, role: String) -> String:
	if "head" in nm:
		return "skin"
	if "feet" in nm or "boot" in nm:
		return "leather"
	if "pant" in nm or "leg" in nm:
		return "cloth"
	# Single-mesh Tripo greek_* casts (GreekGuardMesh, GreekOracleMesh, …)
	if "guard" in nm or "hoplite" in nm or "spartan" in nm:
		return "armor" if role in ["hoplite", "guard"] else "cloth"
	if "smith" in nm:
		return "leather"
	if "oracle" in nm or "priest" in nm:
		return "cloth"
	if "merchant" in nm:
		return "cloth"
	if "woman" in nm or "citizen" in nm:
		return "cloth"
	if "body" in nm:
		if role in ["hoplite", "guard"]:
			return "armor"
		return "cloth"
	# Role fallback for unnamed single meshes
	if role in ["hoplite", "guard"]:
		return "armor"
	if role == "smith":
		return "leather"
	return "cloth"


static func _make_mat(palette: Dictionary, key: String) -> StandardMaterial3D:
	var col: Color = palette.get(key, palette["cloth"])
	var metal: = 0.55 if key in ["armor", "metal", "accent"] else 0.05
	var rough: = 0.42 if key in ["armor", "metal", "accent"] else 0.78
	if key == "cloth":
		metal = 0.04
		rough = 0.82
	elif key == "skin":
		metal = 0.02
		rough = 0.72
	elif key == "leather":
		metal = 0.08
		rough = 0.8
	elif key == "hair":
		metal = 0.02
		rough = 0.88
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = metal
	mat.roughness = rough
	return mat


static func remove_corinthian_helm(model: Node3D) -> void :
	if model == null:
		return
	var helm: = model.find_child("CorinthianHelmMount", true, false)
	if helm != null:
		helm.get_parent().remove_child(helm)
		helm.free()


static func _ensure_corinthian_helm(model: Node3D) -> void :
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
	var bone: = "Head"
	if skel.find_bone(bone) < 0:
		if skel.find_bone("head") >= 0:
			bone = "head"
		else:
			return
	var att: = BoneAttachment3D.new()
	att.name = "CorinthianHelmMount"
	att.bone_name = bone
	skel.add_child(att)
	var helm: = _build_corinthian_mesh()
	att.add_child(helm)




static func _build_corinthian_mesh() -> Node3D:
	var root: = Node3D.new()
	root.name = "CorinthianHelm"

	root.position = Vector3(0.0, 0.06, 0.04)
	root.scale = Vector3(1.12, 1.12, 1.12)

	var bronze: = StandardMaterial3D.new()
	bronze.albedo_color = Color(0.74, 0.55, 0.28)
	bronze.metallic = 0.72
	bronze.roughness = 0.38

	var crest_mat: = StandardMaterial3D.new()
	crest_mat.albedo_color = Color(0.78, 0.12, 0.12)
	crest_mat.roughness = 0.85
	crest_mat.metallic = 0.05


	var dome: = MeshInstance3D.new()
	dome.name = "Helm_Dome"
	var sphere: = SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.24
	sphere.radial_segments = 10
	sphere.rings = 6
	dome.mesh = sphere
	dome.material_override = bronze
	dome.scale = Vector3(1.1, 0.9, 1.15)
	dome.position = Vector3(0.0, 0.03, 0.0)
	root.add_child(dome)


	var brow: = MeshInstance3D.new()
	brow.name = "Helm_Brow"
	var brow_mesh: = SphereMesh.new()
	brow_mesh.radius = 0.13
	brow_mesh.height = 0.18
	brow_mesh.radial_segments = 10
	brow_mesh.rings = 5
	brow.mesh = brow_mesh
	brow.material_override = bronze
	brow.scale = Vector3(1.0, 0.7, 0.85)
	brow.position = Vector3(0.0, -0.02, 0.04)
	root.add_child(brow)


	var nose: = MeshInstance3D.new()
	nose.name = "Helm_Nose"
	var nose_box: = BoxMesh.new()
	nose_box.size = Vector3(0.035, 0.12, 0.04)
	nose.mesh = nose_box
	nose.material_override = bronze
	nose.position = Vector3(0.0, -0.06, 0.13)
	root.add_child(nose)


	for side in [-1.0, 1.0]:
		var cheek: = MeshInstance3D.new()
		cheek.name = "Helm_Cheek_%s" % ("L" if side < 0.0 else "R")
		var cheek_box: = BoxMesh.new()
		cheek_box.size = Vector3(0.05, 0.14, 0.1)
		cheek.mesh = cheek_box
		cheek.material_override = bronze
		cheek.position = Vector3(0.11 * side, -0.08, 0.06)
		cheek.rotation_degrees = Vector3(8.0, -18.0 * side, 6.0 * side)
		root.add_child(cheek)


	var crest: = MeshInstance3D.new()
	crest.name = "Helm_Crest"
	var crest_box: = BoxMesh.new()
	crest_box.size = Vector3(0.04, 0.16, 0.28)
	crest.mesh = crest_box
	crest.material_override = crest_mat
	crest.position = Vector3(0.0, 0.16, -0.02)
	crest.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	root.add_child(crest)


	var ridge: = MeshInstance3D.new()
	ridge.name = "Helm_CrestRidge"
	var ridge_box: = BoxMesh.new()
	ridge_box.size = Vector3(0.03, 0.04, 0.22)
	ridge.mesh = ridge_box
	ridge.material_override = bronze
	ridge.position = Vector3(0.0, 0.1, -0.01)
	root.add_child(ridge)

	return root

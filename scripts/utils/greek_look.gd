extends RefCounted
## Paint Quaternius modular humans to read as Hellenic — bronze, crimson,
## linen, olive — and hide modern/fantasy props (backpacks). Warriors get a
## Corinthian helm that covers crowns.


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
		## Quaternius backpack is a MeshInstance3D under the skeleton.
		if n is MeshInstance3D and "backpack" in nm:
			(n as MeshInstance3D).visible = false


static func _paint_meshes(model: Node3D, palette: Dictionary) -> void:
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var nm := String(mi.name).to_lower()
		var parent_nm := String(mi.get_parent().name).to_lower() if mi.get_parent() else ""
		if "backpack" in nm:
			mi.visible = false
			continue
		var key := "cloth"
		if "head" in nm or "head" in parent_nm:
			key = "skin"
		elif "feet" in nm or "feet" in parent_nm or "boot" in nm:
			key = "leather"
		elif "pant" in nm or "leg" in nm or "leg" in parent_nm:
			key = "cloth"
		elif "body" in nm or "body" in parent_nm:
			## Warriors: bronze cuirass read. Civilians: linen chiton.
			key = "armor"
		var col: Color = palette.get(key, palette["cloth"])
		## Slight per-slot metalness for armor/metal.
		var metal := 0.55 if key in ["armor", "metal"] else 0.05
		var rough := 0.45 if key in ["armor", "metal"] else 0.75
		## Citizens / merchants / oracle: body reads as cloth not plate.
		if key == "armor" and not ("king" in nm or "adventurer" in nm or "soldier" in nm):
			## Soft linen / wool for non-warrior bodies.
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
		## Keep any albedo texture as a multiply tint if present.
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
	## Don't stack on an inventory-equipped helmet bone.
	if model.find_child("HelmetBone", true, false) != null:
		return
	var path := "res://assets/props/gear/corinthian_helmet.glb"
	if not ResourceLoader.exists(path):
		return
	var GearGrip = load("res://scripts/gear_grip.gd")
	if GearGrip == null:
		return
	var helm: Node3D = GearGrip.attach_helmet(model, path)
	if helm:
		helm.name = "CorinthianHelmMount"
		## Enlarge so it covers Quaternius crowns / modern hats.
		if helm.get_child_count() > 0:
			var holder := helm.get_child(0) as Node3D
			if holder:
				holder.scale *= 1.22
				holder.position.y += 0.03
				holder.position.z += 0.01
	var GearPaint = load("res://scripts/gear_paint.gd")
	if GearPaint and helm:
		GearPaint.paint_attached(helm, path)

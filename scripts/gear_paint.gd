extends RefCounted
## GearPaint — paint Kenney / procedural gear so it reads as Greek bronze,
## not flat white missing-texture placeholders.

const ASPIS_FACE := "res://assets/props/gear/aspis_face.png"
const TOWER_FACE := "res://assets/props/gear/tower_aspis_face.png"
const BRONZE := "res://assets/props/gear/bronze_metal.png"


## Apply a look based on the source GLB path (or item id hint).
static func paint_attached(root: Node3D, glb_path: String = "") -> void:
	if root == null:
		return
	var path := glb_path.to_lower()
	# Aspis often imports as flat grey in captures — stamp the bronze face.
	if path.find("aspis_shield") >= 0 or (path.find("aspis") >= 0 and path.find("tower") < 0):
		_paint_textured(root, ASPIS_FACE, Color(1, 1, 1), 0.55, 0.35)
		return
	if path.find("xiphos_sword") >= 0 or path.find("kontos_spear") >= 0:
		return
	if path.find("tower") >= 0:
		_paint_textured(root, TOWER_FACE, Color(1, 1, 1), 0.6, 0.25)
	elif path.find("xiphos") >= 0 or path.find("kontos") >= 0 or path.find("sword") >= 0 \
			or path.find("spear") >= 0 or path.find("knife") >= 0:
		_paint_textured(root, BRONZE, Color(0.92, 0.82, 0.55), 0.35, 0.55)
	elif path.find("helmet") >= 0 or path.find("helm") >= 0:
		_paint_solid(root, Color(0.72, 0.52, 0.22), 0.4, 0.65)
	else:
		# Generic bronze wash so nothing stays pure white.
		_paint_solid(root, Color(0.78, 0.62, 0.38), 0.55, 0.35)


static func _paint_textured(root: Node3D, tex_path: String, tint: Color, rough: float, metal: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	if ResourceLoader.exists(tex_path):
		mat.albedo_texture = load(tex_path)
	mat.roughness = rough
	mat.metallic = metal
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_apply(root, mat)


static func _paint_solid(root: Node3D, color: Color, rough: float, metal: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = metal
	_apply(root, mat)


static func _apply(root: Node3D, mat: Material) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi:
			mi.material_override = mat

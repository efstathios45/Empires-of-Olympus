class_name GearLook
## Applies readable bronze/painted materials to gear GLBs whose imports arrive
## untextured (pure white albedo). Used by ground loot and worn panoply.

const BRONZE := Color(0.78, 0.58, 0.28)
const STEEL := Color(0.72, 0.74, 0.78)
const LEATHER := Color(0.42, 0.28, 0.18)

const TEX := {
	"aspis": "res://assets/props/gear/aspis_face.png",
	"tower_shield": "res://assets/props/gear/tower_aspis_face.png",
	"xiphos": "res://assets/props/gear/xiphos_sword_0.png",
	"bronze_knife": "res://assets/props/gear/xiphos_sword_0.png",
	"kontos": "res://assets/props/gear/kontos_spear_0.png",
	"metal": "res://assets/props/gear/bronze_metal.png",
}


static func apply(root: Node, item_id: String = "") -> void:
	if root == null:
		return
	var albedo := _albedo_for(item_id)
	var tex_path := String(TEX.get(item_id, TEX["metal"]))
	var tex: Texture2D = null
	if tex_path != "" and ResourceLoader.exists(tex_path):
		tex = load(tex_path) as Texture2D
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var mat := StandardMaterial3D.new()
		mat.albedo_color = albedo
		if tex != null:
			mat.albedo_texture = tex
		mat.metallic = 0.65 if item_id != "leather_cuirass" else 0.05
		mat.roughness = 0.42 if item_id != "leather_cuirass" else 0.85
		mat.emission_enabled = true
		mat.emission = albedo * 0.22
		mat.emission_energy_multiplier = 0.35
		mi.material_override = mat


static func _albedo_for(item_id: String) -> Color:
	match item_id:
		"aspis", "tower_shield":
			return Color(0.82, 0.62, 0.28)
		"xiphos", "bronze_knife", "kontos":
			return STEEL
		"corinthian_helm":
			return BRONZE
		"leather_cuirass":
			return LEATHER
		"bronze_thorax":
			return BRONZE
		_:
			return BRONZE

class_name HeroAnim
extends RefCounted
## Maps the combat aliases player.gd asks for (idle, walk, attack, …)
## onto the clip names of whichever hero mesh is actually on screen.
## KayKit classes keep the ual1/ual2 library. The hoplite plays the clips
## authored on PS1/PSX Hoplite Chan.

const LOOPING := ["idle", "walk", "sprint", "block"]

const KAYKIT := {
	"idle": "ual1_Idle",
	"walk": "ual1_Walk",
	"sprint": "ual1_Sprint",
	"jump": "ual1_Jump",
	"dodge": "ual1_Roll",
	"block": "ual2_Sword_Block",
	"hit": "ual1_Hit_Chest",
	"death": "ual1_Death01",
	"skill": "ual1_Sword_Attack",
	"heavy": "ual2_Sword_Heavy_A",
	"attack_ranged": "ual1_Sword_Attack",
	"attack": ["ual2_Sword_Light_A", "ual2_Sword_Light_B", "ual2_Sword_Light_C"],
}

# Authored names, including the model's own typos (STANDIND, ATACK).
# There is no hit, death, jump, or dodge clip on this rig — those aliases
# stay empty and the player skips the missing playback.
const HOPLITE_CHAN := {
	"idle": "STANDIND STILL",
	"walk": "WALK 1",
	"sprint": "RUN EQUIPPED",
	"jump": "",
	"dodge": "",
	"block": "MARCH ON GUARD",
	"hit": "",
	"death": "",
	"skill": "DORY ATACK",
	"heavy": "XIPHOS side SLASH",
	"attack_ranged": "",
	"attack": ["DORY ATACK", "XIPHOS side SLASH"],
}


static func map_for(class_id: String) -> Dictionary:
	if class_id == "hoplite":
		return HOPLITE_CHAN
	return KAYKIT


static func clip(class_id: String, alias: String, index: int = 0) -> String:
	var entry: Variant = map_for(class_id).get(alias, "")
	if entry is Array:
		var names: Array = entry
		if names.is_empty():
			return ""
		return String(names[posmod(index, names.size())])
	return String(entry)


static func combo_count(class_id: String) -> int:
	var entry: Variant = map_for(class_id).get("attack", [])
	if entry is Array:
		return (entry as Array).size()
	return 1 if String(entry) != "" else 0


## One-shot the strikes; keep locomotion and the guard march looping.
## Runs after ModelUtils.set_animation_loops, which does not recognise
## the model's "ATACK" spelling.
static func apply_loops(anim: AnimationPlayer, class_id: String) -> void:
	if anim == null:
		return
	var profile := map_for(class_id)
	for alias in profile:
		var names: Array = []
		var entry: Variant = profile[alias]
		if entry is Array:
			names = entry
		elif String(entry) != "":
			names = [String(entry)]
		var looping: bool = alias in LOOPING
		for raw in names:
			var anim_name := String(raw)
			if not anim.has_animation(anim_name):
				continue
			var animation := anim.get_animation(anim_name)
			if animation == null:
				continue
			animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE


## PS1 albedo is a handful of texels. Nearest filtering keeps the pixels.
static func pixel_filter(model: Node) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(surface)
			if mat is BaseMaterial3D:
				var dup := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
				dup.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				mi.set_surface_override_material(surface, dup)


## First skinned mesh whose material name contains `token` (e.g. "DORY").
static func find_named_mesh(model: Node, token: String) -> MeshInstance3D:
	var needle := token.to_upper()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(surface)
			var mat_name := ""
			if mat:
				mat_name = mat.resource_name
			if needle in mat_name.to_upper() or needle in mi.name.to_upper():
				return mi
	return null

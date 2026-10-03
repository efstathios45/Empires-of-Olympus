@tool

const NATIVE_PATH = "res://addons/zylann.hterrain/native/"

const HT_ImageUtilsGeneric = preload("./image_utils_generic.gd")
const HT_QuadTreeLodGeneric = preload("./quad_tree_lod_generic.gd")





const _supported_os = {



}

const _supported_archs = ["x86_64"]


static func _supports_current_arch() -> bool:
	for arch in _supported_archs:

		if OS.has_feature(arch):
			return true
	return false


static func is_native_available() -> bool:
	if not _supports_current_arch():
		return false
	var os = OS.get_name()
	if not _supported_os.has(os):
		return false

	var v = Engine.get_version_info()
	return v.major == 4 and v.minor == 0


static func get_image_utils():
	if is_native_available():
		var HT_ImageUtilsNative = load(NATIVE_PATH + "image_utils.gdns")


		if HT_ImageUtilsNative != null:
			return HT_ImageUtilsNative.new()
	return HT_ImageUtilsGeneric.new()


static func get_quad_tree_lod():
	if is_native_available():
		var HT_QuadTreeLod = load(NATIVE_PATH + "quad_tree_lod.gdns")
		if HT_QuadTreeLod != null:
			return HT_QuadTreeLod.new()
	return HT_QuadTreeLodGeneric.new()

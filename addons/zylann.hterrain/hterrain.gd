@tool
extends Node3D

const HT_NativeFactory = preload("./native/factory.gd")
const HT_Mesher = preload("./hterrain_mesher.gd")
const HT_Grid = preload("./util/grid.gd")
const HTerrainData = preload("./hterrain_data.gd")
const HTerrainChunk = preload("./hterrain_chunk.gd")
const HTerrainChunkDebug = preload("./hterrain_chunk_debug.gd")
const HT_Util = preload("./util/util.gd")
const HTerrainCollider = preload("./hterrain_collider.gd")
const HTerrainTextureSet = preload("./hterrain_texture_set.gd")
const HT_Logger = preload("./util/logger.gd")

const SHADER_CLASSIC4 = "Classic4"
const SHADER_CLASSIC4_LITE = "Classic4Lite"
const SHADER_LOW_POLY = "LowPoly"
const SHADER_ARRAY = "Array"
const SHADER_MULTISPLAT16 = "MultiSplat16"
const SHADER_MULTISPLAT16_LITE = "MultiSplat16Lite"
const SHADER_CUSTOM = "Custom"

const MIN_MAP_SCALE = 0.01


const _SHADER_TYPE_HINT_STRING = \
"Classic4," + \
"Classic4Lite," + \
"LowPoly," + \
"Array," + \
"MultiSplat16," + \
"MultiSplat16Lite," + \
"Custom"











const _builtin_shaders = {
	SHADER_CLASSIC4: {
		path = "res://addons/zylann.hterrain/shaders/simple4.gdshader", 
		global_path = "res://addons/zylann.hterrain/shaders/simple4_global.gdshader"
	}, 
	SHADER_CLASSIC4_LITE: {
		path = "res://addons/zylann.hterrain/shaders/simple4_lite.gdshader", 
		global_path = "res://addons/zylann.hterrain/shaders/simple4_global.gdshader"
	}, 
	SHADER_LOW_POLY: {
		path = "res://addons/zylann.hterrain/shaders/low_poly.gdshader", 
		global_path = ""
	}, 
	SHADER_ARRAY: {
		path = "res://addons/zylann.hterrain/shaders/array.gdshader", 
		global_path = "res://addons/zylann.hterrain/shaders/array_global.gdshader"
	}, 
	SHADER_MULTISPLAT16: {
		path = "res://addons/zylann.hterrain/shaders/multisplat16.gdshader", 
		global_path = "res://addons/zylann.hterrain/shaders/multisplat16_global.gdshader"
	}, 
	SHADER_MULTISPLAT16_LITE: {
		path = "res://addons/zylann.hterrain/shaders/multisplat16_lite.gdshader", 
		global_path = "res://addons/zylann.hterrain/shaders/multisplat16_global.gdshader"
	}
}

const _NORMAL_BAKER_PATH = "res://addons/zylann.hterrain/tools/normalmap_baker.gd"
const _LOOKDEV_SHADER_PATH = "res://addons/zylann.hterrain/shaders/lookdev.gdshader"

const SHADER_PARAM_INVERSE_TRANSFORM = "u_terrain_inverse_transform"
const SHADER_PARAM_NORMAL_BASIS = "u_terrain_normal_basis"

const SHADER_PARAM_GROUND_PREFIX = "u_ground_"



const _api_shader_params = {
	"u_terrain_heightmap": true, 
	"u_terrain_normalmap": true, 
	"u_terrain_colormap": true, 
	"u_terrain_splatmap": true, 
	"u_terrain_splatmap_1": true, 
	"u_terrain_splatmap_2": true, 
	"u_terrain_splatmap_3": true, 
	"u_terrain_splat_index_map": true, 
	"u_terrain_splat_weight_map": true, 
	"u_terrain_globalmap": true, 

	"u_terrain_inverse_transform": true, 
	"u_terrain_normal_basis": true, 

	"u_ground_albedo_bump_0": true, 
	"u_ground_albedo_bump_1": true, 
	"u_ground_albedo_bump_2": true, 
	"u_ground_albedo_bump_3": true, 

	"u_ground_normal_roughness_0": true, 
	"u_ground_normal_roughness_1": true, 
	"u_ground_normal_roughness_2": true, 
	"u_ground_normal_roughness_3": true, 

	"u_ground_albedo_bump_array": true, 
	"u_ground_normal_roughness_array": true
}

const _api_shader_ground_albedo_params = {
	"u_ground_albedo_bump_0": true, 
	"u_ground_albedo_bump_1": true, 
	"u_ground_albedo_bump_2": true, 
	"u_ground_albedo_bump_3": true
}

const _ground_texture_array_shader_params = [
	"u_ground_albedo_bump_array", 
	"u_ground_normal_roughness_array"
]

const _splatmap_shader_params = [
	"u_terrain_splatmap", 
	"u_terrain_splatmap_1", 
	"u_terrain_splatmap_2", 
	"u_terrain_splatmap_3"
]

const MIN_CHUNK_SIZE = 16
const MAX_CHUNK_SIZE = 64



const _ground_enum_to_name = [
	"albedo_bump", 
	"normal_roughness"
]

const _DEBUG_AABB = false

signal transform_changed(global_transform)

@export_range(0.0, 1.0) var ambient_wind: float:
	get:
		return ambient_wind
	set(amplitude):
		if ambient_wind == amplitude:
			return
		ambient_wind = amplitude
		for layer in _detail_layers:
			layer.update_material()


@export_range(2, 5) var lod_scale: = 2.0:
	get:
		return _lodder.get_split_scale()
	set(value):
		_lodder.set_split_scale(value)






@export var map_scale: = Vector3(1, 1, 1):
	get:
		return map_scale
	set(p_map_scale):
		if map_scale == p_map_scale:
			return
		p_map_scale.x = maxf(p_map_scale.x, MIN_MAP_SCALE)
		p_map_scale.y = maxf(p_map_scale.y, MIN_MAP_SCALE)
		p_map_scale.z = maxf(p_map_scale.z, MIN_MAP_SCALE)
		map_scale = p_map_scale
		_on_transform_changed()


@export var centered: = false:
	get:
		return centered
	set(p_centered):
		if p_centered == centered:
			return
		centered = p_centered
		_on_transform_changed()


var _custom_shader: Shader = null
var _custom_globalmap_shader: Shader = null
var _shader_type: = SHADER_CLASSIC4_LITE
var _shader_uses_texture_array: = false
var _material: = ShaderMaterial.new()
var _material_params_need_update: = false

var _cast_shadow_setting: = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

var _render_layer_mask: = 1


var _ground_texture_count_cache: = 0

var _used_splatmaps_count_cache: = 0
var _is_using_indexed_splatmap: = false

var _texture_set: = HTerrainTextureSet.new()
var _texture_set_migration_textures = null

var _data: HTerrainData = null

var _mesher: = HT_Mesher.new()
var _lodder = HT_NativeFactory.get_quad_tree_lod()
var _viewer_pos_world: = Vector3()



var _chunks: = []
var _chunk_size: int = 32
var _pending_chunk_updates: = []

var _detail_layers: = []

var _collision_enabled: = true
var _collider: HTerrainCollider = null
var _collision_layer: = 1
var _collision_mask: = 1
var _physics_material: PhysicsMaterial = null


var _updated_chunks: = 0
var _logger = HT_Logger.get_for(self)


var _normals_baker = null

var _lookdev_enabled: = false
var _lookdev_material: ShaderMaterial


func _init():
	_logger.debug("Create HeightMap")


	_lodder.set_callbacks(_cb_make_chunk, _cb_recycle_chunk, _cb_get_vertical_bounds)

	set_notify_transform(true)



	_material.set_shader_parameter("u_ground_uv_scale", 20)
	_material.set_shader_parameter("u_ground_uv_scale_vec4", Color(20, 20, 20, 20))
	_material.set_shader_parameter("u_depth_blending", true)

	_material.shader = load(_builtin_shaders[_shader_type].path)

	_texture_set.changed.connect(_on_texture_set_changed)

	if _collision_enabled:
		if _check_heightmap_collider_support():
			_collider = HTerrainCollider.new(self, _collision_layer, _collision_mask)


func _get_property_list():


	var props = [
		{



			"name": "data_directory", 
			"type": TYPE_STRING, 
			"usage": PROPERTY_USAGE_EDITOR, 
			"hint": PROPERTY_HINT_DIR
		}, 
		{



			"name": "_terrain_data", 
			"type": TYPE_OBJECT, 
			"usage": PROPERTY_USAGE_STORAGE, 
			"hint": PROPERTY_HINT_RESOURCE_TYPE, 



			"hint_string": "HTerrainData"
		}, 
		{
			"name": "chunk_size", 
			"type": TYPE_INT, 
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE, 

			"hint_string": "16, 32"
		}, 
		{
			"name": "Collision", 
			"type": TYPE_NIL, 
			"usage": PROPERTY_USAGE_GROUP
		}, 
		{
			"name": "collision_enabled", 
			"type": TYPE_BOOL, 
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		}, 
		{
			"name": "collision_layer", 
			"type": TYPE_INT, 
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE, 
			"hint": PROPERTY_HINT_LAYERS_3D_PHYSICS
		}, 
		{
			"name": "collision_mask", 
			"type": TYPE_INT, 
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE, 
			"hint": PROPERTY_HINT_LAYERS_3D_PHYSICS
		}, 
		{
			"name": "physics_material", 
			"type": TYPE_OBJECT, 
			"usage": PROPERTY_USAGE_DEFAULT, 
			"hint": PROPERTY_HINT_RESOURCE_TYPE, 
			"hint_string": "PhysicsMaterial"
		}, 
		{
			"name": "Rendering", 
			"type": TYPE_NIL, 
			"usage": PROPERTY_USAGE_GROUP
		}, 
		{
			"name": "shader_type", 
			"type": TYPE_STRING, 
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE, 
			"hint": PROPERTY_HINT_ENUM, 
			"hint_string": _SHADER_TYPE_HINT_STRING
		}, 
		{
			"name": "custom_shader", 
			"type": TYPE_OBJECT, 
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE, 
			"hint": PROPERTY_HINT_RESOURCE_TYPE, 
			"hint_string": "Shader"
		}, 
		{
			"name": "custom_globalmap_shader", 
			"type": TYPE_OBJECT, 
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE, 
			"hint": PROPERTY_HINT_RESOURCE_TYPE, 
			"hint_string": "Shader"
		}, 
		{
			"name": "texture_set", 
			"type": TYPE_OBJECT, 
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE, 
			"hint": PROPERTY_HINT_RESOURCE_TYPE, 
			"hint_string": "Resource"




		}, 
		{
			"name": "render_layers", 
			"type": TYPE_INT, 
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE, 
			"hint": PROPERTY_HINT_LAYERS_3D_RENDER
		}, 
		{
			"name": "cast_shadow", 
			"type": TYPE_INT, 
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE, 
			"hint": PROPERTY_HINT_ENUM, 
			"hint_string": "Off,On,DoubleSided,ShadowsOnly"
		}
	]

	if _material.shader != null:
		var shader_params: = _material.shader.get_shader_uniform_list(true)
		for p in shader_params:
			if _api_shader_params.has(p.name):
				continue
			var cp: = {}
			for k in p:
				cp[k] = p[k]





















			if p.usage == PROPERTY_USAGE_GROUP:
				cp.name = "Rendering/" + cp.name
				cp.hint_string = "shader_params/"
			else:
				cp.name = str("shader_params/", p.name)
			props.append(cp)

	return props


func _get(key: StringName):
	if key == &"data_directory":
		return _get_data_directory()

	if key == &"_terrain_data":
		if _data == null or _data.resource_path == "":


			return null
		else:
			return _data

	if key == &"texture_set":
		return get_texture_set()

	elif key == &"shader_type":
		return get_shader_type()

	elif key == &"custom_shader":
		return get_custom_shader()

	elif key == &"custom_globalmap_shader":
		return _custom_globalmap_shader

	elif key.begins_with("shader_params/"):
		var param_name: = key.substr(len("shader_params/"))
		return get_shader_param(param_name)

	elif key == &"chunk_size":
		return _chunk_size

	elif key == &"collision_enabled":
		return _collision_enabled

	elif key == &"collision_layer":
		return _collision_layer

	elif key == &"collision_mask":
		return _collision_mask

	elif key == &"physics_material":
		return _physics_material

	elif key == &"render_layers":
		return get_render_layer_mask()

	elif key == &"cast_shadow":
		return _cast_shadow_setting


func _set(key: StringName, value):
	if key == &"data_directory":
		_set_data_directory(value)



	elif key == &"_terrain_data":
		set_data(value)

	elif key == &"texture_set":
		set_texture_set(value)


	var key_str: = String(key)
	if key_str.begins_with("ground/"):
		for ground_texture_type in HTerrainTextureSet.TYPE_COUNT:
			var type_name = _ground_enum_to_name[ground_texture_type]
			if key_str.begins_with(str("ground/", type_name, "_")):
				var i = key_str.substr(len(key_str) - 1).to_int()
				if _texture_set_migration_textures == null:
					_texture_set_migration_textures = []
				while i >= len(_texture_set_migration_textures):
					_texture_set_migration_textures.append([null, null])
				var texs = _texture_set_migration_textures[i]
				texs[ground_texture_type] = value

	elif key == &"shader_type":
		set_shader_type(value)

	elif key == &"custom_shader":
		set_custom_shader(value)

	elif key == &"custom_globalmap_shader":
		_custom_globalmap_shader = value

	elif key.begins_with("shader_params/"):
		var param_name: = String(key).substr(len("shader_params/"))
		set_shader_param(param_name, value)

	elif key == &"chunk_size":
		set_chunk_size(value)

	elif key == &"collision_enabled":
		set_collision_enabled(value)

	elif key == &"collision_layer":
		_collision_layer = value
		if _collider != null:
			_collider.set_collision_layer(value)

	elif key == &"collision_mask":
		_collision_mask = value
		if _collider != null:
			_collider.set_collision_mask(value)

	elif key == &"physics_material":
		set_physics_material(value)

	elif key == &"render_layers":
		return set_render_layer_mask(value)

	elif key == &"cast_shadow":
		set_cast_shadow(value)


func get_texture_set() -> HTerrainTextureSet:
	return _texture_set


func set_texture_set(new_set: HTerrainTextureSet):
	if _texture_set == new_set:
		return

	if _texture_set != null:

		_texture_set.changed.disconnect(_on_texture_set_changed)

	_texture_set = new_set

	if _texture_set != null:
		_texture_set.changed.connect(_on_texture_set_changed)

	_material_params_need_update = true


func _on_texture_set_changed():
	_material_params_need_update = true
	HT_Util.update_configuration_warning(self, false)


func get_shader_param(param_name: String):
	return HT_Util.get_shader_material_parameter(_material, param_name)


func set_shader_param(param_name: String, v):
	_material.set_shader_parameter(param_name, v)


func set_render_layer_mask(mask: int):
	_render_layer_mask = mask
	_for_all_chunks(HT_SetRenderLayerMaskAction.new(mask))


func get_render_layer_mask() -> int:
	return _render_layer_mask


func set_cast_shadow(setting: int):
	if setting == _cast_shadow_setting:
		return
	_cast_shadow_setting = setting
	_for_all_chunks(HT_SetCastShadowSettingAction.new(setting))


func get_cast_shadow() -> int:
	return _cast_shadow_setting


func _set_data_directory(dirpath: String):
	if dirpath != _get_data_directory():
		if dirpath == "":
			set_data(null)
		else:
			var fpath: = dirpath.path_join(HTerrainData.META_FILENAME)
			if FileAccess.file_exists(fpath):

				var d = load(fpath)
				if d == null:


					_logger.error("Could not load existing data: {}".format([fpath]))
				set_data(d)
			else:

				var d: = HTerrainData.new()
				d.resource_path = fpath
				set_data(d)








				d.save_data(fpath.get_base_dir())
	else:
		_logger.warn("Setting twice the same terrain directory??")


func _get_data_directory() -> String:
	if _data != null:
		return _data.resource_path.get_base_dir()
	return ""


func _check_heightmap_collider_support() -> bool:
	return true








func set_collision_enabled(enabled: bool):
	if _collision_enabled != enabled:
		_collision_enabled = enabled
		if _collision_enabled:
			if _check_heightmap_collider_support():
				_collider = HTerrainCollider.new(self, _collision_layer, _collision_mask)
				_collider.update_physics_material(_physics_material)







		else:


			_collider = null


func set_physics_material(new_physics_material: PhysicsMaterial) -> void :
	if new_physics_material == _physics_material:
		return

	if _physics_material != null:
		_physics_material.changed.disconnect(_on_physics_material_changed)

	_physics_material = new_physics_material

	if _physics_material != null:
		_physics_material.changed.connect(_on_physics_material_changed)

	_on_physics_material_changed()


func _on_physics_material_changed() -> void :
	if _collider != null:
		_collider.update_physics_material(_physics_material)


func _for_all_chunks(action):
	for lod in len(_chunks):
		var grid = _chunks[lod]
		for y in len(grid):
			var row = grid[y]
			for x in len(row):
				var chunk = row[x]
				if chunk != null:
					action.exec(chunk)


func get_chunk_size() -> int:
	return _chunk_size


func set_chunk_size(p_cs: int):
	assert (typeof(p_cs) == TYPE_INT)
	_logger.debug(str("Setting chunk size to ", p_cs))
	var cs: = HT_Util.next_power_of_two(p_cs)
	if cs < MIN_CHUNK_SIZE:
		cs = MIN_CHUNK_SIZE
	if cs > MAX_CHUNK_SIZE:
		cs = MAX_CHUNK_SIZE
	if p_cs != cs:
		_logger.debug(str("Chunk size snapped to ", cs))
	if cs == _chunk_size:
		return
	_chunk_size = cs
	_reset_ground_chunks()



func set_map_scale(p_map_scale: Vector3):
	map_scale = p_map_scale



func set_centered(p_centered: bool):
	centered = p_centered





func get_internal_transform() -> Transform3D:
	var gt: = global_transform
	var it: = Transform3D(gt.basis * Basis().scaled(map_scale), gt.origin)
	if centered and _data != null:
		var half_size: = 0.5 * (_data.get_resolution() - 1.0)
		it.origin += it.basis * ( - Vector3(half_size, 0, half_size))
	return it


func get_internal_transform_unscaled():
	var gt: = global_transform
	if centered and _data != null:
		var half_size: = 0.5 * (_data.get_resolution() - 1.0)

		gt.origin += gt.basis * ( - Vector3(half_size, 0, half_size) * map_scale)
	return gt




func world_to_map(world_pos: Vector3) -> Vector3:
	return get_internal_transform().affine_inverse() * world_pos


func _notification(what: int):
	match what:
		NOTIFICATION_PREDELETE:
			_logger.debug("Destroy HTerrain")

			_clear_all_chunks()

		NOTIFICATION_ENTER_WORLD:
			_logger.debug("Enter world")

			if _texture_set_migration_textures != null and _texture_set.get_slots_count() == 0:





				_texture_set.set_mode(HTerrainTextureSet.MODE_TEXTURES)
				while _texture_set.get_slots_count() < len(_texture_set_migration_textures):
					_texture_set.insert_slot(-1)
				for slot_index in len(_texture_set_migration_textures):
					var texs = _texture_set_migration_textures[slot_index]
					for type in len(texs):
						_texture_set.set_texture(slot_index, type, texs[type])
				_texture_set_migration_textures = null

			_for_all_chunks(HT_EnterWorldAction.new(get_world_3d()))
			if _collider != null:
				_collider.set_world(get_world_3d())
				_collider.set_transform(get_internal_transform())

		NOTIFICATION_EXIT_WORLD:
			_logger.debug("Exit world")
			_for_all_chunks(HT_ExitWorldAction.new())
			if _collider != null:
				_collider.set_world(null)

		NOTIFICATION_TRANSFORM_CHANGED:
			_on_transform_changed()

		NOTIFICATION_VISIBILITY_CHANGED:
			_logger.debug("Visibility changed")
			_for_all_chunks(HT_VisibilityChangedAction.new(is_visible_in_tree()))


func _on_transform_changed():
	_logger.debug("Transform changed")

	if not is_inside_tree():


		return

	var gt = get_internal_transform()

	_for_all_chunks(HT_TransformChangedAction.new(gt))

	_material_params_need_update = true

	if _collider != null:
		_collider.set_transform(gt)

	transform_changed.emit(gt)


func _enter_tree():
	_logger.debug("Enter tree")

	if Engine.is_editor_hint() and _normals_baker == null:
		_normals_baker = load(_NORMAL_BAKER_PATH).new()
		add_child(_normals_baker)
		_normals_baker.set_terrain_data(_data)

	set_process(true)


func _clear_all_chunks():

	_lodder.clear()



	for i in len(_chunks):
		_chunks[i].clear()


func _get_chunk_at(pos_x: int, pos_y: int, lod: int) -> HTerrainChunk:
	if lod < len(_chunks):
		return HT_Grid.grid_get_or_default(_chunks[lod], pos_x, pos_y, null)
	return null


func get_data() -> HTerrainData:
	return _data


func has_data() -> bool:
	return _data != null


func set_data(new_data: HTerrainData):
	assert (new_data == null or new_data is HTerrainData)

	_logger.debug(str("Set new data ", new_data))

	if _data == new_data:
		return

	if has_data():
		_logger.debug("Disconnecting old HeightMapData")
		_data.resolution_changed.disconnect(_on_data_resolution_changed)
		_data.region_changed.disconnect(_on_data_region_changed)
		_data.map_changed.disconnect(_on_data_map_changed)
		_data.map_added.disconnect(_on_data_map_added)
		_data.map_removed.disconnect(_on_data_map_removed)

		if _normals_baker != null:
			_normals_baker.set_terrain_data(null)
			_normals_baker.queue_free()
			_normals_baker = null

	_data = new_data


	_clear_all_chunks()

	if has_data():
		_logger.debug("Connecting new HeightMapData")


		if is_inside_tree() and Engine.is_editor_hint():
			if _data.get_resolution() == 0:
				_data._edit_load_default()

		if _collider != null:
			_collider.create_from_terrain_data(_data)

		_data.resolution_changed.connect(_on_data_resolution_changed)
		_data.region_changed.connect(_on_data_region_changed)
		_data.map_changed.connect(_on_data_map_changed)
		_data.map_added.connect(_on_data_map_added)
		_data.map_removed.connect(_on_data_map_removed)

		if _normals_baker != null:
			_normals_baker.set_terrain_data(_data)

		_on_data_resolution_changed()

	_material_params_need_update = true

	HT_Util.update_configuration_warning(self, true)

	_logger.debug("Set data done")





func update_collider():
	assert (_collision_enabled)
	assert (_collider != null)
	_data.check_images()
	_collider.create_from_terrain_data(_data)


func _on_data_resolution_changed():
	_reset_ground_chunks()

	for layer in _detail_layers:
		layer.on_heightmap_resolution_changed()


func _reset_ground_chunks():
	if _data == null:
		return

	_clear_all_chunks()

	_pending_chunk_updates.clear()

	_lodder.create_from_sizes(_chunk_size, _data.get_resolution())

	_chunks.resize(_lodder.get_lod_count())

	var cres: = _data.get_resolution() / _chunk_size
	var csize_x: = cres
	var csize_y: = cres

	for lod in _lodder.get_lod_count():
		_logger.debug(str("Create grid for lod ", lod, ", ", csize_x, "x", csize_y))
		var grid = HT_Grid.create_grid(csize_x, csize_y)
		_chunks[lod] = grid
		csize_x /= 2
		csize_y /= 2

	_mesher.configure(_chunk_size, _chunk_size, _lodder.get_lod_count())


func _on_data_region_changed(min_x, min_y, size_x, size_y, channel):

	if channel == HTerrainData.CHANNEL_HEIGHT:
		set_area_dirty(min_x, min_y, size_x, size_y)

		if _normals_baker != null:
			_normals_baker.request_tiles_in_region(Vector2(min_x, min_y), Vector2(size_x, size_y))

		for layer in _detail_layers:
			layer.on_heightmap_region_changed(Rect2i(min_x, min_y, size_x, size_y))


func _on_data_map_changed(type: int, index: int):
	if type == HTerrainData.CHANNEL_DETAIL\
	or type == HTerrainData.CHANNEL_HEIGHT\
	or type == HTerrainData.CHANNEL_NORMAL\
	or type == HTerrainData.CHANNEL_GLOBAL_ALBEDO:

		for layer in _detail_layers:
			layer.update_material()

	if type != HTerrainData.CHANNEL_DETAIL:
		_material_params_need_update = true


func _on_data_map_added(type: int, index: int):
	if type == HTerrainData.CHANNEL_DETAIL:
		for layer in _detail_layers:

			if layer.layer_index >= index:
				layer.layer_index += 1
			layer.update_material()
	else:
		_material_params_need_update = true
	HT_Util.update_configuration_warning(self, true)


func _on_data_map_removed(type: int, index: int):
	if type == HTerrainData.CHANNEL_DETAIL:
		for layer in _detail_layers:

			if layer.layer_index > index:
				layer.layer_index -= 1
			layer.update_material()
	else:
		_material_params_need_update = true
	HT_Util.update_configuration_warning(self, true)


func get_shader_type() -> String:
	return _shader_type


func set_shader_type(type: String):
	if type == _shader_type:
		return
	_shader_type = type

	if _shader_type == SHADER_CUSTOM:
		_material.shader = _custom_shader
	else:
		_material.shader = load(_builtin_shaders[_shader_type].path)

	_material_params_need_update = true

	if Engine.is_editor_hint():
		notify_property_list_changed()


func get_custom_shader() -> Shader:
	return _custom_shader


func set_custom_shader(shader: Shader):
	if _custom_shader == shader:
		return

	if _custom_shader != null:
		_custom_shader.changed.disconnect(_on_custom_shader_changed)

	if Engine.is_editor_hint() and shader != null and is_inside_tree():

		if shader.code.is_empty():
			_logger.debug("Populating custom shader with default code")
			var src: = _material.shader
			if src == null:
				src = load(_builtin_shaders[SHADER_CLASSIC4].path)
			shader.code = src.code



	_custom_shader = shader

	if _shader_type == SHADER_CUSTOM:
		_material.shader = _custom_shader

	if _custom_shader != null:
		_custom_shader.changed.connect(_on_custom_shader_changed)
		if _shader_type == SHADER_CUSTOM:
			_material_params_need_update = true

	if Engine.is_editor_hint():
		notify_property_list_changed()


func _on_custom_shader_changed():
	_material_params_need_update = true
	notify_property_list_changed()


func _update_material_params():
	assert (_material != null)
	_logger.debug("Updating terrain material params")

	var terrain_textures: = {}
	var res: = Vector2(-1, -1)

	var lookdev_material: ShaderMaterial
	if _lookdev_enabled:
		lookdev_material = _get_lookdev_material()



	if has_data():
		for map_type in HTerrainData.CHANNEL_COUNT:
			var count: = _data.get_map_count(map_type)
			for i in count:
				var param_name: String = HTerrainData.get_map_shader_param_name(map_type, i)
				terrain_textures[param_name] = _data.get_texture(map_type, i)
		res.x = _data.get_resolution()
		res.y = res.x



	if is_inside_tree():
		var gt: = get_internal_transform()
		var t: = gt.affine_inverse()
		_material.set_shader_parameter(SHADER_PARAM_INVERSE_TRANSFORM, t)


		var normal_basis = gt.basis.inverse().transposed()
		_material.set_shader_parameter(SHADER_PARAM_NORMAL_BASIS, normal_basis)

		if lookdev_material != null:
			lookdev_material.set_shader_parameter(SHADER_PARAM_INVERSE_TRANSFORM, t)
			lookdev_material.set_shader_parameter(SHADER_PARAM_NORMAL_BASIS, normal_basis)

	for param_name in terrain_textures:
		var tex = terrain_textures[param_name]
		_material.set_shader_parameter(param_name, tex)
		if lookdev_material != null:
			lookdev_material.set_shader_parameter(param_name, tex)

	if _texture_set != null:
		match _texture_set.get_mode():
			HTerrainTextureSet.MODE_TEXTURES:
				var slots_count: = _texture_set.get_slots_count()
				for type in HTerrainTextureSet.TYPE_COUNT:
					for slot_index in slots_count:
						var texture: = _texture_set.get_texture(slot_index, type)
						var shader_param: = _get_ground_texture_shader_param_name(type, slot_index)
						_material.set_shader_parameter(shader_param, texture)

			HTerrainTextureSet.MODE_TEXTURE_ARRAYS:
				for type in HTerrainTextureSet.TYPE_COUNT:
					var texture_array: = _texture_set.get_texture_array(type)
					var shader_params: = _get_ground_texture_array_shader_param_name(type)
					_material.set_shader_parameter(shader_params, texture_array)

	_shader_uses_texture_array = false
	_is_using_indexed_splatmap = false
	_used_splatmaps_count_cache = 0

	var shader: = _material.shader
	if shader != null:
		var param_list: = RenderingServer.get_shader_parameter_list(shader.get_rid())
		_ground_texture_count_cache = 0
		for p in param_list:
			if _api_shader_ground_albedo_params.has(p.name):
				_ground_texture_count_cache += 1
			elif p.name == "u_ground_albedo_bump_array":
				_shader_uses_texture_array = true
			elif p.name == "u_terrain_splat_index_map":
				_is_using_indexed_splatmap = true
			elif p.name in _splatmap_shader_params:
				_used_splatmaps_count_cache += 1






func is_using_texture_array() -> bool:
	return _shader_uses_texture_array





func get_used_splatmaps_count() -> int:
	return _used_splatmaps_count_cache





func is_using_indexed_splatmap() -> bool:
	return _is_using_indexed_splatmap


static func _get_common_shader_params(shader1: Shader, shader2: Shader) -> Array:
	var shader1_param_names: = {}
	var common_params: = []

	var shader1_params: = RenderingServer.get_shader_parameter_list(shader1.get_rid())
	var shader2_params: = RenderingServer.get_shader_parameter_list(shader2.get_rid())

	for p in shader1_params:
		shader1_param_names[p.name] = true

	for p in shader2_params:
		if shader1_param_names.has(p.name):
			common_params.append(p.name)

	return common_params



func setup_globalmap_material(mat: ShaderMaterial):
	mat.shader = get_globalmap_shader()
	if mat.shader == null:
		_logger.error("Could not find a shader to use for baking the global map.")
		return

	var common_params = _get_common_shader_params(mat.shader, _material.shader)
	for param_name in common_params:
		var v = _material.get_shader_parameter(param_name)
		mat.set_shader_parameter(param_name, v)



func get_globalmap_shader() -> Shader:
	if _shader_type == SHADER_CUSTOM:
		if _custom_globalmap_shader != null:
			return _custom_globalmap_shader
		_logger.warn("The terrain uses a custom shader but doesn't have one for baking the "
			+ "global map. Will attempt to use a built-in shader.")
		if is_using_texture_array():
			return load(_builtin_shaders[SHADER_ARRAY].global_path) as Shader
		return load(_builtin_shaders[SHADER_CLASSIC4].global_path) as Shader
	return load(_builtin_shaders[_shader_type].global_path) as Shader



func set_lod_scale(p_lod_scale: float):
	lod_scale = p_lod_scale



func get_lod_scale() -> float:
	return lod_scale


func get_lod_count() -> int:
	return _lodder.get_lod_count()








const s_dirs = [
	[-1, 0], 
	[1, 0], 
	[0, -1], 
	[0, 1]
]










const s_rdirs = [
	[-1, 0], 
	[-1, 1], 
	[0, 2], 
	[1, 2], 
	[2, 1], 
	[2, 0], 
	[1, -1], 
	[0, -1]
]


func _edit_update_viewer_position(camera: Camera3D):
	_update_viewer_position(camera)


func _update_viewer_position(camera: Camera3D):
	if camera == null:
		var viewport: = get_viewport()
		if viewport != null:
			camera = viewport.get_camera_3d()

	if camera == null:
		return

	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:




		var cam_pos: = camera.global_transform.origin
		var cam_dir: = - camera.global_transform.basis.z
		var max_distance: = camera.far * 1.2
		var hit_cell_pos = cell_raycast(cam_pos, cam_dir, max_distance)

		if hit_cell_pos != null:
			var cell_to_world: = get_internal_transform()
			var h: = _data.get_height_at(hit_cell_pos.x, hit_cell_pos.y)
			_viewer_pos_world = cell_to_world * Vector3(hit_cell_pos.x, h, hit_cell_pos.y)

	else:
		_viewer_pos_world = camera.global_transform.origin


func _process(delta: float):
	if not Engine.is_editor_hint():

		_update_viewer_position(null)

	if has_data():
		if _data.is_locked():

			return

		if _data.get_resolution() != 0:
			var gt: = get_internal_transform()

			var viewer_pos_heightmap_local: = gt.affine_inverse() * _viewer_pos_world

			_lodder.update(viewer_pos_heightmap_local)




		if _data.get_map_count(HTerrainData.CHANNEL_DETAIL) > 0:


			for layer in _detail_layers:
				layer.process(delta, _viewer_pos_world)

	_updated_chunks = 0





	var precount = _pending_chunk_updates.size()
	for i in precount:
		var u: HT_PendingChunkUpdate = _pending_chunk_updates[i]


		for d in 4:
			var ncpos_x = u.pos_x + s_dirs[d][0]
			var ncpos_y = u.pos_y + s_dirs[d][1]

			var nchunk: = _get_chunk_at(ncpos_x, ncpos_y, u.lod)
			if nchunk != null and nchunk.is_active():


				_add_chunk_update(nchunk, ncpos_x, ncpos_y, u.lod)


		if u.lod > 0:
			var cpos_upper_x: = u.pos_x * 2
			var cpos_upper_y: = u.pos_y * 2
			var nlod: = u.lod - 1

			for rd in 8:
				var ncpos_upper_x = cpos_upper_x + s_rdirs[rd][0]
				var ncpos_upper_y = cpos_upper_y + s_rdirs[rd][1]

				var nchunk: = _get_chunk_at(ncpos_upper_x, ncpos_upper_y, nlod)
				if nchunk != null and nchunk.is_active():
					_add_chunk_update(nchunk, ncpos_upper_x, ncpos_upper_y, nlod)


	var lvisible: = is_visible_in_tree()
	for i in len(_pending_chunk_updates):
		var u: HT_PendingChunkUpdate = _pending_chunk_updates[i]
		var chunk: = _get_chunk_at(u.pos_x, u.pos_y, u.lod)
		assert (chunk != null)
		_update_chunk(chunk, u.lod, lvisible and chunk.is_active())
		_updated_chunks += 1

	_pending_chunk_updates.clear()

	if _material_params_need_update:
		_update_material_params()
		HT_Util.update_configuration_warning(self, false)
		_material_params_need_update = false






func _update_chunk(chunk: HTerrainChunk, lod: int, p_visible: bool):
	assert (has_data())


	var seams: = 0
	var cpos_x: = chunk.cell_origin_x / (_chunk_size << lod)
	var cpos_y: = chunk.cell_origin_y / (_chunk_size << lod)
	var cpos_lower_x: = cpos_x / 2
	var cpos_lower_y: = cpos_y / 2


	for d in 4:
		var ncpos_lower_x = (cpos_x + s_dirs[d][0]) / 2
		var ncpos_lower_y = (cpos_y + s_dirs[d][1]) / 2
		if ncpos_lower_x != cpos_lower_x or ncpos_lower_y != cpos_lower_y:
			var nchunk: = _get_chunk_at(ncpos_lower_x, ncpos_lower_y, lod + 1)
			if nchunk != null and nchunk.is_active():
				seams |= (1 << d)

	var mesh: = _mesher.get_chunk(lod, seams)
	chunk.set_mesh(mesh)



	var s: = _chunk_size << lod
	var aabb: = _data.get_region_aabb(chunk.cell_origin_x, chunk.cell_origin_y, s, s)
	aabb.position.x = 0
	aabb.position.z = 0
	chunk.set_aabb(aabb)

	chunk.set_visible(p_visible)
	chunk.set_pending_update(false)


func _add_chunk_update(chunk: HTerrainChunk, pos_x: int, pos_y: int, lod: int):
	if chunk.is_pending_update():

		return

	assert (lod < len(_chunks))
	assert (pos_x >= 0)
	assert (pos_y >= 0)
	assert (pos_y < len(_chunks[lod]))
	assert (pos_x < len(_chunks[lod][pos_y]))


	var u: = HT_PendingChunkUpdate.new()
	u.pos_x = pos_x
	u.pos_y = pos_y
	u.lod = lod
	_pending_chunk_updates.push_back(u)

	chunk.set_pending_update(true)






func set_area_dirty(origin_in_cells_x: int, origin_in_cells_y: int, \
size_in_cells_x: int, size_in_cells_y: int):

	var cpos0_x: = origin_in_cells_x / _chunk_size
	var cpos0_y: = origin_in_cells_y / _chunk_size
	var csize_x: = (size_in_cells_x - 1) / _chunk_size + 1
	var csize_y: = (size_in_cells_y - 1) / _chunk_size + 1


	for lod in _lodder.get_lod_count():

		var grid = _chunks[lod]
		var s: int = _lodder.get_lod_factor(lod)



		var min_x: = cpos0_x / s
		var min_y: = cpos0_y / s
		var max_x: = (cpos0_x + csize_x - 1) / s + 1
		var max_y: = (cpos0_y + csize_y - 1) / s + 1


		for cy in range(min_y, max_y):
			for cx in range(min_x, max_x):
				var chunk = HT_Grid.grid_get_or_default(grid, cx, cy, null)
				if chunk != null and chunk.is_active():
					_add_chunk_update(chunk, cx, cy, lod)



func _cb_make_chunk(cpos_x: int, cpos_y: int, lod: int):

	var chunk: = _get_chunk_at(cpos_x, cpos_y, lod)

	if chunk == null:


		var lod_factor: int = _lodder.get_lod_factor(lod)
		var origin_in_cells_x: = cpos_x * _chunk_size * lod_factor
		var origin_in_cells_y: = cpos_y * _chunk_size * lod_factor

		var material = _material
		if _lookdev_enabled:
			material = _get_lookdev_material()

		if _DEBUG_AABB:
			chunk = HTerrainChunkDebug.new(
				self, origin_in_cells_x, origin_in_cells_y, material)
		else:
			chunk = HTerrainChunk.new(self, origin_in_cells_x, origin_in_cells_y, material)
		chunk.parent_transform_changed(get_internal_transform())

		chunk.set_render_layer_mask(_render_layer_mask)
		chunk.set_cast_shadow_setting(_cast_shadow_setting)

		var grid = _chunks[lod]
		var row = grid[cpos_y]
		row[cpos_x] = chunk


	_add_chunk_update(chunk, cpos_x, cpos_y, lod)

	chunk.set_active(true)
	return chunk



func _cb_recycle_chunk(chunk: HTerrainChunk, cx: int, cy: int, lod: int):
	chunk.set_visible(false)
	chunk.set_active(false)


func _cb_get_vertical_bounds(cpos_x: int, cpos_y: int, lod: int):
	var chunk_size: int = _chunk_size * _lodder.get_lod_factor(lod)
	var origin_in_cells_x: = cpos_x * chunk_size
	var origin_in_cells_y: = cpos_y * chunk_size



	return _data.get_point_aabb(
		origin_in_cells_x + chunk_size / 2, 
		origin_in_cells_y + chunk_size / 2)















func cell_raycast(origin_world: Vector3, dir_world: Vector3, max_distance: float):
	assert (typeof(origin_world) == TYPE_VECTOR3)
	assert (typeof(dir_world) == TYPE_VECTOR3)
	if not has_data():
		return null

	var to_local: = get_internal_transform().affine_inverse()
	var origin = to_local * origin_world
	var dir = to_local.basis * dir_world
	return _data.cell_raycast(origin, dir, max_distance)


static func _get_ground_texture_shader_param_name(ground_texture_type: int, slot: int) -> String:
	assert (typeof(slot) == TYPE_INT and slot >= 0)
	_check_ground_texture_type(ground_texture_type)
	return str(SHADER_PARAM_GROUND_PREFIX, _ground_enum_to_name[ground_texture_type], "_", slot)



func get_ground_texture(slot: int, type: int) -> Texture:
	_logger.error(
		"HTerrain.get_ground_texture is obsolete, " + 
		"use HTerrain.get_texture_set().get_texture(slot, type) instead")
	var shader_param = _get_ground_texture_shader_param_name(type, slot)
	return _material.get_shader_parameter(shader_param)



func set_ground_texture(slot: int, type: int, tex: Texture):
	_logger.error(
		"HTerrain.set_ground_texture is obsolete, " + 
		"use HTerrain.get_texture_set().set_texture(slot, type, texture) instead")
	assert (tex == null or tex is Texture)
	var shader_param: = _get_ground_texture_shader_param_name(type, slot)
	_material.set_shader_parameter(shader_param, tex)


func _get_ground_texture_array_shader_param_name(type: int) -> String:
	return _ground_texture_array_shader_params[type] as String



func get_ground_texture_array(type: int) -> TextureLayered:
	_logger.error(
		"HTerrain.get_ground_texture_array is obsolete, " + 
		"use HTerrain.get_texture_set().get_texture_array(type) instead")
	var param_name: = _get_ground_texture_array_shader_param_name(type)
	return _material.get_shader_parameter(param_name)



func set_ground_texture_array(type: int, texture_array: TextureLayered):
	_logger.error(
		"HTerrain.set_ground_texture_array is obsolete, " + 
		"use HTerrain.get_texture_set().set_texture_array(type, texarray) instead")
	var param_name: = _get_ground_texture_array_shader_param_name(type)
	_material.set_shader_parameter(param_name, texture_array)


func _internal_add_detail_layer(layer):
	assert (_detail_layers.find(layer) == -1)
	_detail_layers.append(layer)


func _internal_remove_detail_layer(layer):
	assert (_detail_layers.find(layer) != -1)
	_detail_layers.erase(layer)




func get_detail_layers() -> Array:
	return _detail_layers.duplicate()



func set_detail_texture(slot, tex):
	_logger.error(
		"HTerrain.set_detail_texture is obsolete, use HTerrainDetailLayer.texture instead")



func get_detail_texture(slot):
	_logger.error(
		"HTerrain.get_detail_texture is obsolete, use HTerrainDetailLayer.texture instead")



func set_ambient_wind(amplitude: float):
	ambient_wind = amplitude


static func _check_ground_texture_type(ground_texture_type: int):
	assert (typeof(ground_texture_type) == TYPE_INT)
	assert (ground_texture_type >= 0 and ground_texture_type < HTerrainTextureSet.TYPE_COUNT)



func get_ground_texture_slot_count() -> int:
	_logger.error("get_ground_texture_slot_count is obsolete, "\
	+ "use get_cached_ground_texture_slot_count instead")
	return get_max_ground_texture_slot_count()


func get_max_ground_texture_slot_count() -> int:
	_logger.error("get_ground_texture_slot_count is obsolete, "\
	+ "use get_cached_ground_texture_slot_count instead")
	return get_cached_ground_texture_slot_count()





func get_cached_ground_texture_slot_count() -> int:
	return _ground_texture_count_cache


func _edit_debug_draw(ci: CanvasItem):
	_lodder.debug_draw_tree(ci)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: = PackedStringArray()

	if _data == null:
		warnings.append("""The terrain is missing data.
""" + "Select the `Data Directory` property in the inspector to assign it.")

	else:
		var heightmap: = _data.get_image(HTerrainData.CHANNEL_HEIGHT)
		if heightmap.get_format() == Image.FORMAT_RH:


			warnings.append(
				"The heightmap uses a legacy format (RH), which might cause suboptimal authoring.\n"
				+ "You may convert it to RF by exporting it to 32-bit EXR, then import it back.\n"
				+ "You can also use a script to convert \"height.res\" (Image resource)")

	if _texture_set == null:
		warnings.append("""The terrain does not have a HTerrainTextureSet assigned
""" + "This is required if you want to paint textures on it.")

	else:
		var mode: = _texture_set.get_mode()

		if mode == HTerrainTextureSet.MODE_TEXTURES and is_using_texture_array():
			warnings.append("""The current shader needs texture arrays,
""" + "but the current HTerrainTextureSet is setup with individual textures.\n"\
			+ "You may need to switch it to TEXTURE_ARRAYS mode,\n"\
			+ "or re-import images in this mode with the import tool.")

		elif mode == HTerrainTextureSet.MODE_TEXTURE_ARRAYS and not is_using_texture_array():
			warnings.append("""The current shader needs individual textures,
""" + "but the current HTerrainTextureSet is setup with texture arrays.\n"\
			+ "You may need to switch it to TEXTURES mode,\n"\
			+ "or re-import images in this mode with the import tool.")


	return warnings


func set_lookdev_enabled(enable: bool):
	if _lookdev_enabled == enable:
		return
	_lookdev_enabled = enable
	_material_params_need_update = true
	if _lookdev_enabled:
		_for_all_chunks(HT_SetMaterialAction.new(_get_lookdev_material()))
	else:
		_for_all_chunks(HT_SetMaterialAction.new(_material))


func set_lookdev_shader_param(param_name: String, value):
	var mat = _get_lookdev_material()
	mat.set_shader_parameter(param_name, value)


func is_lookdev_enabled() -> bool:
	return _lookdev_enabled


func _get_lookdev_material() -> ShaderMaterial:
	if _lookdev_material == null:
		_lookdev_material = ShaderMaterial.new()
		_lookdev_material.shader = load(_LOOKDEV_SHADER_PATH)
	return _lookdev_material


class HT_PendingChunkUpdate:
	var pos_x: = 0
	var pos_y: = 0
	var lod: = 0


class HT_EnterWorldAction:
	var world: World3D = null
	func _init(w):
		world = w
	func exec(chunk):
		chunk.enter_world(world)


class HT_ExitWorldAction:
	func exec(chunk):
		chunk.exit_world()


class HT_TransformChangedAction:
	var transform: Transform3D
	func _init(t):
		transform = t
	func exec(chunk):
		chunk.parent_transform_changed(transform)


class HT_VisibilityChangedAction:
	var visible: = false
	func _init(v):
		visible = v
	func exec(chunk):
		chunk.set_visible(visible and chunk.is_active())







class HT_SetMaterialAction:
	var material: Material = null
	func _init(m):
		material = m
	func exec(chunk):
		chunk.set_material(material)


class HT_SetRenderLayerMaskAction:
	var mask: int = 0
	func _init(m: int):
		mask = m
	func exec(chunk):
		chunk.set_render_layer_mask(mask)


class HT_SetCastShadowSettingAction:
	var setting: = 0
	func _init(s: int):
		setting = s
	func exec(chunk):
		chunk.set_cast_shadow_setting(setting)

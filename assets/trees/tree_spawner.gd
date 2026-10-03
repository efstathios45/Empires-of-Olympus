class_name TreeForest
extends Node3D


























const FOREST_VARIANTS: = 4
const LOD_UPDATE_INTERVAL: = 0.2
const MIN_SPACING: = 4.0
const CLEARING_RADIUS: = 9.0






static func build_tree(
		params: Dictionary, atlas_cells: int, 
		leaf_mat: Material, bark_mat: Material
	) -> Node3D:
	var root: = Node3D.new()
	root.name = "Tree"
	var result: Dictionary = TreeFactory.build(params, atlas_cells)

	var trunk: = MeshInstance3D.new()
	trunk.name = "TreeTrunk"
	trunk.mesh = result["wood"]
	trunk.material_override = bark_mat
	root.add_child(trunk)

	var leaves: = MeshInstance3D.new()
	leaves.name = "TreeLeaves"
	leaves.mesh = result["leaves"]
	leaves.material_override = leaf_mat

	leaves.extra_cull_margin = 8.0
	root.add_child(leaves)

	return root



static func spawn_tree(
		parent: Node, params: Dictionary, atlas_cells: int, 
		leaf_mat: Material, bark_mat: Material, 
		xform: Transform3D = Transform3D.IDENTITY
	) -> Node3D:
	var t: = build_tree(params, atlas_cells, leaf_mat, bark_mat)
	parent.add_child(t)
	t.transform = xform
	return t





static func make_leaf_material(
		shader: Shader, atlas: Texture2D, overrides: Dictionary = {}
	) -> ShaderMaterial:
	var mat: = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("leaf_atlas", atlas)
	for k in overrides.keys():
		mat.set_shader_parameter(k, overrides[k])
	return mat




const BARK_SHADER: Shader = preload("res://assets/trees/bark_dissolve.gdshader")





static func make_bark_material(
		bark_color: Color, bark_texture: Texture2D = null
	) -> ShaderMaterial:
	var mat: = ShaderMaterial.new()
	mat.shader = BARK_SHADER
	mat.set_shader_parameter("bark_color", bark_color)
	if bark_texture != null:
		mat.set_shader_parameter("bark_texture", bark_texture)
		mat.set_shader_parameter("use_texture", true)
	return mat




var params: Dictionary = {}
var atlas_cells: int = 2
var leaf_material: Material = null
var bark_material: Material = null
var variant_jitter: Dictionary = {}
var tree_count: int = 120
var forest_radius: float = 80.0
var scale_jitter: float = 0.25
var lod_distance: float = 55.0



var lod_blend_band: float = 24.0
var cast_leaf_shadows: bool = true
var seed: int = 1337

var _variants: Array = []
var _lod_accum: float = 0.0
var _built: bool = false



func setup(
		p_params: Dictionary, p_atlas_cells: int, 
		p_leaf_material: Material, p_bark_material: Material, 
		p_count: int, p_radius: float, opts: Dictionary = {}
	) -> TreeForest:
	params = p_params
	atlas_cells = p_atlas_cells
	leaf_material = p_leaf_material
	bark_material = p_bark_material
	tree_count = p_count
	forest_radius = p_radius
	variant_jitter = opts.get("variant_jitter", {})
	scale_jitter = opts.get("scale_jitter", scale_jitter)
	lod_distance = opts.get("lod_distance", lod_distance)
	lod_blend_band = opts.get("lod_blend_band", lod_blend_band)
	cast_leaf_shadows = opts.get("cast_leaf_shadows", cast_leaf_shadows)
	seed = int(opts.get("seed", params.get("seed", seed)))
	return self


func build() -> void :
	_clear()
	var rng: = RandomNumberGenerator.new()
	rng.seed = seed * 31 + 7

	var positions: = _scatter_positions(rng)

	var aabb_pad: float = forest_radius + 30.0
	var big_aabb: = AABB(
		Vector3( - aabb_pad, -10.0, - aabb_pad), 
		Vector3(aabb_pad * 2.0, 90.0, aabb_pad * 2.0))

	for vi in range(FOREST_VARIANTS):
		var vparams: Dictionary = _jitter_params(params, rng)
		vparams["seed"] = rng.randi() % 1000000
		var res: Dictionary = TreeFactory.build(vparams, atlas_cells)



		var far_params: Dictionary = vparams.duplicate()
		far_params["leaves_per_cluster"] = minf(
			3.0, maxf(2.0, float(vparams.get("leaves_per_cluster", 5.0))))
		far_params["leaf_card_size"] = float(vparams.get("leaf_card_size", 1.4)) * 1.25
		far_params["cluster_radius"] = float(vparams.get("cluster_radius", 0.8)) * 1.1
		var far_res: Dictionary = TreeFactory.build(far_params, atlas_cells)
		var trunk_impostor: ArrayMesh = TreeFactory.build_trunk_impostor(vparams)

		var xforms: Array[Transform3D] = []
		var i: int = vi
		while i < positions.size():
			var yaw: float = rng.randf() * TAU
			var sc: float = 1.0 + rng.randf_range( - scale_jitter, scale_jitter)
			var basis: = Basis(Vector3.UP, yaw).scaled(Vector3(sc, sc, sc))
			xforms.append(Transform3D(basis, positions[i]))
			i += FOREST_VARIANTS

		var near_wood_mmi: = _make_mmi("WoodNear%d" % vi, res["wood"], bark_material, big_aabb, true)
		var far_wood_mmi: = _make_mmi("WoodFar%d" % vi, trunk_impostor, bark_material, big_aabb, false)
		var near_mmi: = _make_mmi("LeavesNear%d" % vi, res["leaves"], leaf_material, big_aabb, cast_leaf_shadows)
		var far_mmi: = _make_mmi("LeavesFar%d" % vi, far_res["leaves"], leaf_material, big_aabb, false)
		_variants.append({
			"xforms": xforms, 
			"near_wood": near_wood_mmi, 
			"far_wood": far_wood_mmi, 
			"near": near_mmi, 
			"far": far_mmi, 
		})

	_built = true
	_update_lod()


func _process(delta: float) -> void :
	if not _built:
		return
	_lod_accum += delta
	if _lod_accum > LOD_UPDATE_INTERVAL:
		_lod_accum = 0.0
		_update_lod()


func _scatter_positions(rng: RandomNumberGenerator) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var attempts: int = 0
	var min_sq: float = MIN_SPACING * MIN_SPACING
	while positions.size() < tree_count and attempts < tree_count * 40:
		attempts += 1
		var a: float = rng.randf() * TAU
		var r: float = forest_radius * sqrt(rng.randf())
		var pos: = Vector3(cos(a) * r, 0.0, sin(a) * r)
		if pos.length() < CLEARING_RADIUS:
			continue
		var ok: = true
		for q in positions:
			if q.distance_squared_to(pos) < min_sq:
				ok = false
				break
		if ok:
			positions.append(pos)
	return positions


func _jitter_params(base: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var out: Dictionary = base.duplicate()
	for key in variant_jitter.keys():
		if not base.has(key):
			continue
		var pct: float = float(variant_jitter[key])
		out[key] = float(base[key]) * (1.0 + rng.randf_range( - pct, pct))
	return out


func _make_mmi(
		mmi_name: String, mesh: Mesh, mat: Material, 
		custom_aabb: AABB, shadows: bool
	) -> MultiMeshInstance3D:
	var mmi: = MultiMeshInstance3D.new()
	mmi.name = mmi_name
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows\
	else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = custom_aabb
	var mm: = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D


	mm.use_custom_data = true
	mm.mesh = mesh
	mmi.multimesh = mm
	add_child(mmi)
	return mmi


func _fill_mmi(mmi: MultiMeshInstance3D, xforms: Array, blends: Array, is_far: bool) -> void :
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = xforms.size()
	var tier: float = 1.0 if is_far else 0.0
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])


		mm.set_instance_custom_data(i, Color(float(blends[i]), tier, 1.0, 0.0))


func _update_lod() -> void :
	var cam: = get_viewport().get_camera_3d()
	if cam == null:
		return
	var cam_pos: = cam.global_position
	var near_limit: float = lod_distance + lod_blend_band * 0.5
	var far_limit: float = maxf(lod_distance - lod_blend_band * 0.5, 0.0)
	var band: float = maxf(near_limit - far_limit, 0.001)
	for v in _variants:
		var near_xf: Array[Transform3D] = []
		var near_b: Array[float] = []
		var far_xf: Array[Transform3D] = []
		var far_b: Array[float] = []
		for xf in (v["xforms"] as Array):
			var dist: float = (xf as Transform3D).origin.distance_to(cam_pos)


			var blend: float = clampf((near_limit - dist) / band, 0.0, 1.0)





			if dist < near_limit:
				near_xf.append(xf)
				near_b.append(blend)
			if dist > far_limit:
				far_xf.append(xf)
				far_b.append(blend)
		_fill_mmi(v["near_wood"], near_xf, near_b, false)
		_fill_mmi(v["far_wood"], far_xf, far_b, true)
		_fill_mmi(v["near"], near_xf, near_b, false)
		_fill_mmi(v["far"], far_xf, far_b, true)


func _clear() -> void :
	for c in get_children():
		c.queue_free()
	_variants.clear()
	_built = false

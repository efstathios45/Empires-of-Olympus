class_name TreeFactory
extends Object















const DEFAULTS: = {
	"seed": 1337, 
	"trunk_height": 6.0, 
	"trunk_radius": 0.35, 
	"taper": 0.45, 
	"levels": 3, 
	"branches_per_level": 4, 
	"branch_angle_deg": 42.0, 
	"length_ratio": 0.62, 
	"radius_ratio": 0.58, 
	"gnarl": 0.25, 
	"upward_bias": 0.3, 
	"segments_per_branch": 5, 
	"radial_segments": 6, 
	"branch_start": 0.35, 
	"branch_mode": 0, 
	"length_falloff": 0.0, 
	"droop": 0.0, 
	"cluster_along": 0.0, 
	"cluster_flatten": 0.0, 
	"leaf_card_size": 1.5, 
	"leaf_size_jitter": 0.35, 
	"leaves_per_cluster": 7, 
	"cluster_radius": 0.9, 
}

const MAX_BRANCHES: = 1400


static func build(params: Dictionary, atlas_cells: int) -> Dictionary:
	var p: Dictionary = DEFAULTS.duplicate()
	for k in params.keys():
		p[k] = params[k]

	var rng: = RandomNumberGenerator.new()
	rng.seed = int(p["seed"])

	var branches: Array = []
	var clusters: Array = []
	var state: = {"budget": MAX_BRANCHES}
	_grow(branches, clusters, p, rng, state, 
		Vector3.ZERO, Vector3.UP, 
		float(p["trunk_height"]), float(p["trunk_radius"]), 0)

	var wood: ArrayMesh = _build_wood_mesh(branches, p)
	var leaves: ArrayMesh = _build_leaf_mesh(clusters, p, atlas_cells, rng)

	var centers: = PackedVector3Array()
	for c in clusters:
		centers.append(c["center"])

	return {
		"wood": wood, 
		"leaves": leaves, 
		"branch_count": branches.size(), 
		"cluster_count": clusters.size(), 
		"cluster_centers": centers, 
	}




static func _grow(
		branches: Array, clusters: Array, p: Dictionary, 
		rng: RandomNumberGenerator, state: Dictionary, 
		origin: Vector3, dir: Vector3, 
		length: float, radius: float, level: int
	) -> void :
	if state["budget"] <= 0:
		return
	state["budget"] = int(state["budget"]) - 1

	var seg_count: int = maxi(2, int(p["segments_per_branch"]))
	var step: float = length / float(seg_count)
	var gnarl: float = float(p["gnarl"])
	var up_bias: float = float(p["upward_bias"])
	var droop: float = float(p["droop"])

	var pts: = PackedVector3Array()
	var radii: = PackedFloat32Array()
	var pos: = origin
	var d: = dir.normalized()
	var tip_r: float = radius * float(p["taper"])
	pts.append(pos)
	radii.append(radius)
	for i in range(seg_count):
		var t: float = float(i + 1) / float(seg_count)
		var bend: = Vector3(
			rng.randf_range(-1.0, 1.0), 
			rng.randf_range(-1.0, 1.0), 
			rng.randf_range(-1.0, 1.0)
		).normalized()


		var droop_amt: float = 0.0 if level == 0 else droop * 0.3 * t
		d = (d + bend * gnarl * 0.35 + Vector3.UP * up_bias * 0.16
			+ Vector3.DOWN * droop_amt).normalized()
		pos += d * step
		pts.append(pos)
		radii.append(lerpf(radius, tip_r, t))

	branches.append({"points": pts, "radii": radii, "level": level})

	var levels: int = int(p["levels"])
	if level < levels:
		var n: int = maxi(1, int(p["branches_per_level"]))
		var b_start: float = clampf(float(p["branch_start"]), 0.05, 0.9)
		var whorled: bool = int(p["branch_mode"]) == 1

		if whorled and level == 0:


			var per_whorl: int = 5
			for w in range(n):
				var t: float = lerpf(b_start, 0.95, 
					float(w) / maxf(float(n - 1), 1.0))
				var base_az: float = rng.randf() * TAU
				for j in range(per_whorl):
					var az: float = base_az + TAU * float(j) / float(per_whorl)\
					+ rng.randf_range(-0.25, 0.25)
					_spawn_child(branches, clusters, p, rng, state, 
						pts, radius, tip_r, length, level, t, az)
		else:


			var n_eff: int = mini(n, 3) if whorled else n
			for k in range(n_eff):
				var t: float = lerpf(b_start, 0.97, 
					(float(k) + rng.randf() * 0.8) / float(n_eff))
				_spawn_child(branches, clusters, p, rng, state, 
					pts, radius, tip_r, length, level, t, rng.randf() * TAU)


	var leaf_start: int = maxi(1, levels - 1)
	if level >= leaf_start:
		clusters.append({"center": pts[pts.size() - 1]})
		if level == levels and rng.randf() < 0.55:
			clusters.append({"center": _sample_spline(pts, 0.55)})

		var along: float = clampf(float(p["cluster_along"]), 0.0, 1.0)
		if along > 0.0:
			for tt in [0.35, 0.6, 0.8]:
				if rng.randf() < along:
					clusters.append({"center": _sample_spline(pts, tt)})


static func _spawn_child(
		branches: Array, clusters: Array, p: Dictionary, 
		rng: RandomNumberGenerator, state: Dictionary, 
		pts: PackedVector3Array, radius: float, tip_r: float, 
		length: float, level: int, t: float, azimuth: float
	) -> void :
	var attach_pos: Vector3 = _sample_spline(pts, t)
	var attach_dir: Vector3 = _sample_tangent(pts, t)
	var attach_r: float = lerpf(radius, tip_r, t)

	var perp: = _any_perpendicular(attach_dir)
	var axis: = perp.rotated(attach_dir, azimuth).normalized()
	var angle: float = deg_to_rad(float(p["branch_angle_deg"])
		* rng.randf_range(0.75, 1.25))
	var child_dir: = attach_dir.rotated(axis, angle)


	var falloff: float = clampf(float(p["length_falloff"]), 0.0, 0.95)
	var len_scale: float = lerpf(1.0, 1.0 - falloff, t)
	var child_len: float = length * float(p["length_ratio"])\
	* rng.randf_range(0.75, 1.15) * maxf(len_scale, 0.12)
	var child_r: float = maxf(attach_r * float(p["radius_ratio"]), 0.01)
	_grow(branches, clusters, p, rng, state, 
		attach_pos, child_dir, child_len, child_r, level + 1)


static func _sample_spline(pts: PackedVector3Array, t: float) -> Vector3:
	var f: float = clampf(t, 0.0, 1.0) * float(pts.size() - 1)
	var i: int = mini(int(f), pts.size() - 2)
	return pts[i].lerp(pts[i + 1], f - float(i))


static func _sample_tangent(pts: PackedVector3Array, t: float) -> Vector3:
	var f: float = clampf(t, 0.0, 1.0) * float(pts.size() - 1)
	var i: int = mini(int(f), pts.size() - 2)
	return (pts[i + 1] - pts[i]).normalized()


static func _any_perpendicular(v: Vector3) -> Vector3:
	var ref: = Vector3.RIGHT if absf(v.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	return v.cross(ref).normalized()




static func _build_wood_mesh(branches: Array, p: Dictionary) -> ArrayMesh:
	var st: = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radial: int = clampi(int(p["radial_segments"]), 3, 12)

	for b in branches:
		var pts: PackedVector3Array = b["points"]
		var radii: PackedFloat32Array = b["radii"]
		var ring_count: int = pts.size()


		var rings: Array = []
		var u: = _any_perpendicular((pts[1] - pts[0]).normalized())
		for i in range(ring_count):
			var tangent: Vector3
			if i == 0:
				tangent = (pts[1] - pts[0]).normalized()
			elif i == ring_count - 1:
				tangent = (pts[i] - pts[i - 1]).normalized()
			else:
				tangent = (pts[i + 1] - pts[i - 1]).normalized()
			u = (u - tangent * u.dot(tangent)).normalized()
			var v: = tangent.cross(u).normalized()
			var ring: = PackedVector3Array()
			for k in range(radial):
				var a: float = TAU * float(k) / float(radial)
				ring.append(pts[i] + (u * cos(a) + v * sin(a)) * radii[i])
			rings.append(ring)


		for i in range(ring_count - 1):
			var ra: PackedVector3Array = rings[i]
			var rb: PackedVector3Array = rings[i + 1]
			var va: float = float(i) / float(ring_count - 1)
			var vb: float = float(i + 1) / float(ring_count - 1)
			for k in range(radial):
				var k2: int = (k + 1) % radial
				var ua: float = float(k) / float(radial)
				var ub: float = float(k + 1) / float(radial)
				_quad(st, 
					ra[k], Vector2(ua, va), 
					ra[k2], Vector2(ub, va), 
					rb[k2], Vector2(ub, vb), 
					rb[k], Vector2(ua, vb))


		var last_ring: PackedVector3Array = rings[ring_count - 1]
		var tip_dir: = (pts[ring_count - 1] - pts[ring_count - 2]).normalized()
		var tip: = pts[ring_count - 1] + tip_dir * radii[ring_count - 1] * 1.5
		for k in range(radial):
			var k2: int = (k + 1) % radial
			st.set_uv(Vector2(0.5, 1.0))
			st.add_vertex(last_ring[k])
			st.set_uv(Vector2(0.5, 1.0))
			st.add_vertex(tip)
			st.set_uv(Vector2(0.5, 1.0))
			st.add_vertex(last_ring[k2])

	st.generate_normals()
	return st.commit()


static func _quad(
		st: SurfaceTool, 
		p0: Vector3, uv0: Vector2, p1: Vector3, uv1: Vector2, 
		p2: Vector3, uv2: Vector2, p3: Vector3, uv3: Vector2
	) -> void :

	st.set_uv(uv0);st.add_vertex(p0)
	st.set_uv(uv2);st.add_vertex(p2)
	st.set_uv(uv1);st.add_vertex(p1)
	st.set_uv(uv0);st.add_vertex(p0)
	st.set_uv(uv3);st.add_vertex(p3)
	st.set_uv(uv2);st.add_vertex(p2)




const CARD_CORNERS: Array[Vector2] = [
	Vector2(-0.5, -0.5), Vector2(0.5, -0.5), 
	Vector2(0.5, 0.5), Vector2(-0.5, 0.5), 
]
const CARD_TRIS: Array[int] = [0, 1, 2, 0, 2, 3]






static func build_impostor(
		centers: PackedVector3Array, atlas_cells: int, 
		rng: RandomNumberGenerator, card_count: int = 14
	) -> ArrayMesh:
	if centers.is_empty():
		return ArrayMesh.new()

	var lo: Vector3 = centers[0]
	var hi: Vector3 = centers[0]
	for c in centers:
		lo.x = minf(lo.x, c.x);lo.y = minf(lo.y, c.y);lo.z = minf(lo.z, c.z)
		hi.x = maxf(hi.x, c.x);hi.y = maxf(hi.y, c.y);hi.z = maxf(hi.z, c.z)
	var center: Vector3 = (lo + hi) * 0.5
	var radius: float = maxf(maxf(hi.x - lo.x, hi.z - lo.z) * 0.5, 1.0)
	var height: float = maxf(hi.y - lo.y, 1.0)
	var y_min: float = lo.y
	var y_span: float = maxf(hi.y - lo.y, 0.001)
	var cells: int = maxi(1, atlas_cells)
	var inset: float = 0.94

	var st: = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for _i in range(card_count):
		var pos: = center + Vector3(
			rng.randf_range(-1.0, 1.0) * radius * 0.85, 
			rng.randf_range(-0.5, 0.5) * height * 0.7, 
			rng.randf_range(-1.0, 1.0) * radius * 0.85)
		var size: float = radius * rng.randf_range(1.35, 1.85)
		var height_t: float = clampf((pos.y - y_min) / y_span, 0.0, 1.0)
		var phase: float = rng.randf()
		var roll: float = rng.randf()
		var depth_key: float = rng.randf()
		var cell: int = rng.randi_range(0, cells * cells - 1)
		var cx: int = cell % cells
		var cy: int = floori(float(cell) / float(cells))
		for idx in CARD_TRIS:
			var corner: Vector2 = CARD_CORNERS[idx]
			var uv: = Vector2(
				(float(cx) + 0.5 + corner.x * inset) / float(cells), 
				(float(cy) + 0.5 - corner.y * inset) / float(cells))
			st.set_uv(uv)
			st.set_uv2(corner * size)
			st.set_color(Color(phase, height_t, roll, depth_key))
			st.set_normal(Vector3.UP)
			st.add_vertex(pos)
	return st.commit()





static func build_trunk_impostor(params: Dictionary) -> ArrayMesh:
	var p: Dictionary = DEFAULTS.duplicate()
	for k in params.keys():
		p[k] = params[k]

	var height: float = float(p["trunk_height"]) * 0.85
	var base_r: float = maxf(float(p["trunk_radius"]) * 1.15, 0.06)
	var top_r: float = base_r * 0.32
	var radial: = 5

	var st: = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var base: = PackedVector3Array()
	var top: = PackedVector3Array()
	for k in range(radial):
		var a: float = TAU * float(k) / float(radial)
		var dir: = Vector3(cos(a), 0.0, sin(a))
		base.append(dir * base_r)
		top.append(Vector3(0.0, height, 0.0) + dir * top_r)

	for k in range(radial):
		var k2: int = (k + 1) % radial
		var u0: float = float(k) / float(radial)
		var u1: float = float(k + 1) / float(radial)
		_quad(st, 
			base[k], Vector2(u0, 0.0), 
			base[k2], Vector2(u1, 0.0), 
			top[k2], Vector2(u1, 1.0), 
			top[k], Vector2(u0, 1.0))

	st.generate_normals()
	return st.commit()


static func _build_leaf_mesh(
		clusters: Array, p: Dictionary, atlas_cells: int, 
		rng: RandomNumberGenerator
	) -> ArrayMesh:
	if clusters.is_empty():
		return ArrayMesh.new()

	var y_min: float = INF
	var y_max: float = - INF
	for c in clusters:
		var y: float = (c["center"] as Vector3).y
		y_min = minf(y_min, y)
		y_max = maxf(y_max, y)
	var y_span: float = maxf(y_max - y_min, 0.001)

	var st: = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var card_size: float = float(p["leaf_card_size"])
	var jitter: float = float(p["leaf_size_jitter"])
	var per_cluster: int = maxi(1, int(p["leaves_per_cluster"]))
	var cluster_r: float = float(p["cluster_radius"])
	var cells: int = maxi(1, atlas_cells)
	var inset: float = 0.94
	var flatten: float = clampf(float(p["cluster_flatten"]), 0.0, 0.95)

	for c in clusters:
		var center: Vector3 = c["center"]
		for _i in range(per_cluster):
			var off: = Vector3(
				rng.randf_range(-1.0, 1.0), 
				rng.randf_range(-0.7, 0.7) * (1.0 - flatten), 
				rng.randf_range(-1.0, 1.0)
			) * cluster_r
			var pos: = center + off
			var size: float = card_size * (1.0 + rng.randf_range( - jitter, jitter))
			var height_t: float = clampf((pos.y - y_min) / y_span, 0.0, 1.0)
			var phase: float = rng.randf()

			var roll: float = rng.randf()


			var depth_key: float = rng.randf()

			var cell: int = rng.randi_range(0, cells * cells - 1)
			var cx: int = cell % cells
			var cy: int = floori(float(cell) / float(cells))



			for idx in CARD_TRIS:
				var corner: Vector2 = CARD_CORNERS[idx]
				var uv: = Vector2(
					(float(cx) + 0.5 + corner.x * inset) / float(cells), 
					(float(cy) + 0.5 - corner.y * inset) / float(cells))
				st.set_uv(uv)
				st.set_uv2(corner * size)
				st.set_color(Color(phase, height_t, roll, depth_key))
				st.set_normal(Vector3.UP)
				st.add_vertex(pos)

	return st.commit()

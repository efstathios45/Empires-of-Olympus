@tool

const HT_Errors = preload("./errors.gd")



static func next_power_of_two(x: int) -> int:
	x -= 1
	x |= x >> 1
	x |= x >> 2
	x |= x >> 4
	x |= x >> 8
	x |= x >> 16
	x += 1
	return x



static func create_wirecube_mesh(color = Color(1, 1, 1)) -> Mesh:
	var positions: = PackedVector3Array([
		Vector3(0, 0, 0), 
		Vector3(1, 0, 0), 
		Vector3(1, 0, 1), 
		Vector3(0, 0, 1), 
		Vector3(0, 1, 0), 
		Vector3(1, 1, 0), 
		Vector3(1, 1, 1), 
		Vector3(0, 1, 1), 
	])
	var colors: = PackedColorArray([
		color, color, color, color, 
		color, color, color, color, 
	])
	var indices: = PackedInt32Array([
		0, 1, 
		1, 2, 
		2, 3, 
		3, 0, 

		4, 5, 
		5, 6, 
		6, 7, 
		7, 4, 

		0, 4, 
		1, 5, 
		2, 6, 
		3, 7
	])
	var arrays: = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh


static func integer_square_root(x: int) -> int:
	assert (typeof(x) == TYPE_INT)
	var r: = int(roundf(sqrt(x)))
	if r * r == x:
		return r

	return -1



static func format_integer(n: int, sep: = ",") -> String:
	assert (typeof(n) == TYPE_INT)

	var negative: = false
	if n < 0:
		negative = true
		n = - n

	var s = ""
	while n >= 1000:
		s = str(sep, str(n % 1000).pad_zeros(3), s)
		n /= 1000

	if negative:
		return str("-", str(n), s)
	else:
		return str(str(n), s)



static func get_node_in_parents(node: Node, klass) -> Node:
	while node != null:
		node = node.get_parent()
		if node != null and is_instance_of(node, klass):
			return node
	return null



static func find_first_node(node: Node, klass) -> Node:
	if is_instance_of(node, klass):
		return node
	for i in node.get_child_count():
		var child: = node.get_child(i)
		var found_node: = find_first_node(child, klass)
		if found_node != null:
			return found_node
	return null


static func is_in_edited_scene(node: Node) -> bool:
	if not node.is_inside_tree():
		return false
	var edited_scene: = node.get_tree().edited_scene_root
	if node == edited_scene:
		return true
	return edited_scene != null and edited_scene.is_ancestor_of(node)





static func get_cropped_image(src: Image, width: int, height: int, 
	fill_color = null, anchor = Vector2(-1, -1)) -> Image:

	width = int(width)
	height = int(height)
	if width == src.get_width() and height == src.get_height():
		return src
	var im: = Image.create(width, height, false, src.get_format())
	if fill_color != null:
		im.fill(fill_color)
	var p = get_cropped_image_params(
		src.get_width(), src.get_height(), width, height, anchor)
	im.blit_rect(src, p.src_rect, p.dst_pos)
	return im


static func get_cropped_image_params(src_w: int, src_h: int, dst_w: int, dst_h: int, 
	anchor: Vector2) -> Dictionary:

	var rel_anchor: = (anchor + Vector2(1, 1)) / 2.0

	var dst_x: = (dst_w - src_w) * rel_anchor.x
	var dst_y: = (dst_h - src_h) * rel_anchor.y

	var src_x: = 0
	var src_y: = 0

	if dst_x < 0:
		src_x -= dst_x
		src_w -= dst_x
		dst_x = 0

	if dst_y < 0:
		src_y -= dst_y
		src_h -= dst_y
		dst_y = 0

	if dst_x + src_w >= dst_w:
		src_w = dst_w - dst_x

	if dst_y + src_h >= dst_h:
		src_h = dst_h - dst_y

	return {
		"src_rect": Rect2i(src_x, src_y, src_w, src_h), 
		"dst_pos": Vector2i(dst_x, dst_y)
	}


































static func apply_dpi_scale(root: Node, dpi_scale: float):
	if dpi_scale == 1.0:
		return
	var to_process: = [root]
	while len(to_process) > 0:
		var node: Node = to_process[-1]
		to_process.pop_back()
		if node is Window:
			node.size = Vector2(node.size) * dpi_scale
		elif node is Viewport or node is SubViewport:
			continue
		elif node is Control:
			if node.custom_minimum_size != Vector2(0, 0):
				node.custom_minimum_size = node.custom_minimum_size * dpi_scale
			var parent = node.get_parent()
			if parent != null:
				if not (parent is Container):
					node.offset_bottom *= dpi_scale
					node.offset_left *= dpi_scale
					node.offset_top *= dpi_scale
					node.offset_right *= dpi_scale
		for i in node.get_child_count():
			to_process.append(node.get_child(i))






static func get_aabb_intersection_with_segment(aabb: AABB, 
	segment_begin: Vector3, segment_end: Vector3) -> Array:

	var hits: = []

	if not aabb.intersects_segment(segment_begin, segment_end):
		return hits

	var hit

	var x_rect: = Rect2(aabb.position.y, aabb.position.z, aabb.size.y, aabb.size.z)

	hit = Plane(Vector3(1, 0, 0), aabb.position.x)\
	.intersects_segment(segment_begin, segment_end)
	if hit != null and x_rect.has_point(Vector2(hit.y, hit.z)):
		hits.append(hit)

	hit = Plane(Vector3(1, 0, 0), aabb.end.x)\
	.intersects_segment(segment_begin, segment_end)
	if hit != null and x_rect.has_point(Vector2(hit.y, hit.z)):
		hits.append(hit)

	var y_rect: = Rect2(aabb.position.x, aabb.position.z, aabb.size.x, aabb.size.z)

	hit = Plane(Vector3(0, 1, 0), aabb.position.y)\
	.intersects_segment(segment_begin, segment_end)
	if hit != null and y_rect.has_point(Vector2(hit.x, hit.z)):
		hits.append(hit)

	hit = Plane(Vector3(0, 1, 0), aabb.end.y)\
	.intersects_segment(segment_begin, segment_end)
	if hit != null and y_rect.has_point(Vector2(hit.x, hit.z)):
		hits.append(hit)

	var z_rect: = Rect2(aabb.position.x, aabb.position.y, aabb.size.x, aabb.size.y)

	hit = Plane(Vector3(0, 0, 1), aabb.position.z)\
	.intersects_segment(segment_begin, segment_end)
	if hit != null and z_rect.has_point(Vector2(hit.x, hit.y)):
		hits.append(hit)

	hit = Plane(Vector3(0, 0, 1), aabb.end.z)\
	.intersects_segment(segment_begin, segment_end)
	if hit != null and z_rect.has_point(Vector2(hit.x, hit.y)):
		hits.append(hit)

	if len(hits) == 2:

		var d0 = hits[0].distance_squared_to(segment_begin)
		var d1 = hits[1].distance_squared_to(segment_begin)
		if d0 > d1:
			var temp = hits[0]
			hits[0] = hits[1]
			hits[1] = temp
	else:
		assert (len(hits) < 2)

	return hits


class HT_GridRaytraceResult2D:
	var hit_cell_pos: Vector2
	var prev_cell_pos: Vector2













static func grid_raytrace_2d(ray_origin: Vector2, ray_direction: Vector2, 
	quad_predicate: Callable, max_distance: float) -> HT_GridRaytraceResult2D:

	if max_distance < 0.0001:

		return null

	var xi_step: = 0
	if ray_direction.x > 0:
		xi_step = 1
	elif ray_direction.x < 0:
		xi_step = -1

	var yi_step: = 0
	if ray_direction.y > 0:
		yi_step = 1
	elif ray_direction.y < 0:
		yi_step = -1

	var infinite: = 9999999.0

	var param_delta_x: = infinite
	if xi_step != 0:
		param_delta_x = 1.0 / absf(ray_direction.x)

	var param_delta_y: = infinite
	if yi_step != 0:
		param_delta_y = 1.0 / absf(ray_direction.y)



	var param_cross_x: = infinite

	var param_cross_y: = infinite



	if xi_step != 0:
		if xi_step == 1:
			param_cross_x = (ceilf(ray_origin.x) - ray_origin.x) * param_delta_x
		else:
			param_cross_x = (ray_origin.x - floorf(ray_origin.x)) * param_delta_x
	else:

		param_cross_x = infinite


	if yi_step != 0:
		if yi_step == 1:
			param_cross_y = (ceilf(ray_origin.y) - ray_origin.y) * param_delta_y
		else:
			param_cross_y = (ray_origin.y - floorf(ray_origin.y)) * param_delta_y
	else:

		param_cross_y = infinite

	var x: = int(floorf(ray_origin.x))
	var y: = int(floorf(ray_origin.y))


	if param_cross_x == 0.0:
		param_cross_x += param_delta_x


		if xi_step == -1:
			x -= 1

	if param_cross_y == 0.0:
		param_cross_y += param_delta_y
		if yi_step == -1:
			y -= 1

	var prev_x: = x
	var prev_y: = y
	var param: = 0.0
	var prev_param: = 0.0

	while true:
		prev_x = x
		prev_y = y
		prev_param = param

		if param_cross_x < param_cross_y:

			x += xi_step


			param = param_cross_x
			param_cross_x += param_delta_x

		else:

			y += yi_step
			param = param_cross_y
			param_cross_y += param_delta_y

		if param > max_distance:
			param = max_distance

			if quad_predicate.call(prev_x, prev_y, prev_param, param):
				var res: = HT_GridRaytraceResult2D.new()
				res.hit_cell_pos = Vector2(x, y)
				res.prev_cell_pos = Vector2(prev_x, prev_y)
				return res
			else:
				break

		elif quad_predicate.call(prev_x, prev_y, prev_param, param):
			var res: = HT_GridRaytraceResult2D.new()
			res.hit_cell_pos = Vector2(x, y)
			res.prev_cell_pos = Vector2(prev_x, prev_y)
			return res

	return null


static func get_segment_clipped_by_rect(rect: Rect2, 
	segment_begin: Vector2, segment_end: Vector2) -> Array:








	if rect.has_point(segment_begin) and rect.has_point(segment_end):
		return [segment_begin, segment_end]

	var a: = rect.position
	var b: = Vector2(rect.end.x, rect.position.y)
	var c: = Vector2(rect.position.x, rect.end.y)
	var d: = rect.end

	var ab = Geometry2D.segment_intersects_segment(segment_begin, segment_end, a, b)
	var cd = Geometry2D.segment_intersects_segment(segment_begin, segment_end, c, d)
	var ac = Geometry2D.segment_intersects_segment(segment_begin, segment_end, a, c)
	var bd = Geometry2D.segment_intersects_segment(segment_begin, segment_end, b, d)

	var hits = []
	if ab != null:
		hits.append(ab)
	if cd != null:
		hits.append(cd)
	if ac != null:
		hits.append(ac)
	if bd != null:
		hits.append(bd)


	if len(hits) == 1:
		if rect.has_point(segment_begin):
			hits = [segment_begin, hits[0]]
		elif rect.has_point(segment_end):
			hits = [hits[0], segment_end]
		else:



			return []

	elif len(hits) == 2:
		var d0 = hits[0].distance_squared_to(segment_begin)
		var d1 = hits[1].distance_squared_to(segment_begin)
		if d0 > d1:
			hits = [hits[1], hits[0]]

	return hits


static func get_pixel_clamped(im: Image, x: int, y: int) -> Color:
	x = clampi(x, 0, im.get_width() - 1)
	y = clampi(y, 0, im.get_height() - 1)
	return im.get_pixel(x, y)


static func update_configuration_warning(node: Node, recursive: bool):
	if not Engine.is_editor_hint():
		return
	node.update_configuration_warnings()
	if recursive:
		for i in node.get_child_count():
			var child = node.get_child(i)
			update_configuration_warning(child, true)


static func write_import_file(settings: Dictionary, imp_fpath: String, logger) -> bool:

	var f: = FileAccess.open(imp_fpath, FileAccess.WRITE)
	if f == null:
		var err = FileAccess.get_open_error()
		logger.error("Could not open '{0}' for write, error {1}"\
		.format([imp_fpath, HT_Errors.get_message(err)]))
		return false

	for section in settings:
		f.store_line(str("[", section, "]"))
		f.store_line("")
		var params = settings[section]
		for key in params:
			var v = params[key]
			var sv
			match typeof(v):
				TYPE_STRING:
					sv = str("\"", v.replace("\"", "\""), "\"")
				TYPE_BOOL:
					sv = "true" if v else "false"
				_:
					sv = str(v)
			f.store_line(str(key, "=", sv))
		f.store_line("")

	return true


static func update_texture_partial(
	tex: ImageTexture, im: Image, src_rect: Rect2i, dst_pos: Vector2i):





















	var fuck = tex.get_image()
	fuck.blit_rect(im, src_rect, dst_pos)
	tex.update(fuck)





static func get_shader_material_parameter(material: ShaderMaterial, param_name: StringName):
	var v = material.get_shader_parameter(param_name)
	if v == null:
		var shader: Shader = material.shader
		if shader != null:
			v = RenderingServer.shader_get_parameter_default(shader.get_rid(), param_name)
	return v

@tool







class HT_XYZBounds:


	var min_x: = 0.0
	var min_y: = 0.0

	var max_x: = 0.0
	var max_y: = 0.0

	var line_count: = 0

	var image_width: = 0
	var image_height: = 0






static func load_bounds(f: FileAccess) -> HT_XYZBounds:

	var line: = f.get_line()
	var floats: = line.split_floats(" ")



	var min_pos_x: = floats[0]
	var min_pos_y: = floats[1]

	var max_pos_x: = min_pos_x
	var max_pos_y: = min_pos_y


	var line_count: = 1


	while not f.eof_reached():
		line = f.get_line()


		if len(line) < 2:
			break

		floats = line.split_floats(" ")

		var pos_x: = floats[0]
		var pos_y: = floats[1]

		min_pos_x = minf(min_pos_x, pos_x)
		min_pos_y = minf(min_pos_y, pos_y)

		max_pos_x = maxf(max_pos_x, pos_x)
		max_pos_y = maxf(max_pos_y, pos_y)

		line_count += 1

	var bounds: = HT_XYZBounds.new()
	bounds.min_x = min_pos_x
	bounds.min_y = min_pos_y
	bounds.max_x = max_pos_x
	bounds.max_y = max_pos_y
	bounds.line_count = line_count
	bounds.image_width = int(max_pos_x - min_pos_x) + 1
	bounds.image_height = int(max_pos_y - min_pos_y) + 1
	return bounds





static func load_heightmap(f: FileAccess, dst_image: Image, bounds: HT_XYZBounds):






	var dst_format: = dst_image.get_format()
	assert (dst_format == Image.FORMAT_RF or dst_format == Image.FORMAT_RH)


	if bounds == null:
		var file_begin: = f.get_position()
		bounds = load_bounds(f)
		f.seek(file_begin)


	var min_pos_x: = bounds.min_x
	var min_pos_y: = bounds.min_y
	var line_count: = bounds.line_count

	for i in line_count:
		var line: = f.get_line()
		var floats: = line.split_floats(" ")
		var x: = int(floats[0] - min_pos_x)
		var y: = int(floats[1] - min_pos_y)





		if x >= 0 and y >= 0 and x < dst_image.get_width() and y < dst_image.get_height():
			dst_image.set_pixel(x, y, Color(floats[2], 0, 0))

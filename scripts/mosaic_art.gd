class_name MosaicArt
extends RefCounted
## Circular agora ψιφιδωτό (psifidoto) — tessera grid + classical Greek palette.

const RES: = 40
## Index 0 = unpainted (shows stone underlay). Palette colors are 1..n.
const EMPTY: = 0

## Classical / Homeric colour words rendered in English, tuned for pebble mosaic.
const PALETTE: = [
	{"id": "leukos", "name": "Leukos", "gloss": "Marble white", "color": Color(0.93, 0.90, 0.84)},
	{"id": "melas", "name": "Melas", "gloss": "Deep black", "color": Color(0.10, 0.09, 0.10)},
	{"id": "erythros", "name": "Erythros", "gloss": "Blood red", "color": Color(0.72, 0.16, 0.14)},
	{"id": "phoenikeos", "name": "Phoinix", "gloss": "Crimson dye", "color": Color(0.62, 0.12, 0.28)},
	{"id": "porphyra", "name": "Porphyra", "gloss": "Tyrian purple", "color": Color(0.42, 0.16, 0.48)},
	{"id": "kyaneos", "name": "Kyaneos", "gloss": "Dark blue", "color": Color(0.14, 0.24, 0.52)},
	{"id": "glaukos", "name": "Glaukos", "gloss": "Sea-gleam", "color": Color(0.35, 0.58, 0.62)},
	{"id": "chloros", "name": "Chloros", "gloss": "Fresh green", "color": Color(0.32, 0.55, 0.28)},
	{"id": "omphax", "name": "Omphax", "gloss": "Unripe grape", "color": Color(0.45, 0.52, 0.22)},
	{"id": "xanthos", "name": "Xanthos", "gloss": "Golden yellow", "color": Color(0.88, 0.72, 0.22)},
	{"id": "ochros", "name": "Ochros", "gloss": "Pale ochre", "color": Color(0.82, 0.66, 0.38)},
	{"id": "chryseos", "name": "Chryseos", "gloss": "Bright gold", "color": Color(0.86, 0.70, 0.28)},
	{"id": "pyrros", "name": "Pyrros", "gloss": "Flame orange", "color": Color(0.86, 0.42, 0.14)},
	{"id": "keramos", "name": "Keramos", "gloss": "Clay brown", "color": Color(0.55, 0.32, 0.18)},
	{"id": "argos", "name": "Argos", "gloss": "Silver-grey", "color": Color(0.62, 0.64, 0.66)},
	{"id": "aithops", "name": "Aithops", "gloss": "Smoky bronze", "color": Color(0.38, 0.28, 0.20)},
]

const UNDERLAY: = Color(0.78, 0.70, 0.58)
const MORTAR: = Color(0.52, 0.45, 0.36)


static func palette_count() -> int:
	return PALETTE.size()


static func color_at(index: int) -> Color:
	if index <= EMPTY or index > PALETTE.size():
		return UNDERLAY
	return PALETTE[index - 1]["color"]


static func entry_at(index: int) -> Dictionary:
	if index <= EMPTY or index > PALETTE.size():
		return {}
	return PALETTE[index - 1]


static func empty_tiles() -> PackedByteArray:
	var t: = PackedByteArray()
	t.resize(RES * RES)
	t.fill(EMPTY)
	return t


static func ensure_tiles(tiles: PackedByteArray) -> PackedByteArray:
	if tiles == null or tiles.size() != RES * RES:
		return empty_tiles()
	return tiles


static func in_circle(x: int, y: int) -> bool:
	var cx: = (RES - 1) * 0.5
	var cy: = (RES - 1) * 0.5
	var dx: = float(x) - cx
	var dy: = float(y) - cy
	# Slight inset so the rim reads cleanly.
	return dx * dx + dy * dy <= (cx - 0.35) * (cx - 0.35)


static func index_of(x: int, y: int) -> int:
	return y * RES + x


static func painted_count(tiles: PackedByteArray) -> int:
	tiles = ensure_tiles(tiles)
	var n: = 0
	for y in RES:
		for x in RES:
			if not in_circle(x, y):
				continue
			if tiles[index_of(x, y)] != EMPTY:
				n += 1
	return n


static func circle_capacity() -> int:
	var n: = 0
	for y in RES:
		for x in RES:
			if in_circle(x, y):
				n += 1
	return n


static func set_tile(tiles: PackedByteArray, x: int, y: int, color_index: int) -> void:
	if x < 0 or y < 0 or x >= RES or y >= RES:
		return
	if not in_circle(x, y):
		return
	var c: = clampi(color_index, EMPTY, PALETTE.size())
	tiles[index_of(x, y)] = c


static func paint_brush(tiles: PackedByteArray, x: int, y: int, color_index: int, radius: int = 0) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius + radius:
				set_tile(tiles, x + dx, y + dy, color_index)


static func clear_circle(tiles: PackedByteArray) -> void:
	tiles = ensure_tiles(tiles)
	for y in RES:
		for x in RES:
			if in_circle(x, y):
				tiles[index_of(x, y)] = EMPTY


## Build a square Image of the circular mosaic (transparent outside the disc).
static func build_image(tiles: PackedByteArray, px_per_cell: int = 8) -> Image:
	tiles = ensure_tiles(tiles)
	var side: = RES * px_per_cell
	var img: = Image.create(side, side, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var gap: = maxi(1, int(round(float(px_per_cell) * 0.12)))
	for y in RES:
		for x in RES:
			if not in_circle(x, y):
				continue
			var idx: = int(tiles[index_of(x, y)])
			var col: = color_at(idx) if idx != EMPTY else UNDERLAY
			var x0: = x * px_per_cell
			var y0: = y * px_per_cell
			# Mortar frame
			for py in px_per_cell:
				for px in px_per_cell:
					var edge: = px < gap or py < gap or px >= px_per_cell - gap or py >= px_per_cell - gap
					img.set_pixel(x0 + px, y0 + py, MORTAR if edge else col)
	return img


static func build_texture(tiles: PackedByteArray, px_per_cell: int = 8) -> ImageTexture:
	return ImageTexture.create_from_image(build_image(tiles, px_per_cell))


static func tiles_to_array(tiles: PackedByteArray) -> Array:
	tiles = ensure_tiles(tiles)
	var out: Array = []
	out.resize(tiles.size())
	for i in tiles.size():
		out[i] = int(tiles[i])
	return out


static func tiles_from_array(raw) -> PackedByteArray:
	var t: = empty_tiles()
	if typeof(raw) != TYPE_ARRAY:
		return t
	var n: = mini(raw.size(), t.size())
	for i in n:
		t[i] = clampi(int(raw[i]), EMPTY, PALETTE.size())
	return t

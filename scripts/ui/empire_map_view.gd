extends Control



signal empire_selected(id: String)

const Kit = preload("res://scripts/ui/ui_kit.gd")
const MAP_TEX: = "res://assets/textures/backgrounds/empire_map_hellas.png"

const BORDER_TEX: = {
	"sparta": "res://assets/textures/backgrounds/empire_border_sparta.png", 
	"athens": "res://assets/textures/backgrounds/empire_border_athens.png", 
	"corinth": "res://assets/textures/backgrounds/empire_border_corinth.png", 
}


const REGION_RECTS: = {
	"sparta": [0.14, 0.4, 0.36, 0.48], 
	"athens": [0.52, 0.28, 0.42, 0.48], 
	"corinth": [0.3, 0.16, 0.32, 0.34], 
}

const CHRONICLE: = {
	"sparta": {
		"name": "Sparta", 
		"king": "King Agesilaos the Ironhand", 
		"queen": "Queen Gorgo of the Eurotas", 
		"capital": "Sparta", 
		"rival": "Athens", 
		"war": "The Laconic Wars — phalanx iron against Attic fleets", 
		"battle": "Blood on the Eurotas fords (Year of the Twin Eagles)", 
		"detail": "Laconia drills every child into a shield-bearer. Agesilaos swore no Spartan blade would rest while Athenian triremes shadow the gulf. Argos pays tribute in bronze; Olympia hosts the games under crimson banners.", 
	}, 
	"athens": {
		"name": "Athens", 
		"king": "Archon Perikles the Far-Sighted", 
		"queen": "Priestess Aspasia of the Olive", 
		"capital": "Athens", 
		"rival": "Sparta", 
		"war": "The Olive and the Spear — academy silver funding island revolts", 
		"battle": "Night of Broken Oars off Salamis Sound", 
		"detail": "Athena's city rules the isles by decree and silver. Perikles keeps the lamps of the academy burning while privateers harry Corinthian grain. Thebes watches uneasily; the Cyclades fly the blue pennant.", 
	}, 
	"corinth": {
		"name": "Corinth", 
		"king": "Tyrant Kypselos the Coin-Weigher", 
		"queen": "Lady Melissa of Two Seas", 
		"capital": "Thebes (Boeotian foothold)", 
		"rival": "Both — and neither", 
		"war": "The Toll Wars — every keel taxed, every rival bribed", 
		"battle": "The Burning of the Diolkos warehouses", 
		"detail": "Two seas, one isthmus — and walled Thebes as Corinth's inland gate. Kypselos sells grain to Sparta and timber to Athens in the same week, then funds both sides' next campaign. Drachmae are her phalanx.", 
	}, 
}

var selected: String = "sparta"
var _map_host: Control
var _map_tex: TextureRect
var _highlights: Dictionary = {}
var _hotspots: Dictionary = {}
var _detail_title: Label
var _detail_body: Label
var _map_origin: Vector2 = Vector2.ZERO
var _map_drawn: Vector2 = Vector2.ZERO


func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_STOP
	var root: = HBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_map_host = Control.new()
	_map_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_host.clip_contents = true
	_map_host.resized.connect(_layout_map)
	root.add_child(_map_host)

	_map_tex = TextureRect.new()
	if ResourceLoader.exists(MAP_TEX):
		_map_tex.texture = load(MAP_TEX)
	_map_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_map_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_host.add_child(_map_tex)

	for id in ["sparta", "athens", "corinth"]:
		var hl: = TextureRect.new()
		var path: String = String(BORDER_TEX.get(id, ""))
		if path != "" and ResourceLoader.exists(path):
			hl.texture = load(path)
		hl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hl.stretch_mode = TextureRect.STRETCH_SCALE
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		hl.modulate = Color(1, 1, 1, 0)
		_map_host.add_child(hl)
		_highlights[id] = hl

		var btn: = Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = "Study %s" % String(CHRONICLE[id]["name"])
		btn.pressed.connect(_on_region_pressed.bind(id))
		btn.mouse_entered.connect(_on_region_hover.bind(id, true))
		btn.mouse_exited.connect(_on_region_hover.bind(id, false))
		_map_host.add_child(btn)
		_hotspots[id] = btn


	var side: = PanelContainer.new()
	side.custom_minimum_size = Vector2(360, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.87, 0.74, 0.96)
	sb.border_color = Color(0.55, 0.4, 0.16, 0.95)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	side.add_theme_stylebox_override("panel", sb)
	root.add_child(side)

	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	side.add_child(col)

	const CHRONICLE_W: = 320
	col.add_child(Kit.make_label("Chronicle of the Realm", 17, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	_detail_title = Kit.make_label("", 22, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER)
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_title.custom_minimum_size = Vector2(CHRONICLE_W, 0)
	col.add_child(_detail_title)

	_detail_body = Kit.make_label("", 13, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT)
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body.custom_minimum_size = Vector2(CHRONICLE_W, 0)
	_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_detail_body)

	var tip: = Kit.make_label("Click a coloured realm — only its land border lights.", 12, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(CHRONICLE_W, 0)
	col.add_child(tip)

	call_deferred("_layout_map")
	call_deferred("set_selected", selected)


func _layout_map() -> void :
	if _map_host == null or _map_tex == null:
		return
	var host: = _map_host.size
	if host.x < 8.0 or host.y < 8.0:
		return
	_map_tex.position = Vector2.ZERO
	_map_tex.size = host
	var tex: Texture2D = _map_tex.texture
	if tex == null:
		return
	var tex_size: = tex.get_size()
	var scale: float = minf(host.x / tex_size.x, host.y / tex_size.y)
	_map_drawn = tex_size * scale
	_map_origin = (host - _map_drawn) * 0.5


	for id in _highlights:
		var hl: TextureRect = _highlights[id]
		hl.position = _map_origin
		hl.size = _map_drawn

	for id in _hotspots:
		var rect_n: Array = REGION_RECTS.get(id, [0.3, 0.3, 0.2, 0.2])
		var r: = Rect2(
			_map_origin.x + float(rect_n[0]) * _map_drawn.x, 
			_map_origin.y + float(rect_n[1]) * _map_drawn.y, 
			float(rect_n[2]) * _map_drawn.x, 
			float(rect_n[3]) * _map_drawn.y)
		_hotspots[id].position = r.position
		_hotspots[id].size = r.size
	_refresh_highlights()


func set_selected(id: String) -> void :
	if not CHRONICLE.has(id):
		return
	selected = id
	_refresh_highlights()
	_refresh_detail()


func _refresh_highlights() -> void :
	for id in _highlights:
		var hl: TextureRect = _highlights[id]

		hl.modulate = Color(1.08, 1.05, 1.0, 1.0) if id == selected else Color(1, 1, 1, 0)


func _refresh_detail() -> void :
	var c: Dictionary = CHRONICLE.get(selected, {})
	if c.is_empty():
		return
	_detail_title.text = String(c.get("name", ""))
	_detail_body.text = "\n".join([
		"King: %s" % String(c.get("king", "")), 
		"Consort: %s" % String(c.get("queen", "")), 
		"Capital: %s" % String(c.get("capital", "")), 
		"Rival: %s" % String(c.get("rival", "")), 
		"", 
		"War: %s" % String(c.get("war", "")), 
		"Famous battle: %s" % String(c.get("battle", "")), 
		"", 
		String(c.get("detail", "")), 
	])


func _on_region_pressed(id: String) -> void :
	AudioManager.play_sfx("ui_click", -4.0)
	set_selected(id)
	empire_selected.emit(id)


func _on_region_hover(id: String, on: bool) -> void :
	if id == selected:
		return
	var hl: TextureRect = _highlights.get(id)
	if hl == null:
		return
	hl.modulate = Color(1, 1, 1, 0.55 if on else 0.0)

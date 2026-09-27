extends Control
## Interactive political map of Hellas — click a realm to highlight it and
## read the chronicle (kings, wars, rivalries). Emits empire_selected(id).

signal empire_selected(id: String)

const Kit = preload("res://scripts/ui/ui_kit.gd")
const MAP_TEX := "res://assets/textures/backgrounds/empire_map_hellas.png"

## Normalized rects on the painted map: [x, y, w, h] in 0–1 of the texture.
const REGION_RECTS := {
	"sparta": [0.14, 0.40, 0.36, 0.48],
	"athens": [0.52, 0.28, 0.42, 0.48],
	"corinth": [0.30, 0.16, 0.32, 0.34],
}

## Made-up Age-of-Bronze chronicle for each empire (game fiction).
const CHRONICLE := {
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
		"war": "The Olive and the Spear — academy gold funding island revolts",
		"battle": "Night of Broken Oars off Salamis Sound",
		"detail": "Athena's city rules the isles by decree and silver. Perikles keeps the lamps of the academy burning while privateers harry Corinthian grain. Thebes watches uneasily; the Cyclades fly the blue pennant.",
	},
	"corinth": {
		"name": "Corinth",
		"king": "Tyrant Kypselos the Coin-Weigher",
		"queen": "Lady Melissa of Two Seas",
		"capital": "Corinth",
		"rival": "Both — and neither",
		"war": "The Toll Wars — every keel taxed, every rival bribed",
		"battle": "The Burning of the Diolkos warehouses",
		"detail": "Two seas, one isthmus, and Kypselos' ledgers thicker than any shield. Corinth sells grain to Sparta and timber to Athens in the same week, then funds both sides' next campaign. Gold is her phalanx.",
	},
}

var selected: String = "sparta"
var _map_host: Control
var _map_tex: TextureRect
var _highlights: Dictionary = {}  ## id -> ColorRect
var _hotspots: Dictionary = {}  ## id -> Button
var _detail_title: Label
var _detail_body: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var root := HBoxContainer.new()
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
		var color: Color = GameState.EMPIRES.get(id, {}).get("color", Color.WHITE)
		var hl := ColorRect.new()
		hl.color = Color(color.r, color.g, color.b, 0.0)
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_map_host.add_child(hl)
		_highlights[id] = hl

		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = "Study %s" % String(CHRONICLE[id]["name"])
		btn.pressed.connect(_on_region_pressed.bind(id))
		btn.mouse_entered.connect(_on_region_hover.bind(id, true))
		btn.mouse_exited.connect(_on_region_hover.bind(id, false))
		_map_host.add_child(btn)
		_hotspots[id] = btn

	var side := PanelContainer.new()
	side.custom_minimum_size = Vector2(340, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb: StyleBox = Kit.style("res://assets/ui/panel_scroll.tres")
	if sb:
		side.add_theme_stylebox_override("panel", sb)
	root.add_child(side)

	var margin := Kit.make_margin(20)
	side.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	col.add_child(Kit.make_label("Chronicle of the Realm", 18, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	_detail_title = Kit.make_label("", 22, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER)
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_title.custom_minimum_size = Vector2(260, 0)
	col.add_child(_detail_title)

	_detail_body = Kit.make_label("", 13, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT)
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body.custom_minimum_size = Vector2(260, 0)
	_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_detail_body)

	var tip := Kit.make_label("Click a coloured realm on the map.", 12, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(260, 0)
	col.add_child(tip)

	call_deferred("_layout_map")
	call_deferred("set_selected", selected)


func _layout_map() -> void:
	if _map_host == null or _map_tex == null:
		return
	var host := _map_host.size
	if host.x < 8.0 or host.y < 8.0:
		return
	_map_tex.position = Vector2.ZERO
	_map_tex.size = host
	var tex: Texture2D = _map_tex.texture
	if tex == null:
		return
	var tex_size := tex.get_size()
	var scale: float = minf(host.x / tex_size.x, host.y / tex_size.y)
	var drawn := tex_size * scale
	var origin := (host - drawn) * 0.5
	for id in _hotspots:
		var rect_n: Array = REGION_RECTS.get(id, [0.3, 0.3, 0.2, 0.2])
		var r := Rect2(
			origin.x + float(rect_n[0]) * drawn.x,
			origin.y + float(rect_n[1]) * drawn.y,
			float(rect_n[2]) * drawn.x,
			float(rect_n[3]) * drawn.y)
		_hotspots[id].position = r.position
		_hotspots[id].size = r.size
		_highlights[id].position = r.position
		_highlights[id].size = r.size
	_refresh_highlights()


func set_selected(id: String) -> void:
	if not CHRONICLE.has(id):
		return
	selected = id
	_refresh_highlights()
	_refresh_detail()


func _refresh_highlights() -> void:
	for id in _highlights:
		var hl: ColorRect = _highlights[id]
		var base: Color = GameState.EMPIRES.get(id, {}).get("color", Color.WHITE)
		if id == selected:
			hl.color = Color(base.r, base.g, base.b, 0.42)
		else:
			hl.color = Color(base.r, base.g, base.b, 0.0)


func _refresh_detail() -> void:
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


func _on_region_pressed(id: String) -> void:
	AudioManager.play_sfx("ui_click", -4.0)
	set_selected(id)
	empire_selected.emit(id)


func _on_region_hover(id: String, on: bool) -> void:
	if id == selected:
		return
	var hl: ColorRect = _highlights.get(id)
	if hl == null:
		return
	var base: Color = GameState.EMPIRES.get(id, {}).get("color", Color.WHITE)
	hl.color = Color(base.r, base.g, base.b, 0.22 if on else 0.0)

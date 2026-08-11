extends Control
## Hellas map with red territorial barriers and a glow over the selected empire.
## Coordinates are normalized 0–1 over the drawn map rect (approx. of the art).

var selected: String = "sparta"

## Approximate region boxes on the painted map (x, y, w, h) in 0–1 space.
const REGIONS := {
	"sparta": Rect2(0.10, 0.42, 0.34, 0.42),   # SW crimson Peloponnese
	"corinth": Rect2(0.34, 0.18, 0.30, 0.40),  # central gold isthmus
	"athens": Rect2(0.58, 0.22, 0.32, 0.48),   # east blue coasts / isles
}

## Red barrier polylines between empires (normalized points).
const BARRIERS: Array = [
	# Sparta | Corinth
	[Vector2(0.30, 0.38), Vector2(0.36, 0.48), Vector2(0.40, 0.62), Vector2(0.38, 0.78)],
	# Corinth | Athens
	[Vector2(0.52, 0.22), Vector2(0.56, 0.38), Vector2(0.58, 0.55), Vector2(0.62, 0.72)],
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_selected(id: String) -> void:
	selected = id
	queue_redraw()


func _draw() -> void:
	var r := get_rect().size
	if r.x < 8.0 or r.y < 8.0:
		return
	# Soft glow over the chosen realm.
	if REGIONS.has(selected):
		var nr: Rect2 = REGIONS[selected]
		var gr := Rect2(nr.position * r, nr.size * r)
		var col := Color(1.0, 0.82, 0.35, 0.22)
		if selected == "sparta":
			col = Color(1.0, 0.28, 0.18, 0.26)
		elif selected == "athens":
			col = Color(0.25, 0.55, 1.0, 0.26)
		elif selected == "corinth":
			col = Color(1.0, 0.82, 0.2, 0.26)
		draw_rect(gr, col, true)
		# Bright rim
		var rim := col
		rim.a = 0.85
		draw_rect(gr.grow(2.0), rim, false, 3.0)

	# Crimson barriers between empires.
	for line in BARRIERS:
		var pts: PackedVector2Array = PackedVector2Array()
		for p in line:
			pts.append(Vector2(p.x, p.y) * r)
		if pts.size() >= 2:
			draw_polyline(pts, Color(0.85, 0.08, 0.05, 0.95), 4.0, true)
			draw_polyline(pts, Color(1.0, 0.35, 0.2, 0.55), 8.0, true)

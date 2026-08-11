extends Control
## Hellas map with red territorial barriers and a circular magnifier glow
## over the selected empire (Metin/map-lens style, not a rectangle).

var selected: String = "sparta"

## Approximate region centres + radius on the painted map (normalized 0–1).
const REGIONS := {
	"sparta": {"c": Vector2(0.27, 0.63), "r": 0.20},
	"corinth": {"c": Vector2(0.49, 0.38), "r": 0.17},
	"athens": {"c": Vector2(0.74, 0.46), "r": 0.19},
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
	# Circular magnifying-glass glow over the chosen realm.
	if REGIONS.has(selected):
		var info: Dictionary = REGIONS[selected]
		var centre: Vector2 = Vector2(info["c"].x, info["c"].y) * r
		# Radius scales with the shorter map axis so the lens stays round.
		var rad: float = float(info["r"]) * minf(r.x, r.y)
		var col := Color(1.0, 0.82, 0.35, 0.22)
		if selected == "sparta":
			col = Color(1.0, 0.28, 0.18, 0.28)
		elif selected == "athens":
			col = Color(0.25, 0.55, 1.0, 0.28)
		elif selected == "corinth":
			col = Color(1.0, 0.82, 0.2, 0.28)
		# Soft filled lens.
		draw_circle(centre, rad, col)
		# Brighter inner wash (magnifier glass).
		var inner := col
		inner.a = col.a * 0.55
		draw_circle(centre, rad * 0.62, inner)
		# Glass rim.
		var rim := col
		rim.a = 0.92
		draw_arc(centre, rad, 0.0, TAU, 64, rim, 3.5, true)
		# Outer ring (metal frame of the loupe).
		var frame := Color(0.95, 0.9, 0.75, 0.75)
		draw_arc(centre, rad + 4.0, 0.0, TAU, 64, frame, 2.0, true)
		# Magnifier handle — short stem pointing bottom-right.
		var handle_a: Vector2 = centre + Vector2(rad * 0.72, rad * 0.72)
		var handle_b: Vector2 = handle_a + Vector2(rad * 0.55, rad * 0.55)
		draw_line(handle_a, handle_b, Color(0.92, 0.85, 0.55, 0.9), 5.0, true)
		draw_line(handle_a, handle_b, Color(0.55, 0.35, 0.12, 0.85), 2.5, true)

	# Crimson barriers between empires.
	for line in BARRIERS:
		var pts: PackedVector2Array = PackedVector2Array()
		for p in line:
			pts.append(Vector2(p.x, p.y) * r)
		if pts.size() >= 2:
			draw_polyline(pts, Color(0.85, 0.08, 0.05, 0.95), 4.0, true)
			draw_polyline(pts, Color(1.0, 0.35, 0.2, 0.55), 8.0, true)

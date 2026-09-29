extends Node3D


const EMPIRE_COLORS: = {
	"sparta": Color(0.92, 0.32, 0.28), 
	"athens": Color(0.45, 0.68, 1.0), 
	"corinth": Color(0.95, 0.82, 0.32), 
}

var _name_lab: Label3D
var _level_lab: Label3D
var display_name: String = "Champion"
var level: int = 1
var empire_id: String = "sparta"


func _ready() -> void :
	position = Vector3(0.0, 2.45, 0.0)
	_name_lab = _make_label(52, 0.0036)
	_name_lab.position = Vector3(0.0, 0.12, 0.0)
	add_child(_name_lab)
	_level_lab = _make_label(36, 0.003)
	_level_lab.position = Vector3(0.0, -0.02, 0.0)
	add_child(_level_lab)
	refresh()


func _make_label(font_size: int, pixel: float) -> Label3D:
	var lab: = Label3D.new()
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.shaded = false
	lab.double_sided = true
	lab.no_depth_test = true
	lab.font_size = font_size
	lab.pixel_size = pixel
	lab.outline_size = 14
	lab.outline_modulate = Color(0.05, 0.04, 0.03, 0.92)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lab


func set_plate(p_name: String, p_level: int, p_empire: String) -> void :
	display_name = p_name if p_name != "" else "Champion"
	level = maxi(1, p_level)
	empire_id = p_empire if p_empire != "" else "sparta"
	refresh()


func refresh() -> void :
	if _name_lab == null or _level_lab == null:
		return
	var col: Color = EMPIRE_COLORS.get(empire_id, Color(0.92, 0.88, 0.78))
	var emp_name: = empire_id.capitalize()
	var gs: = Engine.get_main_loop()
	if gs is SceneTree:
		var autoload: = (gs as SceneTree).root.get_node_or_null("GameState")
		if autoload != null and autoload.get("EMPIRES") is Dictionary:
			var data: Dictionary = (autoload.EMPIRES as Dictionary).get(empire_id, {})
			if not data.is_empty():
				emp_name = String(data.get("name", emp_name))
				if data.has("color"):
					var base: Color = data["color"]
					col = base.lightened(0.35)
	_name_lab.text = display_name
	_name_lab.modulate = col
	_level_lab.text = "Lv %d · %s" % [level, emp_name]
	_level_lab.modulate = Color(col.r, col.g, col.b, 0.9)

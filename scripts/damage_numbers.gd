class_name DamageNumbers
extends Node


const FONT_PATH: = "res://assets/fonts/cinzel.ttf"
static var _font: Font

static func _get_font() -> Font:
	if _font == null and ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	return _font


static func spawn(parent: Node, at: Vector3, amount: int, color: Color = Color(1.0, 0.85, 0.35)) -> void :
	if parent == null:
		return
	var label: = Label3D.new()
	label.text = str(amount)
	label.font = _get_font()
	label.font_size = 96
	label.pixel_size = 0.012
	label.modulate = color
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.outline_size = 16
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = at
	parent.add_child(label)

	var drift: = Vector3(randf_range(-0.4, 0.4), 1.6, randf_range(-0.4, 0.4))
	var tween: = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", at + drift, 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)

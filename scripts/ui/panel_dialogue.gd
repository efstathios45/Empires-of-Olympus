extends Control




const Kit = preload("res://scripts/ui/ui_kit.gd")


const TEXT_W: = 520

var hud: CanvasLayer

var _quest_title: Label
var _quest_brief: Label
var _progress: Label
var _reward: Label
var _complete_btn: Button

func _ready() -> void :

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())

	var center: = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel: = Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(820, 560)
	center.add_child(panel)

	var margin: = Kit.make_margin(20)
	panel.add_child(margin)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)


	var speaker: = HBoxContainer.new()
	speaker.alignment = BoxContainer.ALIGNMENT_CENTER
	speaker.add_theme_constant_override("separation", 12)
	v.add_child(speaker)
	speaker.add_child(Kit.make_icon("icon_laurel", 38))
	speaker.add_child(Kit.make_label("Priestess Melite", 30, Kit.INK_TITLE))

	var quote: = Kit.make_label(
		"\"The gods watch you, champion. Hellas bleeds — will you answer?\"", 
		17, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.custom_minimum_size = Vector2(TEXT_W, 0)
	v.add_child(quote)
	v.add_child(_divider())


	_quest_title = Kit.make_label("", 24, Kit.INK_TITLE)
	_quest_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_title.custom_minimum_size = Vector2(TEXT_W, 0)
	v.add_child(_quest_title)

	_quest_brief = Kit.make_label("", 18, Kit.INK)
	_quest_brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_brief.custom_minimum_size = Vector2(TEXT_W, 0)
	_quest_brief.add_theme_constant_override("line_spacing", 8)
	v.add_child(_quest_brief)
	v.add_child(Kit.spacer(4))

	_progress = Kit.make_label("", 17, Kit.INK_SOFT)
	_progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_progress.custom_minimum_size = Vector2(TEXT_W, 0)
	_progress.add_theme_constant_override("line_spacing", 5)
	v.add_child(_progress)

	_reward = Kit.make_label("", 18, Kit.INK_GOLD)
	_reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward.custom_minimum_size = Vector2(TEXT_W, 0)
	v.add_child(_reward)


	v.add_child(Kit.spacer(6))
	var row: = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)

	_complete_btn = Kit.make_button("Complete", true)
	_complete_btn.pressed.connect(_on_complete)
	row.add_child(_complete_btn)

	var close_btn: = Kit.make_button("Farewell", false)
	close_btn.pressed.connect( func() -> void : hud.close_panel_from_click())
	row.add_child(close_btn)

	_refresh()

func _divider() -> ColorRect:
	var d: = ColorRect.new()
	d.color = Color(0.42, 0.32, 0.14, 0.3)
	d.custom_minimum_size = Vector2(TEXT_W, 2)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d

func _refresh() -> void :
	var q: Dictionary = GameState.current_quest()
	if q.is_empty():
		_quest_title.text = "The Trials are complete"
		_quest_brief.text = "You have done what no hero before you managed. The stones are dust, the beast is felled. Olympia sings your name."
		_progress.text = ""
		_reward.text = ""
		_complete_btn.visible = false
		return
	_quest_title.text = "Trial %d — %s" % [GameState.quest_index + 1, q["title"]]
	_quest_brief.text = q["brief"]
	_progress.text = "Your progress:\n%s" % GameState.quest_progress_text()
	_reward.text = "Reward: %d gold  •  %d glory" % [q["reward_gold"], q["reward_xp"]]
	_complete_btn.visible = GameState.is_quest_objective_done()

func _on_complete() -> void :
	var finished_last: bool = GameState.quest_index == GameState.QUESTS.size() - 1
	if GameState.turn_in_quest():
		AudioManager.play_sfx("quest_complete")
		if finished_last:
			hud.close_panel_from_click()
			hud.show_victory()
			return
	_refresh()

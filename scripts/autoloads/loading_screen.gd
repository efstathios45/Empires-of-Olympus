extends CanvasLayer
















const PRELOAD_PATHS: PackedStringArray = [

	"res://scenes/game_world.tscn", 
	"res://scenes/main.tscn", 
	"res://scenes/ui/hud.tscn", 
	"res://scenes/ui/main_menu.tscn", 
	"res://assets/3d_vfx/StylizedHitFX/effects/hit/vfx_hit_01.tscn", 
	"res://assets/3d_vfx/StylizedHitFX/effects/strike/vfx_strike_01.tscn", 
	"res://assets/3d_vfx/impact_explosions/effects/explosion/vfx_explosion_01.tscn", 

	"res://assets/3d_vfx/impact_explosions/src/material/explosion/explosion_smoke.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/circle/circle_01.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/circle/circle_02.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/circle/circle_03.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/line/line_x_01.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/line/line_y_01.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/line/line_y_02.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_01.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_02.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_03.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_04.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_in_01.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_in_02.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_in_03.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_in_04.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_out_01.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_out_02.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_out_03.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/ring/ring_out_04.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/square/square_01.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/square/square_02.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/square/square_03.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/square/square_04.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/up/right_01.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/up/up_01.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/up/up_02.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/up/up_03.tres", 
	"res://assets/3d_vfx/shared/texture/gradient/up/up_04.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_euclidean_01.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_euclidean_02.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_euclidean_03.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_inverted_01.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_inverted_02.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_inverted_03.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_manhattan_01.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_manhattan_02.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_manhattan_03.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_warped_01.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_warped_02.tres", 
	"res://assets/3d_vfx/shared/texture/noise/cell/cell_warped_03.tres", 
	"res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_01.tres", 
	"res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_02.tres", 
	"res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_03.tres", 
	"res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_simple_01.tres", 
	"res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_simple_02.tres", 
	"res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_simple_03.tres", 
	"res://assets/3d_vfx/shared/texture/noise/warp/warp_blotch_01.tres", 
	"res://assets/3d_vfx/shared/texture/noise/warp/warp_blotch_02.tres", 
	"res://assets/3d_vfx/shared/texture/noise/warp/warp_brush_01.tres", 
	"res://assets/3d_vfx/shared/texture/noise/warp/warp_brush_02.tres", 
	"res://assets/3d_vfx/shared/texture/noise/warp/warp_ridge_01.tres", 
	"res://assets/3d_vfx/shared/texture/noise/warp/warp_ridge_02.tres", 
	"res://assets/3d_vfx/shared/texture/noise/web/web_01.tres", 
	"res://assets/3d_vfx/shared/texture/noise/web/web_02.tres", 
	"res://assets/3d_vfx/shared/texture/noise/web/web_03.tres", 
	"res://assets/3d_vfx/shared/texture/noise/web/web_warped_01.tres", 
	"res://assets/3d_vfx/shared/texture/noise/web/web_warped_02.tres", 
	"res://assets/3d_vfx/shared/texture/noise/web/web_warped_03.tres", 
	"res://assets/fonts/cinzel.ttf", 
	"res://assets/textures/skyboxes/olympus_sky_sky.tres", 
	"res://assets/ui/btn_blank.png", 
	"res://assets/ui/btn_blank.tres", 
	"res://assets/ui/btn_blank_alt.png", 
	"res://assets/ui/btn_blank_alt.tres", 
	"res://assets/ui/btn_primary.png", 
	"res://assets/ui/btn_primary.tres", 
	"res://assets/ui/btn_secondary.png", 
	"res://assets/ui/btn_secondary.tres", 
	"res://assets/ui/icon_anvil.png", 
	"res://assets/ui/icon_boot.png", 
	"res://assets/ui/icon_clan.png", 
	"res://assets/ui/icon_gem.png", 
	"res://assets/ui/icon_gold.png", 
	"res://assets/ui/icon_health.png", 
	"res://assets/ui/icon_laurel.png", 
	"res://assets/ui/icon_mana.png", 
	"res://assets/ui/icon_map.png", 
	"res://assets/ui/icon_potion.png", 
	"res://assets/ui/icon_quest.png", 
	"res://assets/ui/icon_scroll.png", 
	"res://assets/ui/icon_shield.png", 
	"res://assets/ui/icon_skull.png", 
	"res://assets/ui/icon_sword.png", 
	"res://assets/ui/loading_bar_accent.tres", 
	"res://assets/ui/loading_screen.png", 
	"res://assets/ui/panel_bar.png", 
	"res://assets/ui/panel_bar.tres", 
	"res://assets/ui/panel_card.png", 
	"res://assets/ui/panel_card.tres", 
	"res://assets/ui/panel_hud.png", 
	"res://assets/ui/panel_hud.tres", 
	"res://assets/ui/panel_main.png", 
	"res://assets/ui/panel_main.tres", 
	"res://assets/ui/panel_scroll.png", 
	"res://assets/ui/panel_scroll.tres", 
	"res://assets/ui/panel_tooltip.png", 
	"res://assets/ui/panel_tooltip.tres", 
	"res://assets/ui/theme.tres", 
	"res://assets/ui/title_poster.webp", 
	"res://assets/ui/title_poster_sm.webp", 
	"res://assets/ui/wordmark_title.png", 

	"res://assets/3d_vfx/shared/texture/cracks_01.png", 
	"res://assets/3d_vfx/shared/texture/cracks_emission_01.png", 
	"res://assets/3d_vfx/shared/texture/flare/flare_01.png", 
	"res://assets/3d_vfx/shared/texture/flare/flare_02.png", 
	"res://assets/3d_vfx/shared/texture/flare/flare_03.png", 
	"res://assets/3d_vfx/shared/texture/flare/flare_04.png", 
	"res://assets/3d_vfx/shared/texture/flash/flash_01.png", 
	"res://assets/3d_vfx/shared/texture/flash/flash_02.png", 
	"res://assets/3d_vfx/shared/texture/flash/flash_03.png", 
	"res://assets/3d_vfx/shared/texture/flash/flash_04.png", 
	"res://assets/3d_vfx/shared/texture/flash_front/flash_front_01.png", 
	"res://assets/3d_vfx/shared/texture/flash_front/flash_front_02.png", 
	"res://assets/3d_vfx/shared/texture/flash_front/flash_front_03.png", 
	"res://assets/3d_vfx/shared/texture/flash_front/flash_front_04.png", 
	"res://assets/3d_vfx/shared/texture/flash_front/flash_front_05.png", 
	"res://assets/3d_vfx/shared/texture/flash_front/flash_front_06.png", 
	"res://assets/3d_vfx/shared/texture/flash_long/flash_long_01.png", 
	"res://assets/3d_vfx/shared/texture/flash_long/flash_long_02.png", 
	"res://assets/3d_vfx/shared/texture/flash_long/flash_long_03.png", 
	"res://assets/3d_vfx/shared/texture/flash_long/flash_long_04.png", 
	"res://assets/3d_vfx/shared/texture/flash_side/flash_side_01.png", 
	"res://assets/3d_vfx/shared/texture/flash_side/flash_side_02.png", 
	"res://assets/3d_vfx/shared/texture/flash_side/flash_side_03.png", 
	"res://assets/3d_vfx/shared/texture/flash_side/flash_side_04.png", 
	"res://assets/3d_vfx/shared/texture/flash_side/flash_side_05.png", 
	"res://assets/3d_vfx/shared/texture/flash_side/flash_side_06.png", 
	"res://assets/3d_vfx/shared/texture/icon/pickup_icons/batch_health_icon.png", 
	"res://assets/3d_vfx/shared/texture/icon/pickup_icons/batch_heart_icon.png", 
	"res://assets/3d_vfx/shared/texture/icon/pickup_icons/batch_lightning_icon.png", 
	"res://assets/3d_vfx/shared/texture/icon/pickup_icons/batch_shield_icon.png", 
	"res://assets/3d_vfx/shared/texture/placeholder.png", 
	"res://assets/3d_vfx/shared/texture/spirals/spirals_01.png", 
	"res://assets/3d_vfx/shared/texture/spirals/spirals_02.png", 
	"res://assets/3d_vfx/shared/texture/spirals/spirals_03.png", 
	"res://assets/3d_vfx/shared/texture/spirals/spirals_04.png", 
	"res://assets/3d_vfx/shared/texture/spirals/spirals_05.png", 
	"res://assets/3d_vfx/shared/texture/spirals/spirals_06.png", 
	"res://assets/grass/blades/arc_bushy.png", 
	"res://assets/grass/blades/arc_few.png", 
	"res://assets/grass/blades/arc_full.png", 
	"res://assets/grass/blades/arc_some.png", 
	"res://assets/grass/blades/blade_bushy.png", 
	"res://assets/grass/blades/blade_few.png", 
	"res://assets/grass/blades/blade_full.png", 
	"res://assets/grass/blades/blade_some.png", 
	"res://assets/grass/blades/broad_bushy.png", 
	"res://assets/grass/blades/broad_few.png", 
	"res://assets/grass/blades/broad_full.png", 
	"res://assets/grass/blades/broad_some.png", 
	"res://assets/grass/blades/reed_bushy.png", 
	"res://assets/grass/blades/reed_few.png", 
	"res://assets/grass/blades/reed_full.png", 
	"res://assets/grass/blades/reed_some.png", 
	"res://assets/grass/blades/tuftwild_bushy.png", 
	"res://assets/grass/blades/tuftwild_few.png", 
	"res://assets/grass/blades/tuftwild_full.png", 
	"res://assets/grass/blades/tuftwild_some.png", 
	"res://assets/grass/textures/tesana-grass.png", 
	"res://assets/terrain/grass/grass_albedo.png", 
	"res://assets/terrain/grass/grass_depth.png", 
	"res://assets/terrain/grass/grass_normal.png", 
	"res://assets/terrain/grass/grass_roughness.png", 
	"res://assets/terrain/grass/packed_albedo_bump.png", 
	"res://assets/terrain/grass/packed_normal_roughness.png", 
	"res://assets/terrain/rocks/Rocks07_col.png", 
	"res://assets/terrain/rocks/Rocks07_disp.jpg", 
	"res://assets/terrain/rocks/Rocks07_nrm.jpg", 
	"res://assets/terrain/rocks/Rocks07_rgh.jpg", 
	"res://assets/terrain/rocks/packed_albedo_bump.png", 
	"res://assets/terrain/rocks/packed_normal_roughness.png", 
	"res://assets/terrain/sand/packed_albedo_bump.png", 
	"res://assets/terrain/sand/packed_normal_roughness.png", 
	"res://assets/terrain/sand/sand_albedo.png", 
	"res://assets/terrain/sand/sand_depth.png", 
	"res://assets/terrain/sand/sand_normal.png", 
	"res://assets/terrain/sand/sand_roughness.png", 
	"res://assets/textures/backgrounds/class_hoplite.png", 
	"res://assets/textures/backgrounds/class_magos.png", 
	"res://assets/textures/backgrounds/class_toxotes.png", 
	"res://assets/textures/backgrounds/empire_athens.png", 
	"res://assets/textures/backgrounds/empire_corinth.png", 
	"res://assets/textures/backgrounds/empire_map_hellas.png", 
	"res://assets/textures/backgrounds/empire_sparta.png", 
	"res://assets/textures/metal/bronze_metal.png", 
	"res://assets/textures/nature/mediterranean_ground.png", 
	"res://assets/textures/nature/terrain_dirt.png", 
	"res://assets/textures/skyboxes/olympus_sky_skybox.png", 
	"res://assets/textures/stone/terrain_rock.png", 
	"res://assets/textures/stone/white_marble.png", 
	"res://assets/textures/stone/greek_pebble_mosaic.png", 
	"res://assets/textures/stone/old_mosaic_floor_cc0.png", 
	"res://assets/props/decorations/free_antique_ceramic_vase_01/antique_ceramic_vase_01.glb", 
	"res://assets/props/decorations/free_marble_bust_01/marble_bust_01.glb", 
	"res://assets/trees/bark/acacia_bark.png", 
	"res://assets/trees/foliage/savanna_dry.png", 

	"res://assets/audio/ambient/ambient_ancient_greek_city_plaza_city_crowd.mp3", 
	"res://assets/audio/ambient/ambient_greek_countryside_aegean_wind.mp3", 
	"res://assets/audio/music/jingle_game_over_defeat_dirge.mp3", 
	"res://assets/audio/music/jingle_level_complete_victory_fanfare.mp3", 
	"res://assets/audio/music/music_boss_minotaur_battle.mp3", 
	"res://assets/audio/music/music_exploration_city_agora_theme.mp3", 
	"res://assets/audio/music/music_exploration_olympus_exploration.mp3", 
	"res://assets/audio/music/music_menu_menu_theme.mp3", 
	"res://assets/audio/sfx/enemy/enemy_enemy_growl.mp3", 
	"res://assets/audio/sfx/enemy/enemy_harpy_screech.mp3", 
	"res://assets/audio/sfx/enemy/enemy_minotaur_roar.mp3", 
	"res://assets/audio/sfx/enemy/enemy_oracle_whisper.mp3", 
	"res://assets/audio/sfx/environment/environment_oracle_pulse.mp3", 
	"res://assets/audio/sfx/pickup/pickup_gold_pickup.mp3", 
	"res://assets/audio/sfx/pickup/pickup_potion_drink.mp3", 
	"res://assets/audio/sfx/player/player_dodge_roll.mp3", 
	"res://assets/audio/sfx/player/player_footstep_dirt.mp3", 
	"res://assets/audio/sfx/player/player_footstep_grass.mp3", 
	"res://assets/audio/sfx/player/player_footstep_stone.mp3", 
	"res://assets/audio/sfx/player/player_hit_flesh.mp3", 
	"res://assets/audio/sfx/player/player_level_up.mp3", 
	"res://assets/audio/sfx/player/player_thunderbolt_cast.mp3", 
	"res://assets/audio/sfx/ui/ui_quest_complete.mp3", 
	"res://assets/audio/sfx/ui/ui_refine_fail.mp3", 
	"res://assets/audio/sfx/ui/ui_refine_success.mp3", 
	"res://assets/audio/sfx/ui/ui_ui_click.mp3", 
	"res://assets/audio/sfx/ui/ui_ui_confirm.mp3", 
	"res://assets/audio/sfx/weapon/weapon_spear_clash.mp3", 
	"res://assets/audio/sfx/weapon/weapon_sword_swing.mp3", 

	"res://assets/animations/humanoid_profile_bone_map.tres", 
	"res://assets/characters/greek_smith/greek_smith.glb", 
	"res://assets/characters/blacksmith_npc/blacksmith_npc.glb", 
	"res://assets/characters/blacksmith_npc/blacksmith_npc_animations.tres", 
	"res://assets/characters/boar_enemy/boar_enemy.glb", 
	"res://assets/characters/boar_enemy/boar_enemy_animations.tres", 
	"res://assets/characters/centaur_enemy/centaur_enemy.glb", 
	"res://assets/characters/centaur_enemy/centaur_enemy_animations.tres", 
	"res://assets/characters/greek_merchant/greek_merchant.glb", 
	"res://assets/characters/greek_citizen_woman/greek_citizen_woman.glb", 
	"res://assets/characters/greek_guard/greek_guard.glb", 
	"res://assets/characters/greek_hoplite/greek_hoplite.glb", 
	"res://assets/characters/greek_oracle/greek_oracle.glb", 
	"res://assets/characters/citizen_merchant/citizen_merchant.glb", 
	"res://assets/characters/citizen_merchant/citizen_merchant_animations.tres", 
	"res://assets/characters/citizen_woman/citizen_woman.glb", 
	"res://assets/characters/citizen_woman/citizen_woman_animations.tres", 
	"res://assets/characters/city_guard/city_guard.glb", 
	"res://assets/characters/city_guard/city_guard_animations.tres", 
	"res://assets/characters/gorgon_enemy/gorgon_enemy.glb", 
	"res://assets/characters/gorgon_enemy/gorgon_enemy_animations.tres", 
	"res://assets/characters/harpy_enemy/harpy_enemy.glb", 
	"res://assets/characters/harpy_enemy/harpy_enemy_animations.tres", 
	"res://assets/characters/minotaur_boss/minotaur_boss.glb", 
	"res://assets/characters/minotaur_boss/minotaur_boss_animations.tres", 
	"res://assets/characters/oracle_priestess/oracle_priestess.glb", 
	"res://assets/characters/oracle_priestess/oracle_priestess_animations.tres", 
	"res://assets/characters/satyr_enemy/satyr_enemy.glb", 
	"res://assets/characters/satyr_enemy/satyr_enemy_animations.tres", 
	"res://assets/characters/spartan_hoplite/spartan_hoplite.glb", 
	"res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres", 
	"res://assets/characters/wolf_enemy/wolf_enemy.glb", 
	"res://assets/characters/wolf_enemy/wolf_enemy_animations.tres", 
	"res://assets/environment/buildings/agora_market_stall.glb", 
	"res://assets/environment/buildings/greek_stoa_colonnade.glb", 
	"res://assets/environment/buildings/greek_temple.glb", 
	"res://assets/environment/buildings/greek_townhouse.glb", 
	"res://assets/environment/obstacles/olive_cart.glb", 
	"res://assets/environment/obstacles/training_dummy.glb", 
	"res://assets/environment/rocks/cliff_rock.glb", 
	"res://assets/environment/structures/arena_gate.glb", 
	"res://assets/environment/structures/brazier_flame.glb", 
	"res://assets/environment/structures/broken_ruins.glb", 
	"res://assets/environment/structures/city_gate_arch.glb", 
	"res://assets/environment/structures/marble_column.glb", 
	"res://assets/environment/structures/marble_fountain.glb", 
	"res://assets/props/containers/amphora.glb", 
	"res://assets/props/containers/treasure_chest.glb", 
	"res://assets/props/decorations/greek_statue.glb", 
	"res://assets/props/furniture/marble_altar.glb", 
	"res://assets/props/items/oracle_stone.glb", 
	"res://assets/props/tools/blacksmith_anvil.glb", 
	"res://assets/props/weapons/cretan_bow.glb", 
	"res://assets/props/weapons/dory_spear.glb", 
	"res://assets/props/weapons/theurgist_staff.glb", 
]




const DEFAULT_ACCENT: = Color(0.96, 0.7, 0.45, 1.0)
const DEFAULT_BG: = Color(0.08, 0.08, 0.1, 0.85)

var _cache: Dictionary = {}
var _preloaded: bool = false
var _busy: bool = false
var _vfx_warmed: bool = false

var _root: Control
var _progress: ProgressBar
var _status: Label


func _ready() -> void :
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
















func _resolve_accent() -> Color:
	if ResourceLoader.exists("res://assets/ui/loading_bar_accent.tres"):
		var sb: = load("res://assets/ui/loading_bar_accent.tres") as StyleBoxFlat
		if sb:
			return sb.bg_color
	if ResourceLoader.exists("res://assets/ui/theme.tres"):
		var t: = load("res://assets/ui/theme.tres") as Theme
		if t:
			var fill: = t.get_stylebox("fill", "ProgressBar") as StyleBoxFlat
			if fill:
				return fill.bg_color
	return DEFAULT_ACCENT


func _build_ui() -> void :
	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE



	var bg: = ColorRect.new()
	bg.color = Color.BLACK
	_root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


	if ResourceLoader.exists("res://assets/ui/loading_screen.png"):
		var img: = TextureRect.new()
		img.texture = load("res://assets/ui/loading_screen.png")
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_root.add_child(img)
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


	var vignette: = ColorRect.new()
	vignette.color = Color(0, 0, 0, 0.3)
	_root.add_child(vignette)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)



	if ResourceLoader.exists("res://assets/ui/wordmark_title.png"):
		var wm: = TextureRect.new()
		wm.texture = load("res://assets/ui/wordmark_title.png")
		wm.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wm.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		_root.add_child(wm)
		wm.anchor_left = 0.5
		wm.anchor_right = 0.5
		wm.anchor_top = 0.0
		wm.anchor_bottom = 0.0
		wm.offset_left = -450
		wm.offset_right = 450
		wm.offset_top = 80
		wm.offset_bottom = 380



	var band: = Control.new()
	_root.add_child(band)
	band.anchor_left = 0.5
	band.anchor_right = 0.5
	band.anchor_top = 1.0
	band.anchor_bottom = 1.0
	band.offset_left = -360
	band.offset_right = 360
	band.offset_top = -160
	band.offset_bottom = -40

	var vbox: = VBoxContainer.new()
	band.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)

	_status = Label.new()
	_status.text = "Loading..."
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status)





	var accent: = _resolve_accent()
	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 22)
	var pb_bg: = StyleBoxFlat.new()
	pb_bg.bg_color = DEFAULT_BG
	pb_bg.set_corner_radius_all(6)
	var pb_fill: = StyleBoxFlat.new()
	pb_fill.bg_color = accent
	pb_fill.set_corner_radius_all(6)
	_progress.add_theme_stylebox_override("background", pb_bg)
	_progress.add_theme_stylebox_override("fill", pb_fill)
	vbox.add_child(_progress)


func _show() -> void :
	visible = true
	set_progress(0.0)


func _hide() -> void :
	visible = false


func set_progress(p: float) -> void :
	if _progress:
		_progress.value = clamp(p, 0.0, 1.0)
	if _status:
		_status.text = "Loading... %d%%" % int(p * 100.0)




func preload_and_change_scene(scene_path: String, min_display: float = 1.5) -> void :
	if _busy: return
	_busy = true
	_show()
	var t0: = Time.get_ticks_msec()
	await get_tree().process_frame
	await get_tree().process_frame
	if not _preloaded:
		await _run_preload_sequence()
		_preloaded = true
	await _change_scene_to(scene_path)
	await _vfx_warmup()
	var elapsed: = float(Time.get_ticks_msec() - t0) / 1000.0
	if elapsed < min_display:
		await get_tree().create_timer(min_display - elapsed).timeout
	_hide()
	_busy = false




func change_scene(scene_path: String, min_display: float = 0.6) -> void :
	if _busy: return
	_busy = true
	_show()
	var t0: = Time.get_ticks_msec()
	await get_tree().process_frame
	await get_tree().process_frame
	await _change_scene_to(scene_path)
	var elapsed: = float(Time.get_ticks_msec() - t0) / 1000.0
	if elapsed < min_display:
		await get_tree().create_timer(min_display - elapsed).timeout
	_hide()
	_busy = false



















func _run_preload_sequence() -> void :
	var total: = PRELOAD_PATHS.size()
	if total == 0:
		set_progress(0.92)
		return
	for i in total:
		var path: = PRELOAD_PATHS[i]
		if _cache.has(path) or not ResourceLoader.exists(path):
			set_progress(float(i + 1) / float(total) * 0.92)
			await get_tree().process_frame
			continue
		var res: = load(path)
		if res:
			_cache[path] = res
		else:
			push_warning("LoadingScreen preload failed: " + path)

		set_progress(float(i + 1) / float(total) * 0.92)
		await get_tree().process_frame


func _change_scene_to(scene_path: String) -> void :
	var packed: = _cache.get(scene_path) as PackedScene
	if packed:
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file(scene_path)
	set_progress(1.0)
	await get_tree().process_frame
	await get_tree().process_frame



















func _vfx_warmup() -> void :
	if _vfx_warmed:
		return
	_vfx_warmed = true
	if not OS.has_feature("web"):
		return
	var scene: = get_tree().current_scene
	var cam: = get_viewport().get_camera_3d()
	if scene == null or cam == null:
		return
	var vfx_paths: Array[String] = []
	for p in PRELOAD_PATHS:
		if p.ends_with(".tscn") and ("/3d_vfx/" in p) and ("/effects/" in p):
			vfx_paths.append(p)
	if vfx_paths.is_empty():
		return
	_status.text = "Preparing effects..."


	var holder: = Node3D.new()
	scene.add_child(holder)
	var spawn_at: = cam.global_position - cam.global_transform.basis.z * 3.0
	for path in vfx_paths:
		var ps: = _cache.get(path) as PackedScene
		if ps == null and ResourceLoader.exists(path):
			ps = load(path) as PackedScene
		if ps == null:
			continue
		var inst: Node = ps.instantiate()



		if "autoplay" in inst:
			inst.set("autoplay", false)
		if "proximity_fade" in inst:
			inst.set("proximity_fade", false)
		holder.add_child(inst)
		if inst is Node3D:
			inst.global_position = spawn_at
		if inst.has_node("AnimationPlayer") and inst.has_method("play"):
			inst.call("play")
		await get_tree().process_frame
		await get_tree().process_frame
		if is_instance_valid(inst):
			inst.queue_free()
	if is_instance_valid(holder):
		holder.queue_free()

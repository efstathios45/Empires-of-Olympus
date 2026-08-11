extends Node
## AudioManager — music, SFX pools, and ambient playback. Autoload.

var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 10

const MUSIC := {
	"menu": "res://assets/audio/music/music_menu_menu_theme.mp3",
	"exploration": "res://assets/audio/music/music_exploration_olympus_exploration.mp3",
	"city": "res://assets/audio/music/music_exploration_city_agora_theme.mp3",
	"boss": "res://assets/audio/music/music_boss_minotaur_battle.mp3",
	"victory": "res://assets/audio/music/jingle_level_complete_victory_fanfare.mp3",
	"defeat": "res://assets/audio/music/jingle_game_over_defeat_dirge.mp3",
}

const SFX := {
	"spear_clash": "res://assets/audio/sfx/weapon/weapon_spear_clash.mp3",
	"sword_swing": "res://assets/audio/sfx/weapon/weapon_sword_swing.mp3",
	"hit_flesh": "res://assets/audio/sfx/player/player_hit_flesh.mp3",
	"level_up": "res://assets/audio/sfx/player/player_level_up.mp3",
	"refine_success": "res://assets/audio/sfx/ui/ui_refine_success.mp3",
	"refine_fail": "res://assets/audio/sfx/ui/ui_refine_fail.mp3",
	"gold_pickup": "res://assets/audio/sfx/pickup/pickup_gold_pickup.mp3",
	"dodge_roll": "res://assets/audio/sfx/player/player_dodge_roll.mp3",
	"footstep_dirt": "res://assets/audio/sfx/player/player_footstep_dirt.mp3",
	"footstep_stone": "res://assets/audio/sfx/player/player_footstep_stone.mp3",
	"footstep_grass": "res://assets/audio/sfx/player/player_footstep_grass.mp3",
	"quest_complete": "res://assets/audio/sfx/ui/ui_quest_complete.mp3",
	"enemy_growl": "res://assets/audio/sfx/enemy/enemy_enemy_growl.mp3",
	"thunderbolt": "res://assets/audio/sfx/player/player_thunderbolt_cast.mp3",
	"oracle_pulse": "res://assets/audio/sfx/environment/environment_oracle_pulse.mp3",
	"oracle_whisper": "res://assets/audio/sfx/enemy/enemy_oracle_whisper.mp3",
	"potion_drink": "res://assets/audio/sfx/pickup/pickup_potion_drink.mp3",
	"ui_click": "res://assets/audio/sfx/ui/ui_ui_click.mp3",
	"ui_confirm": "res://assets/audio/sfx/ui/ui_ui_confirm.mp3",
	# Per-creature attack / death — free OpenGameArt animal/monster samples.
	"wolf_attack": "res://assets/audio/sfx/enemy/creatures/lykaon_attack.mp3",
	"wolf_death": "res://assets/audio/sfx/enemy/creatures/lykaon_death.mp3",
	"wolf_black_attack": "res://assets/audio/sfx/enemy/creatures/stygian_attack.mp3",
	"wolf_black_death": "res://assets/audio/sfx/enemy/creatures/stygian_death.mp3",
	"wolf_dire_attack": "res://assets/audio/sfx/enemy/creatures/erymanthian_attack.mp3",
	"wolf_dire_death": "res://assets/audio/sfx/enemy/creatures/erymanthian_death.mp3",
	"boar_attack": "res://assets/audio/sfx/enemy/creatures/boar_attack.mp3",
	"boar_death": "res://assets/audio/sfx/enemy/creatures/boar_death.mp3",
	"satyr_attack": "res://assets/audio/sfx/enemy/creatures/satyr_attack.mp3",
	"satyr_death": "res://assets/audio/sfx/enemy/creatures/satyr_death.mp3",
	"harpy_attack": "res://assets/audio/sfx/enemy/creatures/harpy_attack.mp3",
	"harpy_death": "res://assets/audio/sfx/enemy/creatures/harpy_death.mp3",
	"harpy_screech": "res://assets/audio/sfx/enemy/creatures/harpy_screech_extra.mp3",
	"centaur_attack": "res://assets/audio/sfx/enemy/creatures/centaur_attack.mp3",
	"centaur_death": "res://assets/audio/sfx/enemy/creatures/centaur_death.mp3",
	"gorgon_attack": "res://assets/audio/sfx/enemy/creatures/gorgon_attack.mp3",
	"gorgon_death": "res://assets/audio/sfx/enemy/creatures/gorgon_death.mp3",
	"minotaur_attack": "res://assets/audio/sfx/enemy/creatures/minotaur_attack.mp3",
	"minotaur_death": "res://assets/audio/sfx/enemy/creatures/minotaur_death.mp3",
	"minotaur_roar": "res://assets/audio/sfx/enemy/creatures/minotaur_roar_extra.mp3",
	"stone_rise": "res://assets/audio/sfx/enemy/creatures/stone_rise.mp3",
	"stone_shatter": "res://assets/audio/sfx/enemy/creatures/stone_shatter.mp3",
}

const AMBIENT := {
	"wind": "res://assets/audio/ambient/ambient_greek_countryside_aegean_wind.mp3",
	"city_crowd": "res://assets/audio/ambient/ambient_ancient_greek_city_plaza_city_crowd.mp3",
}

## Key of the looping track currently playing ("" if none / a one-shot jingle).
var current_music: String = ""

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(music_player)
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "Master"
	ambient_player.volume_db = -14.0
	ambient_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(ambient_player)
	# One dedicated footstep voice so grass/dirt samples never stack into a
	# stampede when stride timing overlaps a long multi-hit WAV/MP3.
	footstep_player = AudioStreamPlayer.new()
	footstep_player.bus = "Master"
	footstep_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(footstep_player)
	for i in MAX_SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		# Web (4.3+) defaults to SAMPLE playback, which bypasses the bus
		# pipeline and silently ignores volume/fades. STREAM is required.
		p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(p)
		sfx_players.append(p)

func play_music(key: String, volume_db: float = -6.0) -> void:
	var path: String = MUSIC.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()
	current_music = key

func play_music_once(key: String, volume_db: float = -4.0) -> void:
	## Jingles: play once, do not loop back.
	var path: String = MUSIC.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_ambient(key: String) -> void:
	var path: String = AMBIENT.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if ambient_player.stream == stream and ambient_player.playing:
		return
	ambient_player.stream = stream
	ambient_player.play()

func stop_ambient() -> void:
	ambient_player.stop()

func play_sfx(key: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var path: String = SFX.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return

## Footsteps use a single voice — restart instead of stacking overlaps.
func play_footstep(key: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var path: String = SFX.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if footstep_player == null:
		play_sfx(key, volume_db, pitch)
		return
	footstep_player.stop()
	footstep_player.stream = stream
	footstep_player.volume_db = volume_db
	footstep_player.pitch_scale = pitch
	footstep_player.play()

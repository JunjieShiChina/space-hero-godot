extends Node

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_music := ""

const AUDIO := {
	"menu": "res://assets/audio/stagebg.mp3",
	"stage": "res://assets/audio/stagebg.mp3",
	"boss": "res://assets/audio/bossfight.mp3",
	"game_over": "res://assets/audio/gameover.mp3",
	"success": "res://assets/audio/success.mp3",
	"shoot": "res://assets/audio/biu.wav",
	"shoot2": "res://assets/audio/bullet2.wav",
	"laser": "res://assets/audio/laser.wav",
	"missile": "res://assets/audio/missile.wav",
	"explosion": "res://assets/audio/explosion.wav",
	"hit": "res://assets/audio/hit.wav",
	"coin": "res://assets/audio/getcoin.wav",
	"pickup": "res://assets/audio/pickup.wav",
	"select": "res://assets/audio/select.wav",
	"game_start": "res://assets/audio/gamestart.wav",
	"warning": "res://assets/audio/warning.wav",
	"consume": "res://assets/audio/shopping.mp3",
	"failed": "res://assets/audio/failed.wav",
	"settlement": "res://assets/audio/settlement.wav",
	"shield": "res://assets/audio/shieldtrigger.wav",
}

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	for i in 12:
		var player := AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)

func play_music(key: String) -> void:
	if current_music == key and music_player.playing:
		return
	current_music = key
	var stream := _load_stream(key)
	if stream == null:
		return
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = -8.0
	music_player.play()

func stop_music() -> void:
	music_player.stop()
	current_music = ""

func play_sfx(key: String, volume_db := -3.0) -> void:
	var stream := _load_stream(key)
	if stream == null:
		return
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return

func _load_stream(key: String) -> AudioStream:
	if not AUDIO.has(key):
		return null
	return load(AUDIO[key])

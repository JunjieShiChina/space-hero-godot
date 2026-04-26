extends Node2D
class_name BossWarning

const DESIGN_POSITION := Vector2(852.0, 477.36)
const BLINK_INTERVAL := 0.5
const VISIBLE_DURATION := 5.0

@onready var _audio: AudioStreamPlayer = $WarningAudio

var _elapsed := 0.0
var _blink_timer := 0.0
var _letters_visible := true


func _ready() -> void:
	position = DisplaySettings.to_current(DESIGN_POSITION)
	scale = Vector2.ONE * DisplaySettings.scale_factor()
	_set_letters_visible(true)
	if _audio:
		_audio.finished.connect(_on_audio_finished)
		_audio.play()


func _process(delta: float) -> void:
	_elapsed += delta
	_blink_timer += delta
	if _blink_timer >= BLINK_INTERVAL:
		_blink_timer = 0.0
		_set_letters_visible(not _letters_visible)
	if _elapsed >= VISIBLE_DURATION:
		if _audio:
			_audio.stop()
		queue_free()


func _set_letters_visible(should_show: bool) -> void:
	_letters_visible = should_show
	for child in get_children():
		if child is Sprite2D:
			(child as Sprite2D).visible = should_show


func _on_audio_finished() -> void:
	if _elapsed < VISIBLE_DURATION and _audio:
		_audio.play()

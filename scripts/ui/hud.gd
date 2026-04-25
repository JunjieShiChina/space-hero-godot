extends CanvasLayer
class_name BattleHud

var coin_label: Label
var health_bar: ProgressBar
var weapon_label: Label
var boss_bar: ProgressBar
var warning_label: Label

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	coin_label = _label(DisplaySettings.to_current(Vector2(36, 27)), "COIN 0", DisplaySettings.scale_font_size(42))
	root.add_child(coin_label)
	weapon_label = _label(DisplaySettings.to_current(Vector2(36, 84)), "WEAPON Bullet1", DisplaySettings.scale_font_size(33))
	root.add_child(weapon_label)
	health_bar = ProgressBar.new()
	health_bar.position = DisplaySettings.to_current(Vector2(36, 138))
	health_bar.size = DisplaySettings.to_current(Vector2(390, 33))
	health_bar.max_value = GameData.max_health
	root.add_child(health_bar)
	boss_bar = ProgressBar.new()
	boss_bar.position = DisplaySettings.to_current(Vector2(585, 33))
	boss_bar.size = DisplaySettings.to_current(Vector2(750, 36))
	boss_bar.max_value = 1.0
	boss_bar.visible = false
	root.add_child(boss_bar)
	warning_label = _label(DisplaySettings.to_current(Vector2(0, 420)), "", DisplaySettings.scale_font_size(96))
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.size = Vector2(DisplaySettings.logical_size().x, DisplaySettings.scale_value(135))
	root.add_child(warning_label)
	GameData.changed.connect(refresh)
	refresh()

func refresh() -> void:
	coin_label.text = "COIN %d" % GameData.coin_count
	weapon_label.text = "WEAPON %s   SLOT %d/3   FRIENDS %d" % [GameData.current_bullet(), GameData.current_bullet_index + 1, GameData.friend_plane_count]
	health_bar.value = GameData.player_health

func set_player_health(value: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = value

func show_boss_bar(should_show: bool) -> void:
	boss_bar.visible = should_show
	boss_bar.value = 1.0

func update_boss(value: float) -> void:
	boss_bar.value = clamp(value, 0.0, 1.0)

func show_warning(text: String) -> void:
	warning_label.text = text
	warning_label.modulate = Color(1, 0.15, 0.1)
	var tween := create_tween()
	tween.set_loops(6)
	tween.tween_property(warning_label, "modulate:a", 0.25, 0.18)
	tween.tween_property(warning_label, "modulate:a", 1.0, 0.18)
	await tween.finished
	warning_label.text = ""

func _label(pos: Vector2, text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.75, 0.96, 1.0))
	return label

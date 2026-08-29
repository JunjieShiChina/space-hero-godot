extends CanvasLayer
class_name BattleHud

const HP_TEXTURES := [
	preload("res://assets/sprites/5HP Bar - 0.png"),
	preload("res://assets/sprites/5HP Bar - 1.png"),
	preload("res://assets/sprites/5HP Bar - 2.png"),
	preload("res://assets/sprites/5HP Bar - 3.png"),
	preload("res://assets/sprites/5HP Bar - 4.png"),
	preload("res://assets/sprites/5HP Bar - 5.png"),
]
const SLOT_TEXTURE := preload("res://assets/sprites/Blue.png")
const FRIEND_TEXTURE := preload("res://assets/sprites/friendplane.png")
const FIRE_RATE_TEXTURE := preload("res://assets/sprites/fire_rate_upgrade_icon.png")
const COIN_ICON_SCENE := preload("res://scenes/ui/coin_hud_icon.tscn")
const PIXEL_NUMBER_SCENE := preload("res://scenes/ui/pixel_number_display.tscn")
const HUD_FONT := preload("res://assets/font/STHUPO.TTF")
const COIN_COUNT_JUMP_DURATION := 1.0
const COIN_COUNT_MIN_STEP_RATE := 28.0
const BOTTOM_UI_ALPHA := 0.50
const SLOT_BACK_ALPHA := 0.50
const SLOT_ICON_ALPHA := 0.50
const SLOT_FRAME_ALPHA := 0.50
const BULLET_ICON_TEXTURES := {
	"Bullet1": preload("res://assets/sprites/bullet5.png"),
	"Bullet2": preload("res://assets/sprites/bullet4.png"),
	"BulletArrow": preload("res://assets/sprites/WyvernHornBow.png"),
	"BulletMissile": preload("res://assets/sprites/spr_missile.png"),
	"BulletLaser": preload("res://assets/sprites/bosslaser.png"),
	"BulletFire": preload("res://assets/sprites/bullet5.png"),
	"BulletYue": preload("res://assets/sprites/All_Fire_Bullet_Pixel_16x16_00.png"),
	"Bullet3": preload("res://assets/sprites/bullet6.png"),
	"FollowBullet": preload("res://assets/sprites/All_Fire_Bullet_Pixel_16x16_00.png"),
}
const BULLET_ICON_REGIONS := {
	"BulletYue": Rect2(576, 16, 16, 17),
	"FollowBullet": Rect2(96, 48, 16, 16),
}

const HEALTH_POS := Vector2(200, 1005)
const SHIELD_POS := Vector2(200, 958)
const SLOT_POSITIONS := [
	Vector2(900, 1000),
	Vector2(965, 1000),
	Vector2(1030, 1000),
]
const FIRE_RATE_ICON_POS := Vector2(812, 994)
const FIRE_RATE_LEVEL_POS := Vector2(836, 985)
const FRIEND_ICON_POS := Vector2(1498, 994)
const FRIEND_COUNT_POS := Vector2(1538, 968)
const COIN_ICON_POS := Vector2(1722, 994)
const COIN_COUNT_POS := Vector2(1756, 968)
const BOSS_BAR_POS := Vector2(38, 10)
const BOSS_BAR_SIZE := Vector2(1844, 40)

var _root: Control
var _health_sprite: Sprite2D
var _shield_sprite: Sprite2D
var _slot_frame: Panel
var _slot_nodes: Array[Sprite2D] = []
var _slot_icons: Array[Sprite2D] = []
var _slot_level_displays: Array[Node2D] = []
var _fire_rate_icon: Sprite2D
var _fire_rate_level_display: Node2D
var _friend_icon: Sprite2D
var _friend_count_display: Node2D
var _coin_icon: Node2D
var _coin_count_display: Node2D
var _boss_bar: Control
var _boss_bar_fill: ColorRect
var _boss_bar_top_shine: ColorRect
var _boss_bar_left_step: ColorRect
var _boss_bar_right_step: ColorRect
var _boss_bar_shadow_shape: Polygon2D
var _boss_bar_fill_shape: Polygon2D
var _boss_bar_shine_shape: Polygon2D
var _warning_label: Label
var _current_health := 1.0
var _current_max_health := 1.0
var _boss_bar_ratio := 1.0
var _coin_displayed_count := 0
var _coin_target_count := 0
var _coin_step_accum := 0.0
var _coin_step_rate := COIN_COUNT_MIN_STEP_RATE
var _shield_textures := []


func _ready() -> void:
	_current_health = GameData.player_health
	_current_max_health = GameData.max_health
	_setup_nodes()
	if not GameData.changed.is_connected(refresh):
		GameData.changed.connect(refresh)
	if not DisplaySettings.changed.is_connected(_layout):
		DisplaySettings.changed.connect(_layout)
	_coin_displayed_count = GameData.coin_count
	_coin_target_count = GameData.coin_count
	_layout()
	refresh()


func _process(delta: float) -> void:
	_update_coin_count_animation(delta)


func refresh() -> void:
	_update_health()
	_update_shield_bar()
	_update_slots()
	_set_fire_rate_level_text()
	_set_friend_count_text()
	_set_coin_count_target(GameData.coin_count)


func set_player_health(value: float, max_value: float) -> void:
	_current_health = value
	_current_max_health = max_value
	_update_health()


func show_boss_bar(should_show: bool) -> void:
	_boss_bar.visible = should_show
	_boss_bar_ratio = 1.0
	_apply_boss_bar_ratio()


func update_boss(value: float) -> void:
	_boss_bar_ratio = clamp(value, 0.0, 1.0)
	_apply_boss_bar_ratio()


func show_warning(text: String) -> void:
	_warning_label.text = text
	_warning_label.modulate = Color(1, 0.15, 0.1)
	var tween := create_tween()
	tween.set_loops(6)
	tween.tween_property(_warning_label, "modulate:a", 0.25, 0.18)
	tween.tween_property(_warning_label, "modulate:a", 1.0, 0.18)
	await tween.finished
	_warning_label.text = ""


func flash_coin_count() -> void:
	if _coin_count_display == null:
		return
	var tween := create_tween()
	tween.set_loops(5)
	tween.tween_property(_coin_count_display, "modulate", Color(1, 0.15, 0.1, BOTTOM_UI_ALPHA), 0.06)
	tween.tween_property(_coin_count_display, "modulate", Color(1, 1, 1, BOTTOM_UI_ALPHA), 0.08)


func flash_current_weapon_slot() -> void:
	var index := clampi(GameData.current_bullet_index, 0, _slot_nodes.size() - 1)
	var nodes: Array[CanvasItem] = []
	if index < _slot_nodes.size():
		nodes.append(_slot_nodes[index])
	if index < _slot_icons.size():
		nodes.append(_slot_icons[index])
	if index < _slot_level_displays.size():
		nodes.append(_slot_level_displays[index])
	if _slot_frame:
		nodes.append(_slot_frame)
	_flash_status_nodes(nodes)


func flash_friend_status() -> void:
	var nodes: Array[CanvasItem] = []
	if _friend_icon:
		nodes.append(_friend_icon)
	if _friend_count_display:
		nodes.append(_friend_count_display)
	_flash_status_nodes(nodes)


func flash_fire_rate_status() -> void:
	var nodes: Array[CanvasItem] = []
	if _fire_rate_icon:
		nodes.append(_fire_rate_icon)
	if _fire_rate_level_display:
		nodes.append(_fire_rate_level_display)
	_flash_status_nodes(nodes)


func _setup_nodes() -> void:
	if has_node("Root"):
		_bind_scene_nodes()
	else:
		_build_nodes()


func _bind_scene_nodes() -> void:
	_root = $Root
	_health_sprite = $Root/Health
	_ensure_shield_sprite()
	_slot_nodes = [
		$Root/Slot0,
		$Root/Slot1,
		$Root/Slot2,
	]
	_slot_icons = [
		$Root/SlotIcon0,
		$Root/SlotIcon1,
		$Root/SlotIcon2,
	]
	_ensure_slot_level_displays()
	_slot_frame = $Root/SlotFrame
	_ensure_fire_rate_display()
	_friend_icon = $Root/FriendIcon
	_friend_count_display = _bind_pixel_display($Root/FriendCount, "FriendCount")
	_coin_icon = $Root/CoinIcon as Node2D
	_coin_count_display = _bind_pixel_display($Root/CoinCount, "CoinCount")
	var old_boss_bar := $Root/BossBar
	old_boss_bar.visible = false
	old_boss_bar.name = "BossBarOld"
	_ensure_boss_bar_nodes()
	_warning_label = $Root/Warning
	for slot in _slot_nodes:
		slot.texture = SLOT_TEXTURE
		slot.modulate = Color(0.55, 1.0, 1.0, SLOT_BACK_ALPHA)
	_apply_bottom_ui_alpha()
	_friend_icon.texture = FRIEND_TEXTURE
	_apply_label_theme(_warning_label, Color(1, 0.15, 0.1), 96)
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_bar.visible = false


func _build_nodes() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_health_sprite = Sprite2D.new()
	_health_sprite.name = "Health"
	_root.add_child(_health_sprite)
	_shield_sprite = Sprite2D.new()
	_shield_sprite.name = "ShieldHealth"
	_shield_sprite.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	_root.add_child(_shield_sprite)

	for i in SLOT_POSITIONS.size():
		var slot := Sprite2D.new()
		slot.name = "Slot%d" % i
		slot.texture = SLOT_TEXTURE
		slot.modulate = Color(0.55, 1.0, 1.0, SLOT_BACK_ALPHA)
		_root.add_child(slot)
		_slot_nodes.append(slot)

		var icon := Sprite2D.new()
		icon.name = "SlotIcon%d" % i
		_root.add_child(icon)
		_slot_icons.append(icon)

		var level_display := PIXEL_NUMBER_SCENE.instantiate() as Node2D
		level_display.name = "SlotLevel%d" % i
		level_display.z_index = 12
		level_display.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
		_root.add_child(level_display)
		_slot_level_displays.append(level_display)

	_slot_frame = Panel.new()
	_slot_frame.name = "SlotFrame"
	_root.add_child(_slot_frame)

	_fire_rate_icon = Sprite2D.new()
	_fire_rate_icon.name = "FireRateIcon"
	_fire_rate_icon.texture = FIRE_RATE_TEXTURE
	_fire_rate_icon.z_index = 11
	_root.add_child(_fire_rate_icon)
	_fire_rate_level_display = PIXEL_NUMBER_SCENE.instantiate() as Node2D
	_fire_rate_level_display.name = "FireRateLevel"
	_fire_rate_level_display.z_index = 12
	_root.add_child(_fire_rate_level_display)

	_friend_icon = Sprite2D.new()
	_friend_icon.name = "FriendIcon"
	_friend_icon.texture = FRIEND_TEXTURE
	_root.add_child(_friend_icon)
	_friend_count_display = PIXEL_NUMBER_SCENE.instantiate() as Node2D
	_friend_count_display.name = "FriendCount"
	_root.add_child(_friend_count_display)

	_coin_icon = COIN_ICON_SCENE.instantiate() as Node2D
	_coin_icon.name = "CoinIcon"
	_root.add_child(_coin_icon)
	_coin_count_display = PIXEL_NUMBER_SCENE.instantiate() as Node2D
	_coin_count_display.name = "CoinCount"
	_root.add_child(_coin_count_display)

	_ensure_boss_bar_nodes()
	_boss_bar.visible = false

	_warning_label = _make_label(Color(1, 0.15, 0.1), 96)
	_warning_label.name = "Warning"
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_warning_label)


func _layout() -> void:
	var scale := DisplaySettings.scale_factor()
	_health_sprite.position = DisplaySettings.to_current(HEALTH_POS)
	_health_sprite.scale = Vector2.ONE * 2.12 * scale
	_health_sprite.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	_shield_sprite.position = DisplaySettings.to_current(SHIELD_POS)
	_shield_sprite.scale = Vector2.ONE * 2.12 * scale
	_shield_sprite.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)

	for i in SLOT_POSITIONS.size():
		var slot := _slot_nodes[i]
		slot.position = DisplaySettings.to_current(SLOT_POSITIONS[i])
		slot.scale = Vector2.ONE * 0.36 * scale
		slot.modulate = Color(0.55, 1.0, 1.0, SLOT_BACK_ALPHA)
		_slot_icons[i].position = slot.position
		_slot_level_displays[i].position = slot.position + DisplaySettings.to_current(Vector2(12, 10))
		_slot_level_displays[i].scale = Vector2.ONE * 0.30 * scale
		_slot_level_displays[i].modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)

	var frame_size := DisplaySettings.to_current(Vector2(63, 63))
	_slot_frame.size = frame_size
	_slot_frame.position = DisplaySettings.to_current(SLOT_POSITIONS[GameData.current_bullet_index]) - frame_size * 0.5
	_slot_frame.add_theme_stylebox_override("panel", _make_slot_frame_style())
	_slot_frame.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)

	_fire_rate_icon.position = DisplaySettings.to_current(FIRE_RATE_ICON_POS)
	_fire_rate_icon.scale = Vector2.ONE * 0.50 * scale
	_fire_rate_icon.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	_fire_rate_level_display.position = DisplaySettings.to_current(FIRE_RATE_LEVEL_POS)
	_fire_rate_level_display.scale = Vector2.ONE * 0.36 * scale
	_fire_rate_level_display.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)

	_friend_icon.position = DisplaySettings.to_current(FRIEND_ICON_POS)
	_friend_icon.scale = Vector2.ONE * 1.02 * scale
	_friend_count_display.position = DisplaySettings.to_current(FRIEND_COUNT_POS)
	_friend_count_display.scale = Vector2.ONE * scale
	_friend_icon.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	_friend_count_display.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)

	_coin_icon.position = DisplaySettings.to_current(COIN_ICON_POS)
	_coin_icon.scale = Vector2.ONE * 3.05 * scale
	_coin_count_display.position = DisplaySettings.to_current(COIN_COUNT_POS)
	_coin_count_display.scale = Vector2.ONE * scale
	_coin_icon.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	_coin_count_display.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)

	_boss_bar.position = DisplaySettings.to_current(BOSS_BAR_POS)
	_boss_bar.size = DisplaySettings.to_current(BOSS_BAR_SIZE)
	_layout_boss_bar_children()

	_warning_label.position = DisplaySettings.to_current(Vector2(0, 420))
	_warning_label.size = Vector2(DisplaySettings.logical_size().x, DisplaySettings.scale_value(135))
	_set_label_size(_warning_label, 96)
	_update_shield_bar()
	_update_slots()
	_set_fire_rate_level_text()


func _update_health() -> void:
	var ratio := 0.0
	if _current_max_health > 0.0:
		ratio = clamp(_current_health / _current_max_health, 0.0, 1.0)
	var index := clampi(int(floor(float(HP_TEXTURES.size() - 1) * ratio + 0.001)), 0, HP_TEXTURES.size() - 1)
	_health_sprite.texture = HP_TEXTURES[index]


func _update_shield_bar() -> void:
	if _shield_sprite == null:
		return
	var ratio := GameData.shield_ratio()
	if ratio <= 0.0:
		_shield_sprite.visible = false
		return
	var index := clampi(int(floor(float(HP_TEXTURES.size() - 1) * ratio + 0.001)), 0, HP_TEXTURES.size() - 1)
	_shield_sprite.texture = _shield_bar_texture(index)
	_shield_sprite.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	_shield_sprite.visible = true


func _shield_bar_texture(index: int) -> Texture2D:
	while _shield_textures.size() < HP_TEXTURES.size():
		_shield_textures.append(null)
	if _shield_textures[index] != null:
		return _shield_textures[index]
	var source: Image = HP_TEXTURES[index].get_image()
	if source == null:
		return HP_TEXTURES[index]
	if source.is_compressed():
		source.decompress()
	for y in source.get_height():
		for x in source.get_width():
			var pixel: Color = source.get_pixel(x, y)
			if pixel.a <= 0.01:
				continue
			var brightness := clampf((pixel.r + pixel.g + pixel.b) / 3.0 * 1.45, 0.0, 1.0)
			var recolored := Color(0.60, 0.38, 0.00, pixel.a).lerp(Color(1.0, 0.92, 0.08, pixel.a), brightness)
			source.set_pixel(x, y, recolored)
	var texture := ImageTexture.create_from_image(source)
	_shield_textures[index] = texture
	return texture


func _update_slots() -> void:
	_slot_frame.position = DisplaySettings.to_current(SLOT_POSITIONS[GameData.current_bullet_index]) - _slot_frame.size * 0.5
	for i in _slot_icons.size():
		var bullet_type: String = GameData.bullet_slots[i]
		var icon := _slot_icons[i]
		var level_display := _slot_level_displays[i]
		if bullet_type == "EMPTY" or not BULLET_ICON_TEXTURES.has(bullet_type):
			icon.visible = false
			level_display.visible = false
			continue
		icon.visible = true
		icon.modulate = Color(1.0, 1.0, 1.0, SLOT_ICON_ALPHA)
		icon.texture = BULLET_ICON_TEXTURES[bullet_type]
		icon.region_enabled = BULLET_ICON_REGIONS.has(bullet_type)
		if icon.region_enabled:
			icon.region_rect = BULLET_ICON_REGIONS[bullet_type]
		icon.scale = Vector2.ONE * _bullet_icon_scale(bullet_type) * DisplaySettings.scale_factor()
		level_display.visible = true
		level_display.call("set_number", GameData.weapon_level(bullet_type))
		level_display.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)


func _bullet_icon_scale(bullet_type: String) -> float:
	match bullet_type:
		"BulletArrow":
			return 0.17
		"BulletMissile":
			return 0.55
		"BulletLaser":
			return 0.2
		"FollowBullet":
			return 1.8
		"BulletYue":
			return 1.5
		"Bullet1", "Bullet2":
			return 0.42
		"Bullet3":
			return 0.48
	return 0.32


func _set_coin_count_target(value: int) -> void:
	if _coin_count_display == null:
		return
	_coin_target_count = maxi(0, value)
	if _coin_displayed_count == _coin_target_count:
		_coin_count_display.call("set_number", _coin_displayed_count)
		_coin_step_accum = 0.0
		return
	var diff: int = int(abs(_coin_target_count - _coin_displayed_count))
	_coin_step_rate = maxf(COIN_COUNT_MIN_STEP_RATE, float(diff) / COIN_COUNT_JUMP_DURATION)


func _update_coin_count_animation(delta: float) -> void:
	if _coin_count_display == null or _coin_displayed_count == _coin_target_count:
		return
	_coin_step_accum += delta * _coin_step_rate
	var steps := int(_coin_step_accum)
	if steps <= 0:
		return
	_coin_step_accum -= float(steps)
	var direction: int = 1 if _coin_target_count > _coin_displayed_count else -1
	for _i in steps:
		if _coin_displayed_count == _coin_target_count:
			break
		_coin_displayed_count += direction
	_coin_count_display.call("set_number", _coin_displayed_count)


func _set_friend_count_text() -> void:
	if _friend_count_display == null:
		return
	_friend_count_display.call("set_text", "%d/%d" % [GameData.friend_plane_count, GameData.friend_plane_limit])


func _set_fire_rate_level_text() -> void:
	if _fire_rate_level_display == null:
		return
	_fire_rate_level_display.call("set_number", GameData.current_fire_rate_level())


func _bind_pixel_display(node: Node, display_name: String) -> Node2D:
	if node.has_method("set_number"):
		return node as Node2D
	node.name = "%sOld" % display_name
	node.queue_free()
	var display := PIXEL_NUMBER_SCENE.instantiate() as Node2D
	display.name = display_name
	_root.add_child(display)
	return display


func _ensure_fire_rate_display() -> void:
	_fire_rate_icon = _root.get_node_or_null("FireRateIcon") as Sprite2D
	if _fire_rate_icon == null:
		_fire_rate_icon = Sprite2D.new()
		_fire_rate_icon.name = "FireRateIcon"
		_fire_rate_icon.z_index = 11
		_root.add_child(_fire_rate_icon)
	_fire_rate_icon.texture = FIRE_RATE_TEXTURE
	_fire_rate_icon.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)

	_fire_rate_level_display = _root.get_node_or_null("FireRateLevel") as Node2D
	if _fire_rate_level_display == null:
		_fire_rate_level_display = PIXEL_NUMBER_SCENE.instantiate() as Node2D
		_fire_rate_level_display.name = "FireRateLevel"
		_fire_rate_level_display.z_index = 12
		_root.add_child(_fire_rate_level_display)
	_fire_rate_level_display.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)


func _ensure_shield_sprite() -> void:
	_shield_sprite = _root.get_node_or_null("ShieldHealth") as Sprite2D
	if _shield_sprite == null:
		_shield_sprite = Sprite2D.new()
		_shield_sprite.name = "ShieldHealth"
		_root.add_child(_shield_sprite)
	_shield_sprite.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	_shield_sprite.visible = false


func _ensure_slot_level_displays() -> void:
	_slot_level_displays.clear()
	for i in SLOT_POSITIONS.size():
		var display := _root.get_node_or_null("SlotLevel%d" % i) as Node2D
		if display == null:
			display = PIXEL_NUMBER_SCENE.instantiate() as Node2D
			display.name = "SlotLevel%d" % i
			_root.add_child(display)
		display.z_index = 12
		display.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
		_slot_level_displays.append(display)


func _apply_bottom_ui_alpha() -> void:
	if _health_sprite:
		_health_sprite.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	if _shield_sprite:
		_shield_sprite.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	for slot in _slot_nodes:
		slot.modulate = Color(0.55, 1.0, 1.0, SLOT_BACK_ALPHA)
	for icon in _slot_icons:
		icon.modulate = Color(1, 1, 1, SLOT_ICON_ALPHA)
	for display in _slot_level_displays:
		display.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	if _slot_frame:
		_slot_frame.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	if _fire_rate_icon:
		_fire_rate_icon.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	if _fire_rate_level_display:
		_fire_rate_level_display.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	if _friend_icon:
		_friend_icon.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	if _friend_count_display:
		_friend_count_display.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	if _coin_icon:
		_coin_icon.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)
	if _coin_count_display:
		_coin_count_display.modulate = Color(1, 1, 1, BOTTOM_UI_ALPHA)


func _flash_status_nodes(nodes: Array[CanvasItem]) -> void:
	for node in nodes:
		if node == null:
			continue
		var base_color := node.modulate
		var flash_color := Color(1.0, 0.12, 0.08, maxf(base_color.a, BOTTOM_UI_ALPHA))
		var tween := create_tween()
		tween.set_loops(5)
		tween.tween_property(node, "modulate", flash_color, 0.06)
		tween.tween_property(node, "modulate", base_color, 0.10)


func _ensure_boss_bar_nodes() -> void:
	_boss_bar = _root.get_node_or_null("BossBarRoot") as Control
	if _boss_bar == null:
		_boss_bar = Control.new()
		_boss_bar.name = "BossBarRoot"
		_boss_bar.clip_contents = true
		_root.add_child(_boss_bar)
	_ensure_boss_bar_shape_nodes()
	var back := _boss_bar.get_node_or_null("Back") as ColorRect
	if back == null:
		back = ColorRect.new()
		back.name = "Back"
		back.color = Color(0.0, 0.0, 0.0, 0.0)
		_boss_bar.add_child(back)
	else:
		back.color = Color(0.0, 0.0, 0.0, 0.0)
	_boss_bar_fill = _boss_bar.get_node_or_null("Fill") as ColorRect
	if _boss_bar_fill == null:
		_boss_bar_fill = ColorRect.new()
		_boss_bar_fill.name = "Fill"
		_boss_bar_fill.color = Color(0.86, 0.10, 0.17, 1.0)
		_boss_bar.add_child(_boss_bar_fill)
	_boss_bar_top_shine = _boss_bar.get_node_or_null("TopShine") as ColorRect
	if _boss_bar_top_shine == null:
		_boss_bar_top_shine = ColorRect.new()
		_boss_bar_top_shine.name = "TopShine"
		_boss_bar_top_shine.color = Color(1.0, 0.24, 0.30, 0.38)
		_boss_bar.add_child(_boss_bar_top_shine)
	_boss_bar_left_step = _boss_bar.get_node_or_null("LeftStep") as ColorRect
	if _boss_bar_left_step == null:
		_boss_bar_left_step = ColorRect.new()
		_boss_bar_left_step.name = "LeftStep"
		_boss_bar_left_step.color = Color(0.55, 0.0, 0.06, 1.0)
		_boss_bar.add_child(_boss_bar_left_step)
	else:
		_boss_bar_left_step.color = Color(0.55, 0.0, 0.06, 1.0)
	_boss_bar_right_step = _boss_bar.get_node_or_null("RightStep") as ColorRect
	if _boss_bar_right_step == null:
		_boss_bar_right_step = ColorRect.new()
		_boss_bar_right_step.name = "RightStep"
		_boss_bar_right_step.color = Color(0.55, 0.0, 0.06, 1.0)
		_boss_bar.add_child(_boss_bar_right_step)
	else:
		_boss_bar_right_step.color = Color(0.55, 0.0, 0.06, 1.0)
	_layout_boss_bar_children()


func _ensure_boss_bar_shape_nodes() -> void:
	var legacy_frame := _boss_bar.get_node_or_null("Frame")
	if legacy_frame:
		legacy_frame.queue_free()
	_boss_bar_shadow_shape = _boss_bar.get_node_or_null("ShadowShape") as Polygon2D
	if _boss_bar_shadow_shape == null:
		_boss_bar_shadow_shape = Polygon2D.new()
		_boss_bar_shadow_shape.name = "ShadowShape"
		_boss_bar_shadow_shape.color = Color(0.46, 0.0, 0.08, 0.92)
		_boss_bar.add_child(_boss_bar_shadow_shape)
	_boss_bar_fill_shape = _boss_bar.get_node_or_null("FillShape") as Polygon2D
	if _boss_bar_fill_shape == null:
		_boss_bar_fill_shape = Polygon2D.new()
		_boss_bar_fill_shape.name = "FillShape"
		_boss_bar_fill_shape.color = Color(0.92, 0.04, 0.12, 1.0)
		_boss_bar.add_child(_boss_bar_fill_shape)
	_boss_bar_shine_shape = _boss_bar.get_node_or_null("ShineShape") as Polygon2D
	if _boss_bar_shine_shape == null:
		_boss_bar_shine_shape = Polygon2D.new()
		_boss_bar_shine_shape.name = "ShineShape"
		_boss_bar_shine_shape.color = Color(1.0, 0.24, 0.28, 0.22)
		_boss_bar.add_child(_boss_bar_shine_shape)
	_boss_bar.move_child(_boss_bar_shadow_shape, 0)
	_boss_bar.move_child(_boss_bar_fill_shape, 1)
	_boss_bar.move_child(_boss_bar_shine_shape, 2)


func _layout_boss_bar_children() -> void:
	if _boss_bar == null:
		return
	var back := _boss_bar.get_node_or_null("Back") as ColorRect
	if back:
		back.position = Vector2.ZERO
		back.size = _boss_bar.size
		back.visible = false
	var fill_width := _boss_bar.size.x * _boss_bar_ratio
	var fill_left := (_boss_bar.size.x - fill_width) * 0.5
	var shadow_offset := DisplaySettings.scale_value(5.0)
	var shape_height := maxf(1.0, _boss_bar.size.y - shadow_offset)
	var fill_polygon := _boss_bar_polygon(fill_left, fill_width, shape_height)
	var shadow_polygon := _boss_bar_polygon(fill_left, fill_width, shape_height)
	var shine_height := DisplaySettings.scale_value(4.0)
	var shine_polygon := _boss_bar_shine_polygon(fill_left, fill_width, shine_height)
	if _boss_bar_shadow_shape:
		_boss_bar_shadow_shape.position = Vector2(0.0, shadow_offset)
		_boss_bar_shadow_shape.polygon = shadow_polygon
		_boss_bar_shadow_shape.visible = fill_width > 1.0
	if _boss_bar_fill_shape:
		_boss_bar_fill_shape.position = Vector2.ZERO
		_boss_bar_fill_shape.polygon = fill_polygon
		_boss_bar_fill_shape.visible = fill_width > 1.0
	if _boss_bar_shine_shape:
		_boss_bar_shine_shape.position = Vector2(0.0, DisplaySettings.scale_value(2.0))
		_boss_bar_shine_shape.polygon = shine_polygon
		_boss_bar_shine_shape.visible = fill_width > 1.0
	if _boss_bar_fill:
		_boss_bar_fill.visible = false
	if _boss_bar_top_shine:
		_boss_bar_top_shine.visible = false
	var step_width := DisplaySettings.scale_value(72.0)
	var step_height := DisplaySettings.scale_value(12.0)
	if _boss_bar_left_step:
		_boss_bar_left_step.visible = false
		_boss_bar_left_step.position = Vector2(fill_left, _boss_bar.size.y - step_height)
		_boss_bar_left_step.size = Vector2(minf(step_width, fill_width * 0.5), step_height)
	if _boss_bar_right_step:
		_boss_bar_right_step.visible = false
		var right_step_width := minf(step_width, fill_width * 0.5)
		_boss_bar_right_step.position = Vector2(fill_left + fill_width - right_step_width, _boss_bar.size.y - step_height)
		_boss_bar_right_step.size = Vector2(right_step_width, step_height)


func _boss_bar_polygon(left: float, width: float, height: float) -> PackedVector2Array:
	if width <= 0.0 or height <= 0.0:
		return PackedVector2Array()
	var step := minf(DisplaySettings.scale_value(78.0), width * 0.24)
	var top_height := height * 0.64
	var right := left + width
	return PackedVector2Array([
		Vector2(left, 0.0),
		Vector2(right, 0.0),
		Vector2(right, top_height),
		Vector2(right - step, top_height),
		Vector2(right - step, height),
		Vector2(left + step, height),
		Vector2(left + step, top_height),
		Vector2(left, top_height),
	])


func _boss_bar_shine_polygon(left: float, width: float, height: float) -> PackedVector2Array:
	if width <= 0.0 or height <= 0.0:
		return PackedVector2Array()
	var inset := minf(DisplaySettings.scale_value(10.0), width * 0.2)
	var right := left + width
	return PackedVector2Array([
		Vector2(left + inset, 0.0),
		Vector2(right - inset, 0.0),
		Vector2(right - inset, height),
		Vector2(left + inset, height),
	])


func _apply_boss_bar_ratio() -> void:
	if _boss_bar == null:
		return
	_layout_boss_bar_children()


func _make_label(color: Color, font_size: int) -> Label:
	var label := Label.new()
	_apply_label_theme(label, color, font_size)
	return label


func _apply_label_theme(label: Label, color: Color, font_size: int) -> void:
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", DisplaySettings.scale_font_size(font_size))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.07, 0.02, 0.0))
	label.add_theme_constant_override("outline_size", DisplaySettings.scale_font_size(3))


func _set_label_size(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", DisplaySettings.scale_font_size(font_size))
	label.add_theme_constant_override("outline_size", DisplaySettings.scale_font_size(3))


func _make_slot_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.35, 1.0, 1.0, 0.035)
	style.border_color = Color(0.82, 1.0, 1.0, SLOT_FRAME_ALPHA)
	style.set_border_width_all(DisplaySettings.scale_font_size(3))
	return style

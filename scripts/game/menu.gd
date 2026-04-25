extends Control

const UnityStage0Data = preload("res://generated/unity_stage0_menu_data.gd")
const MENU_FONT_TEXTURE := preload("res://assets/sprites/duat font corporal.png")
const TITLE_BASE_COLOR := Color(1.0, 0.56, 0.22, 1.0)
const TITLE_FLASH_COLOR := Color(1.0, 0.92, 0.20, 1.0)
const ITEM_SELECTED_MIN_ALPHA := 0.18
const ITEM_CONFIRM_MIN_ALPHA := 0.04
const ROCK_EXTRA_MULTIPLIER := 3
const MENU_ITEM_BASE_SCALE := 1.08
const SELECTOR_BASE_SCALE := 1.38
const TITLE_LAYOUT_SCALE := 0.78
const MENU_GLYPH_SPACING := 8.0
const TITLE_BASE_POSITION := Vector2(276, 196.5)
const RESOLUTION_CENTER_X := 960.0
const RESOLUTION_BASE_Y := 583.5
const SHIPS_BASE_POSITION := Vector2(270, 882)
const MENU_GLYPHS := {
	"0": Rect2(457, 427, 44, 51),
	"1": Rect2(43, 427, 22, 51),
	"2": Rect2(69, 427, 45, 51),
	"8": Rect2(359, 427, 45, 51),
	"K": Rect2(30, 278, 45, 52),
	"P": Rect2(284, 278, 45, 52),
}
const ROCK_INITIAL_LAYERS := [2, 1, 2, 0, 1, 2, 1, 0]
const ROCK_LAYER_DATA := [
	{
		"scale_min": 0.26,
		"scale_max": 0.42,
		"speed_min": 48.0,
		"speed_max": 78.0,
		"drift_min": -7.0,
		"drift_max": 7.0,
		"rotation_min": -0.05,
		"rotation_max": 0.06,
		"modulate": Color(0.50, 0.50, 0.56, 0.34),
		"z_index": 0,
		"spawn_y_min": -720.0,
		"spawn_y_max": -120.0,
		"spawn_margin": 90.0,
		"despawn_margin": 120.0,
	},
	{
		"scale_min": 0.62,
		"scale_max": 0.92,
		"speed_min": 110.0,
		"speed_max": 180.0,
		"drift_min": -20.0,
		"drift_max": 20.0,
		"rotation_min": -0.18,
		"rotation_max": 0.20,
		"modulate": Color(0.74, 0.70, 0.72, 0.68),
		"z_index": 0,
		"spawn_y_min": -540.0,
		"spawn_y_max": -90.0,
		"spawn_margin": 120.0,
		"despawn_margin": 150.0,
	},
	{
		"scale_min": 1.12,
		"scale_max": 1.72,
		"speed_min": 210.0,
		"speed_max": 340.0,
		"drift_min": -42.0,
		"drift_max": 42.0,
		"rotation_min": -0.34,
		"rotation_max": 0.38,
		"modulate": Color(0.98, 0.90, 0.84, 0.90),
		"z_index": 0,
		"spawn_y_min": -480.0,
		"spawn_y_max": -80.0,
		"spawn_margin": 260.0,
		"despawn_margin": 320.0,
	},
]

@onready var menu_items: Node2D = $MenuItems
@onready var resolution_item: Node2D = $MenuItems/Resolution
@onready var items: Array[CanvasItem] = [
	$MenuItems/NewGame,
	$MenuItems/Resolution,
	$MenuItems/QuitGame,
]
@onready var title: Node2D = $Title
@onready var selector: Sprite2D = $Selector
@onready var ships: Node2D = $Ships
@onready var rock_parent: Node2D = $Rocks
@onready var drifting_rocks: Array[Sprite2D] = [
	$Rocks/Rock1,
	$Rocks/Rock2,
	$Rocks/Rock3,
	$Rocks/Rock4,
	$Rocks/Rock5,
	$Rocks/Rock6,
	$Rocks/Rock7,
	$Rocks/Rock8,
]

var selected := 0
var rock_rng := RandomNumberGenerator.new()
var confirm_active := false
var confirm_timer := 0.0
var anim_time := 0.0


func _ready() -> void:
	AudioBus.play_music("menu")
	rock_rng.seed = 240424
	_apply_resolution_layout()
	_ensure_rock_count()
	_setup_rocks()
	_update_resolution_label()
	DisplaySettings.changed.connect(_on_display_settings_changed)
	_update_selection()


func _process(delta: float) -> void:
	anim_time += delta
	_update_title_flash()
	_update_item_flash(delta)
	_update_rocks(delta)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		selected = max(0, selected - 1)
		AudioBus.play_sfx("select")
		_update_selection()
	elif event.is_action_pressed("move_down"):
		selected = min(items.size() - 1, selected + 1)
		AudioBus.play_sfx("select")
		_update_selection()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		if selected == 1:
			DisplaySettings.toggle_resolution()
			AudioBus.play_sfx("select")
			_update_selection()
	elif event.is_action_pressed("ui_accept"):
		if confirm_active:
			return
		if selected == 0:
			_start_confirm_flash()
		elif selected == 1:
			DisplaySettings.toggle_resolution()
			AudioBus.play_sfx("select")
			_update_selection()
		else:
			get_tree().quit()


func _update_selection() -> void:
	for index in items.size():
		items[index].modulate = Color(1.0, 1.0, 1.0, 1.0)
	if selected < items.size():
		var item_position := _item_global_position(items[selected])
		selector.position = Vector2(item_position.x - DisplaySettings.scale_value(70.5), item_position.y + DisplaySettings.scale_value(28.5))


func _update_resolution_label() -> void:
	var text_width := _set_atlas_text(resolution_item, DisplaySettings.current_label())
	resolution_item.position = Vector2(RESOLUTION_CENTER_X - text_width * 0.5, RESOLUTION_BASE_Y)


func _on_display_settings_changed() -> void:
	_apply_resolution_layout()
	_update_resolution_label()
	_setup_rocks()
	_update_selection()


func _apply_resolution_layout() -> void:
	var scale_value := DisplaySettings.scale_factor()
	var title_scale := scale_value * TITLE_LAYOUT_SCALE
	var title_bounds := _node2d_local_bounds(title)
	title.scale = Vector2.ONE * title_scale
	title.position.y = TITLE_BASE_POSITION.y * scale_value
	if title_bounds.size.x > 0.0:
		title.position.x = (DisplaySettings.logical_size().x - title_bounds.size.x * title_scale) * 0.5 - title_bounds.position.x * title_scale
	else:
		title.position.x = TITLE_BASE_POSITION.x * scale_value
	menu_items.scale = Vector2.ONE * scale_value
	selector.scale = Vector2.ONE * SELECTOR_BASE_SCALE * scale_value
	ships.position = SHIPS_BASE_POSITION * scale_value
	ships.scale = Vector2.ONE * scale_value


func _node2d_local_bounds(node: Node2D) -> Rect2:
	var has_bounds := false
	var bounds := Rect2()
	for child in node.get_children():
		if not (child is Sprite2D):
			continue
		var sprite := child as Sprite2D
		if sprite.texture == null:
			continue
		var sprite_scale := Vector2(abs(sprite.scale.x), abs(sprite.scale.y))
		var sprite_size := sprite.texture.get_size() * sprite_scale
		var origin := sprite.position
		if sprite.centered:
			origin -= sprite_size * 0.5
		var sprite_bounds := Rect2(origin, sprite_size)
		if has_bounds:
			bounds = bounds.merge(sprite_bounds)
		else:
			bounds = sprite_bounds
			has_bounds = true
	if has_bounds:
		return bounds
	return Rect2()


func _set_atlas_text(parent: Node2D, text_value: String) -> float:
	for child in parent.get_children():
		child.free()
	var cursor := 0.0
	for index in text_value.length():
		var character := text_value.substr(index, 1)
		var region: Rect2 = MENU_GLYPHS.get(character, Rect2())
		if region.size == Vector2.ZERO:
			cursor += 36.0
			continue
		var atlas := AtlasTexture.new()
		atlas.atlas = MENU_FONT_TEXTURE
		atlas.region = region
		var sprite := Sprite2D.new()
		sprite.texture = atlas
		sprite.centered = false
		sprite.position = Vector2(cursor, 0)
		sprite.scale = Vector2.ONE * MENU_ITEM_BASE_SCALE
		parent.add_child(sprite)
		cursor += region.size.x * MENU_ITEM_BASE_SCALE + MENU_GLYPH_SPACING
	return max(0.0, cursor - MENU_GLYPH_SPACING)


func _item_global_position(item: CanvasItem) -> Vector2:
	if item is Node2D:
		return (item as Node2D).global_position
	if item is Control:
		return (item as Control).global_position
	return item.get_global_transform().origin


func _update_title_flash() -> void:
	var flash := (1.0 - cos(anim_time * 2.2)) * 0.5
	title.modulate = TITLE_BASE_COLOR.lerp(TITLE_FLASH_COLOR, flash)


func _update_item_flash(delta: float) -> void:
	if confirm_active:
		confirm_timer -= delta
		var pulse := (1.0 - cos(anim_time * 34.0)) * 0.5
		items[selected].modulate = Color(1.0, 1.0, 1.0, lerp(ITEM_CONFIRM_MIN_ALPHA, 1.0, pulse))
		if confirm_timer <= 0.0:
			SceneFlow.start_new_game()
		return
	for index in items.size():
		if index == selected:
			var pulse := (1.0 - cos(anim_time * 4.0)) * 0.5
			items[index].modulate = Color(1.0, 1.0, 1.0, lerp(ITEM_SELECTED_MIN_ALPHA, 1.0, pulse))
		else:
			items[index].modulate = Color(1.0, 1.0, 1.0, 1.0)


func _start_confirm_flash() -> void:
	confirm_active = true
	confirm_timer = 1.5
	AudioBus.play_sfx("game_start", 0.0)


func _update_rocks(delta: float) -> void:
	for rock in drifting_rocks:
		var velocity: Vector2 = rock.get_meta("velocity")
		rock.position += velocity * delta
		rock.rotation += delta * float(rock.get_meta("rotation_speed"))
		if rock.position.y > get_viewport_rect().size.y + float(rock.get_meta("despawn_margin")):
			_apply_rock_layer(rock, _pick_rock_layer(), true)


func _setup_rocks() -> void:
	for index in drifting_rocks.size():
		var layer_index := int(ROCK_INITIAL_LAYERS[index % ROCK_INITIAL_LAYERS.size()])
		_apply_rock_layer(drifting_rocks[index], layer_index, false)


func _ensure_rock_count() -> void:
	var template_count := drifting_rocks.size()
	if template_count == 0:
		return
	var target_count := template_count * (ROCK_EXTRA_MULTIPLIER + 1)
	var viewport_size := get_viewport_rect().size
	while drifting_rocks.size() < target_count:
		var template: Sprite2D = drifting_rocks[drifting_rocks.size() % template_count]
		var rock: Sprite2D = template.duplicate() as Sprite2D
		rock.name = "Rock%d" % (drifting_rocks.size() + 1)
		var spawn_margin := DisplaySettings.scale_value(180.0)
		rock.position = Vector2(
			rock_rng.randf_range(-spawn_margin, viewport_size.x + spawn_margin),
			rock_rng.randf_range(-viewport_size.y, viewport_size.y)
		)
		rock_parent.add_child(rock)
		drifting_rocks.append(rock)


func _pick_rock_layer() -> int:
	var roll := rock_rng.randf()
	if roll < 0.24:
		return 0
	if roll < 0.60:
		return 1
	return 2


func _apply_rock_layer(rock: Sprite2D, layer_index: int, respawn: bool) -> void:
	var layer: Dictionary = ROCK_LAYER_DATA[layer_index]
	var scale_value := rock_rng.randf_range(float(layer["scale_min"]), float(layer["scale_max"]))
	var velocity := Vector2(
		rock_rng.randf_range(float(layer["drift_min"]), float(layer["drift_max"])),
		rock_rng.randf_range(float(layer["speed_min"]), float(layer["speed_max"]))
	)
	rock.scale = Vector2.ONE * scale_value * DisplaySettings.scale_factor()
	rock.modulate = layer["modulate"]
	rock.z_index = int(layer["z_index"])
	rock.set_meta("depth_layer", layer_index)
	rock.set_meta("velocity", DisplaySettings.to_current(velocity))
	rock.set_meta("rotation_speed", rock_rng.randf_range(float(layer["rotation_min"]), float(layer["rotation_max"])))
	rock.set_meta("despawn_margin", DisplaySettings.scale_value(float(layer["despawn_margin"])))
	if respawn:
		var viewport_width := get_viewport_rect().size.x
		var spawn_margin := DisplaySettings.scale_value(float(layer["spawn_margin"]))
		rock.position = Vector2(
			rock_rng.randf_range(-spawn_margin, viewport_width + spawn_margin),
			rock_rng.randf_range(DisplaySettings.scale_value(float(layer["spawn_y_min"])), DisplaySettings.scale_value(float(layer["spawn_y_max"])))
		)
	else:
		var viewport_size := get_viewport_rect().size
		var spawn_margin := DisplaySettings.scale_value(float(layer["spawn_margin"]))
		var despawn_margin := DisplaySettings.scale_value(float(layer["despawn_margin"]))
		rock.position = Vector2(
			rock_rng.randf_range(-spawn_margin, viewport_size.x + spawn_margin),
			rock_rng.randf_range(-despawn_margin, viewport_size.y + despawn_margin * 0.35)
		)

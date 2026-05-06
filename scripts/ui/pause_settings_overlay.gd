extends CanvasLayer

const MENU_FONT_TEXTURE := preload("res://assets/sprites/duat font corporal.png")
const MENU_GLYPH_SPACING := 8.0
const MENU_ITEM_BASE_SCALE := 1.08
const TITLE_BASE_SCALE := 1.26
const SELECTOR_BASE_SCALE := 1.38
const TITLE_BASE_Y := 474.0
const RESUME_BASE_Y := 588.0
const SETTINGS_BASE_Y := 678.0
const QUIT_GAME_BASE_Y := 768.0
const SELECTOR_OFFSET := Vector2(-70.5, 28.5)
const MENU_GLYPHS := {
	"A": Rect2(30, 212, 45, 52),
	"E": Rect2(227, 212, 45, 52),
	"G": Rect2(323, 212, 45, 52),
	"I": Rect2(421, 212, 45, 52),
	"M": Rect2(134, 278, 45, 52),
	"N": Rect2(187, 278, 45, 52),
	"P": Rect2(284, 278, 45, 52),
	"Q": Rect2(333, 278, 45, 59),
	"R": Rect2(381, 278, 45, 52),
	"S": Rect2(432, 278, 45, 52),
	"T": Rect2(478, 278, 45, 52),
	"U": Rect2(30, 344, 45, 52),
}

@onready var backdrop: ColorRect = $Backdrop
@onready var title_item: Node2D = $Title
@onready var menu_items: Node2D = $MenuItems
@onready var resume_item: Node2D = $MenuItems/Resume
@onready var settings_item: Node2D = $MenuItems/Settings
@onready var quit_item: Node2D = $MenuItems/QuitGame
@onready var selector: Sprite2D = $Selector
@onready var settings_menu: Node = $SettingsMenu
@onready var items: Array[Node2D] = [$MenuItems/Resume, $MenuItems/Settings, $MenuItems/QuitGame]

var selected := 0
var active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	_refresh_labels()
	if settings_menu.has_signal("closed") and not settings_menu.is_connected("closed", _on_settings_closed):
		settings_menu.connect("closed", _on_settings_closed)
	if not DisplaySettings.changed.is_connected(_on_display_settings_changed):
		DisplaySettings.changed.connect(_on_display_settings_changed)


func open() -> void:
	active = true
	selected = 0
	show()
	title_item.visible = true
	menu_items.visible = true
	settings_menu.hide()
	_refresh_labels()
	_update_selection()


func _input(event: InputEvent) -> void:
	if not active:
		return
	if bool(settings_menu.call("is_open")):
		return
	if event.is_action_pressed("pause"):
		_resume_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_up"):
		selected = max(0, selected - 1)
		AudioBus.play_sfx("select")
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		selected = min(items.size() - 1, selected + 1)
		AudioBus.play_sfx("select")
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		match selected:
			0:
				_resume_game()
			1:
				_open_settings()
			_:
				get_tree().paused = false
				SceneFlow.go_main_menu()
		get_viewport().set_input_as_handled()


func _open_settings() -> void:
	title_item.visible = false
	menu_items.visible = false
	selector.visible = false
	settings_menu.call("open", 0)


func _resume_game() -> void:
	active = false
	hide()
	get_tree().paused = false


func _on_settings_closed(_reason: String) -> void:
	title_item.visible = true
	menu_items.visible = true
	_refresh_labels()
	_update_selection()


func _on_display_settings_changed() -> void:
	_refresh_labels()
	_update_selection()


func _refresh_labels() -> void:
	var scale_value := DisplaySettings.scale_factor()
	var center_x := DisplaySettings.logical_center().x
	selector.scale = Vector2.ONE * SELECTOR_BASE_SCALE * scale_value
	var title_width := _set_atlas_text(title_item, "PAUSE", TITLE_BASE_SCALE * scale_value)
	title_item.position = Vector2(center_x - title_width * 0.5, TITLE_BASE_Y * scale_value)

	var resume_width := _set_atlas_text(resume_item, "RESUME", MENU_ITEM_BASE_SCALE * scale_value)
	resume_item.position = Vector2(center_x - resume_width * 0.5, RESUME_BASE_Y * scale_value)

	var settings_width := _set_atlas_text(settings_item, "SETTINGS", MENU_ITEM_BASE_SCALE * scale_value)
	settings_item.position = Vector2(center_x - settings_width * 0.5, SETTINGS_BASE_Y * scale_value)

	var quit_width := _set_atlas_text(quit_item, "QUIT GAME", MENU_ITEM_BASE_SCALE * scale_value)
	quit_item.position = Vector2(center_x - quit_width * 0.5, QUIT_GAME_BASE_Y * scale_value)


func _update_selection() -> void:
	if not active:
		return
	selector.visible = menu_items.visible
	if not menu_items.visible:
		return
	selector.position = items[selected].position + SELECTOR_OFFSET * DisplaySettings.scale_factor()


func _set_atlas_text(parent: Node2D, text_value: String, scale_value := MENU_ITEM_BASE_SCALE) -> float:
	for child in parent.get_children():
		child.queue_free()
	var cursor := 0.0
	var spacing := MENU_GLYPH_SPACING * (scale_value / MENU_ITEM_BASE_SCALE)
	for index in text_value.length():
		var character := text_value.substr(index, 1)
		var region: Rect2 = MENU_GLYPHS.get(character, Rect2())
		if region.size == Vector2.ZERO:
			cursor += 36.0 * (scale_value / MENU_ITEM_BASE_SCALE)
			continue
		var atlas := AtlasTexture.new()
		atlas.atlas = MENU_FONT_TEXTURE
		atlas.region = region
		var sprite := Sprite2D.new()
		sprite.texture = atlas
		sprite.centered = false
		sprite.position = Vector2(cursor, 0)
		sprite.scale = Vector2.ONE * scale_value
		parent.add_child(sprite)
		cursor += region.size.x * scale_value + spacing
	return maxf(0.0, cursor - spacing)

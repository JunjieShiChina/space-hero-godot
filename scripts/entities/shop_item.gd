extends Area2D
class_name ShopItem

const GOODS_FONT := preload("res://assets/font/STHUPO.TTF")

@export_enum("friend", "bullet", "shield") var product_type := "bullet"
@export var bullet_type := ""
@export var price := 0
@export var icon_texture: Texture2D
@export var icon_region := Rect2()
@export var icon_scale := 1.0
@export var item_scale := 1.0

var velocity := Vector2.ZERO
var stage: Node
var retired := false


func _ready() -> void:
	_apply_visual()
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func configure_from_definition(definition: Node, pos: Vector2, fall_speed: float, stage_ref: Node) -> void:
	product_type = String(definition.get("product_type"))
	bullet_type = String(definition.get("bullet_type"))
	price = int(definition.get("price"))
	icon_texture = definition.get("icon_texture") as Texture2D
	icon_region = definition.get("icon_region")
	icon_scale = float(definition.get("icon_scale"))
	item_scale = float(definition.get("item_scale"))
	stage = stage_ref
	global_position = pos
	velocity = Vector2.DOWN * DisplaySettings.scale_value(fall_speed)
	_apply_visual()


func _physics_process(delta: float) -> void:
	if retired:
		return
	global_position += velocity * delta
	if global_position.y > DisplaySettings.scale_value(1240):
		_retire()


func _on_area_entered(area: Area2D) -> void:
	if retired or not (area is PlayerShip):
		return
	if GameData.coin_count < price:
		_fail_purchase()
		return

	var ok := false
	match product_type:
		"bullet":
			GameData.equip_bullet(bullet_type)
			ok = true
		"friend":
			ok = GameData.buy_friend()
		"shield":
			if stage and stage.has_method("spawn_shield"):
				stage.spawn_shield()
				ok = true

	if ok and GameData.spend_coins(price):
		AudioBus.play_sfx("consume")
		_retire()
	else:
		_fail_purchase()


func _apply_visual() -> void:
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root:
		visual_root.scale = Vector2.ONE * DisplaySettings.scale_factor() * item_scale

	var icon := get_node_or_null("VisualRoot/Icon") as Sprite2D
	if icon:
		icon.texture = icon_texture
		icon.visible = icon_texture != null
		icon.region_enabled = icon_region.size.x > 0.0 and icon_region.size.y > 0.0
		if icon.region_enabled:
			icon.region_rect = icon_region
		icon.scale = Vector2.ONE * icon_scale

	var label := get_node_or_null("VisualRoot/PriceLabel") as Label
	if label:
		label.text = str(price)
		label.add_theme_font_override("font", GOODS_FONT)
		label.add_theme_font_size_override("font_size", DisplaySettings.scale_font_size(20))
		label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.34))
		label.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.05))
		label.add_theme_constant_override("outline_size", DisplaySettings.scale_font_size(2))

	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is CircleShape2D:
		(collision.shape as CircleShape2D).radius = DisplaySettings.scale_value(36)


func _fail_purchase() -> void:
	AudioBus.play_sfx("failed")
	if stage and stage.has_method("flash_shop_failure"):
		stage.flash_shop_failure()
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root:
		var tween := create_tween()
		tween.tween_property(visual_root, "modulate", Color(1, 0.25, 0.25), 0.06)
		tween.tween_property(visual_root, "modulate", Color.WHITE, 0.14)


func _retire() -> void:
	if is_queued_for_deletion() or retired:
		return
	retired = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.set_deferred("disabled", true)
	visible = false
	set_process(false)
	set_physics_process(false)
	call_deferred("queue_free")

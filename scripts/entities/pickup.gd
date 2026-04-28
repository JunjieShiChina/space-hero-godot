extends Area2D
class_name PickupItem

const GOODS_FONT := preload("res://assets/font/STHUPO.TTF")
const COIN_ATLAS := preload("res://assets/sprites/gdb-coinsgemsetc-1.png")
const FOLLOW_BULLET_REGION := Rect2(96, 48, 16, 16)
const COIN_FRAME_SPEED := 9.0
const COIN_VISUAL_SCALE := 2.0
const COIN_COLLISION_RADIUS := 17.0
const COIN_FLIP_CYCLES_PER_SECOND := 1.15
const COIN_EDGE_WIDTH_RATIO := 0.12
const COIN_FRAME_REGIONS := {
	"coin1": [
		Rect2(16, 161, 16, 16),
		Rect2(32, 161, 16, 16),
		Rect2(48, 161, 16, 16),
		Rect2(64, 161, 16, 16),
		Rect2(80, 161, 16, 16),
		Rect2(96, 161, 16, 16),
		Rect2(112, 161, 16, 16),
	],
	"coin2": [
		Rect2(16, 129, 16, 16),
		Rect2(32, 129, 16, 16),
		Rect2(48, 129, 16, 16),
		Rect2(64, 129, 16, 16),
		Rect2(80, 129, 16, 16),
		Rect2(96, 129, 16, 16),
		Rect2(112, 129, 16, 16),
	],
	"coin3": [
		Rect2(16, 113, 16, 16),
		Rect2(32, 113, 16, 16),
		Rect2(48, 113, 16, 16),
		Rect2(64, 113, 16, 16),
		Rect2(80, 113, 16, 16),
		Rect2(96, 113, 16, 16),
		Rect2(112, 113, 16, 16),
	],
}

var kind := "coin1"
var amount := 10
var velocity := Vector2.DOWN * 195.0
var price := 0
var product_type := ""
var bullet_type := ""
var stage: Node
var retired := false
var _coin_sprite: AnimatedSprite2D
var _coin_base_scale := Vector2.ONE
var _coin_flip_time := 0.0

func configure_coin(type_name: String, pos: Vector2, value: int, initial_velocity: Vector2 = Vector2.ZERO) -> void:
	kind = type_name
	amount = value
	global_position = pos
	velocity = initial_velocity
	_setup_coin_visual(type_name)

func configure_hp(pos: Vector2) -> void:
	kind = "hp"
	amount = 50
	global_position = pos
	velocity = Vector2.DOWN * DisplaySettings.scale_value(195.0)
	_setup_visual("res://assets/sprites/PowerUp_HP.png", 0.525, 27, 16)

func configure_goods(pos: Vector2, product: String, item_price: int, item_bullet := "") -> void:
	kind = "goods"
	product_type = product
	price = item_price
	bullet_type = item_bullet
	global_position = pos
	velocity = Vector2.ZERO
	_setup_visual("res://assets/sprites/goods.png", 1.05, 36, 16)
	var icon := Sprite2D.new()
	icon.texture = load(_goods_icon_texture(product, item_bullet))
	_apply_goods_icon_region(icon, item_bullet)
	icon.scale = Vector2.ONE * _goods_icon_scale(product, item_bullet) * DisplaySettings.scale_factor()
	add_child(icon)
	var label := Label.new()
	label.text = str(price)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = DisplaySettings.to_current(Vector2(-34, 28))
	label.size = DisplaySettings.to_current(Vector2(68, 26))
	label.add_theme_font_override("font", GOODS_FONT)
	label.add_theme_font_size_override("font_size", DisplaySettings.scale_font_size(20))
	label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.34))
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.05))
	label.add_theme_constant_override("outline_size", DisplaySettings.scale_font_size(2))
	add_child(label)

func _physics_process(delta: float) -> void:
	if kind == "goods":
		return
	global_position += velocity * delta
	if kind == "hp":
		rotation += delta * 1.8
	elif kind.begins_with("coin"):
		_update_coin_flip(delta)
	if global_position.y > DisplaySettings.scale_value(1200):
		call_deferred("_retire")

func _on_area_entered(area: Area2D) -> void:
	if not (area is PlayerShip):
		return
	var player := area as PlayerShip
	if kind.begins_with("coin"):
		GameData.add_coins(amount)
		GameData.record_stat(kind)
		AudioBus.play_sfx("coin")
		call_deferred("_retire")
	elif kind == "hp":
		player.heal(amount)
		GameData.player_health = player.health
		AudioBus.play_sfx("pickup")
		call_deferred("_retire")
	elif kind == "goods":
		var ok := false
		var failure_reason := "coin"
		if GameData.spend_coins(price):
			failure_reason = "item"
			match product_type:
				"bullet":
					ok = GameData.equip_bullet(bullet_type)
					if not ok:
						failure_reason = "weapon"
				"friend":
					ok = GameData.buy_friend()
					if not ok:
						failure_reason = "friend"
				"shield":
					ok = true
					if stage and stage.has_method("spawn_shield"):
						stage.spawn_shield()
				"fire_rate":
					ok = GameData.add_fire_rate_to_current_bullet()
			if not ok:
				GameData.add_coins(price)
		AudioBus.play_sfx("consume" if ok else "failed")
		if ok:
			call_deferred("_retire")
		elif stage and stage.has_method("flash_shop_failure"):
			stage.flash_shop_failure(failure_reason)

func _setup_visual(texture_path: String, scale_value: float, radius: float, layer: int) -> void:
	collision_layer = layer
	collision_mask = 1
	var sprite := Sprite2D.new()
	sprite.texture = load(texture_path)
	sprite.scale = Vector2.ONE * scale_value * DisplaySettings.scale_factor()
	add_child(sprite)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	(shape.shape as CircleShape2D).radius = DisplaySettings.scale_value(radius)
	add_child(shape)
	area_entered.connect(_on_area_entered)

func _setup_coin_visual(type_name: String) -> void:
	collision_layer = 16
	collision_mask = 1
	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.add_animation("spin")
	frames.set_animation_loop("spin", true)
	frames.set_animation_speed("spin", COIN_FRAME_SPEED)
	var regions: Array = COIN_FRAME_REGIONS.get(type_name, COIN_FRAME_REGIONS["coin1"])
	for region: Rect2 in regions:
		_add_coin_frame(frames, region)
	for index in range(regions.size() - 2, 0, -1):
		var reverse_region: Rect2 = regions[index]
		_add_coin_frame(frames, reverse_region)
	sprite.sprite_frames = frames
	sprite.animation = "spin"
	_coin_base_scale = Vector2.ONE * COIN_VISUAL_SCALE * DisplaySettings.scale_factor()
	sprite.scale = _coin_base_scale
	add_child(sprite)
	_coin_sprite = sprite
	sprite.play("spin")

	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = CircleShape2D.new()
	(shape.shape as CircleShape2D).radius = DisplaySettings.scale_value(COIN_COLLISION_RADIUS)
	add_child(shape)
	area_entered.connect(_on_area_entered)

func _add_coin_frame(frames: SpriteFrames, region: Rect2) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = COIN_ATLAS
	atlas.region = region
	frames.add_frame("spin", atlas)

func _update_coin_flip(delta: float) -> void:
	if _coin_sprite == null:
		return
	_coin_flip_time += delta
	var width_factor: float = cos(_coin_flip_time * TAU * COIN_FLIP_CYCLES_PER_SECOND)
	if absf(width_factor) < COIN_EDGE_WIDTH_RATIO:
		width_factor = COIN_EDGE_WIDTH_RATIO * (1.0 if width_factor >= 0.0 else -1.0)
	_coin_sprite.scale.x = _coin_base_scale.x * width_factor
	_coin_sprite.scale.y = _coin_base_scale.y

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

func _goods_icon_texture(product: String, item_bullet: String) -> String:
	if product == "friend":
		return "res://assets/sprites/friendplane.png"
	if product == "shield":
		return "res://assets/sprites/PowerUp_HP.png"
	if product == "fire_rate":
		return "res://assets/sprites/fire_rate_upgrade_icon.png"
	match item_bullet:
		"BulletArrow":
			return "res://assets/sprites/WyvernHornBow.png"
		"Bullet3":
			return "res://assets/sprites/bullet6.png"
		"BulletMissile":
			return "res://assets/sprites/spr_missile.png"
		"FollowBullet":
			return "res://assets/sprites/All_Fire_Bullet_Pixel_16x16_00.png"
	return "res://assets/sprites/bullet5.png"

func _goods_icon_scale(product: String, item_bullet: String) -> float:
	if product == "friend":
		return 0.88
	if product == "shield":
		return 0.38
	if product == "fire_rate":
		return 0.58
	match item_bullet:
		"BulletArrow":
			return 0.18
		"Bullet3":
			return 0.16
		"BulletMissile":
			return 0.62
		"FollowBullet":
			return 2.0
	return 0.58

func _apply_goods_icon_region(icon: Sprite2D, item_bullet: String) -> void:
	icon.region_enabled = item_bullet == "FollowBullet"
	if icon.region_enabled:
		icon.region_rect = FOLLOW_BULLET_REGION

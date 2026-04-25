extends Area2D
class_name PickupItem

var kind := "coin1"
var amount := 10
var velocity := Vector2.DOWN * 195.0
var price := 0
var product_type := ""
var bullet_type := ""
var stage: Node
var retired := false

func configure_coin(type_name: String, pos: Vector2, value: int) -> void:
	kind = type_name
	amount = value
	global_position = pos
	velocity = Vector2.DOWN * DisplaySettings.scale_value(195.0)
	_setup_visual(_coin_texture(type_name), 0.51, 27, 16)

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
	_setup_visual("res://assets/sprites/goods.png", 0.495, 36, 16)
	var label := Label.new()
	label.text = "%s\n%d" % [item_bullet if product == "bullet" else product.to_upper(), price]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = DisplaySettings.to_current(Vector2(-63, 42))
	label.add_theme_font_size_override("font_size", DisplaySettings.scale_font_size(16))
	add_child(label)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	rotation += delta * 1.8
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
		if GameData.spend_coins(price):
			match product_type:
				"bullet":
					GameData.equip_bullet(bullet_type)
					ok = true
				"friend":
					ok = GameData.buy_friend()
				"shield":
					ok = true
					if stage and stage.has_method("spawn_shield"):
						stage.spawn_shield()
			if not ok:
				GameData.add_coins(price)
		AudioBus.play_sfx("consume" if ok else "failed")
		if ok:
			call_deferred("_retire")

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

func _coin_texture(type_name: String) -> String:
	match type_name:
		"coin2":
			return "res://assets/sprites/gold2.png"
		"coin3":
			return "res://assets/sprites/gold3.png"
	return "res://assets/sprites/gold1.png"

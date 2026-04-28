extends Node


func _ready() -> void:
	await _run()
	get_tree().quit()


func _run() -> void:
	await get_tree().process_frame
	GameData.reset_run()
	DisplaySettings.set_resolution(0)
	GameData.add_coins(1000)
	GameData.bullet_slots = ["BulletMissile", "BulletArrow", "FollowBullet"]
	GameData.current_bullet_index = 0
	GameData.weapon_levels = {
		"Bullet1": 1,
		"BulletMissile": 8,
		"BulletArrow": 3,
		"FollowBullet": 2,
	}
	GameData.weapon_fire_rate_steps = {
		"Bullet1": 0,
		"BulletMissile": 5,
		"BulletArrow": 1,
		"FollowBullet": 0,
	}
	GameData.changed.emit()

	var stage_scene := load("res://scenes/stage_1.tscn") as PackedScene
	var stage := stage_scene.instantiate()
	get_tree().root.add_child(stage)
	await get_tree().process_frame
	await get_tree().process_frame

	var player := stage.get("player") as PlayerShip
	player.global_position = DisplaySettings.to_current(Vector2(960, 890))
	player.fire_timer = 0.0
	stage.spawn_shield()

	var shop_item := (load("res://scenes/entities/shop_items/shop_fire_rate.tscn") as PackedScene).instantiate() as ShopItem
	stage.add_child(shop_item)
	shop_item.configure_from_definition(shop_item, DisplaySettings.to_current(Vector2(1550, 820)), 0.0, stage)

	for _i in 3:
		player.shoot_current_weapon()
		await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(0.35).timeout

	if DisplayServer.get_name() != "headless":
		var image := get_tree().root.get_texture().get_image()
		if image:
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/output"))
			image.save_png("res://tests/output/upgrade_ui_verify.png")

	stage.queue_free()
	await get_tree().process_frame

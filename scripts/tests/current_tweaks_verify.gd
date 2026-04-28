extends Node


func _ready() -> void:
	await _run()
	get_tree().quit()


func _run() -> void:
	await get_tree().process_frame
	var game_data := get_node("/root/GameData")
	var display_settings := get_node("/root/DisplaySettings")
	game_data.set("friend_plane_count", 2)
	game_data.set("bullet_slots", ["FollowBullet", "BulletArrow", "Bullet1"])
	game_data.set("current_bullet_index", 0)
	display_settings.call("set_resolution", 0)

	var stage_scene := load("res://scenes/stage_1.tscn") as PackedScene
	var stage := stage_scene.instantiate()
	get_tree().root.add_child(stage)
	await get_tree().process_frame
	await get_tree().process_frame

	var player := stage.get("player") as Node2D
	var player_pos: Vector2 = display_settings.call("to_current", Vector2(960, 890))
	player.global_position = player_pos
	stage.call("spawn_shield")
	await get_tree().process_frame
	if player.has_method("sync_friends"):
		player.call("sync_friends")
	await get_tree().process_frame

	var friends: Array = player.get("friends")
	if not friends.is_empty():
		var friend := friends[0] as Node2D
		stage.call("_spawn_enemy_at", "ship", friend.global_position + display_settings.call("to_current", Vector2(0, -430)))
		player.call("_fire_friend_laser", friend)

	stage.call("_spawn_enemy_at", "ship", display_settings.call("to_current", Vector2(960, -120)))
	stage.call("_spawn_enemy_at", "ep2", display_settings.call("to_current", Vector2(960, 330)))
	stage.call("_spawn_enemy_at", "phase_interceptor", display_settings.call("to_current", Vector2(560, 180)))
	await get_tree().process_frame
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyShip and String(enemy.get("ai")) == "phase_interceptor":
			enemy.call("_shoot_phase_spread")

	var shield_shop := (load("res://scenes/entities/shop_items/shop_shield.tscn") as PackedScene).instantiate()
	stage.add_child(shield_shop)
	shield_shop.global_position = display_settings.call("to_current", Vector2(1730, 820))

	var follow_bullet := (load("res://scenes/entities/bullets/follow_bullet.tscn") as PackedScene).instantiate()
	stage.add_child(follow_bullet)
	follow_bullet.call("setup", "FollowBullet", "player", player_pos + display_settings.call("to_current", Vector2(0, -120)), Vector2.UP)
	var follow_target := follow_bullet.call("_find_target") as Node2D
	print("follow_target=", follow_target.name if follow_target else "none")

	stage.call("_spawn_boss", 1)
	await get_tree().process_frame
	var boss := stage.get("boss") as Node2D
	if boss:
		boss.global_position = display_settings.call("to_current", Vector2(960, 220))
		for i in 5:
			boss.set("boss1_special_index", i)
			boss.call("_shoot_boss1_special_step")

	await get_tree().create_timer(0.45).timeout
	if DisplayServer.get_name() != "headless":
		var image := get_tree().root.get_texture().get_image()
		if image:
			image.save_png("res://tests/output/current_tweaks_verify.png")

	for child in stage.get_children():
		if child is ShieldBubble:
			var shield := child as ShieldBubble
			var shield_enemy := (load("res://scenes/entities/enemy_single_shot.tscn") as PackedScene).instantiate()
			stage.add_child(shield_enemy)
			shield_enemy.call("configure", "ship", shield.global_position + display_settings.call("to_current", Vector2(0, -16)), player)
			var shield_before: float = shield.get("health")
			shield.call("_on_area_entered", shield_enemy)
			print("shield_health=", shield_before, "->", float(shield.get("health")), " enemy_dead=", shield_enemy.get("dead"))
			break

	stage.queue_free()
	await get_tree().process_frame

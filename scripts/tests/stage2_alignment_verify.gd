extends Node


func _ready() -> void:
	await _run()
	get_tree().quit()


func _run() -> void:
	await get_tree().process_frame

	var display_settings := get_node("/root/DisplaySettings")
	display_settings.call("set_resolution", 0)

	var stage_scene := load("res://scenes/stage_2.tscn") as PackedScene
	var stage := stage_scene.instantiate()
	get_tree().root.add_child(stage)
	await get_tree().process_frame
	await get_tree().process_frame

	for node_path in [
		"BackgroundLayer",
		"BackgroundLayer/ScrollingBackground",
		"BackgroundLayer/Starfield",
		"BackgroundLayer/BackgroundAsteroids",
		"Camera2D",
		"PlayerStart",
		"Player",
		"BattleHud",
		"ShopDropManager",
	]:
		assert(stage.has_node(node_path))

	var configs: Dictionary = stage.get("configs")
	var stage_config: Dictionary = configs[2]
	assert(is_equal_approx(float(stage_config["meteor_delay"]), 0.0))
	assert(is_equal_approx(float(stage_config["meteor_prob"]), 0.15))

	var player := stage.get("player") as Node2D
	if player:
		player.global_position = display_settings.call("to_current", Vector2(960, 890))

	stage.call("_debug_clear_combat", true)
	stage.call("_spawn_enemy_at", "meteor", display_settings.call("to_current", Vector2(630, 170)))
	stage.call("_spawn_enemy_at", "small_boss", display_settings.call("to_current", Vector2(1280, 210)))
	stage.call("_spawn_boss", 2)
	await get_tree().process_frame

	var found_meteor := false
	var meteor_probe: EnemyShip = null
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyShip and String(enemy.get("ai")) == "meteor":
			found_meteor = true
			meteor_probe = enemy
			meteor_probe.set("velocity", Vector2.ZERO)
			_assert_meteor_collision_aligned(enemy)
			_assert_meteor_hit_point(enemy, display_settings)
			_assert_meteor_tracking_point(enemy, display_settings)
			_assert_meteor_explosion_position(enemy, display_settings)
			_assert_follow_bullet_tracks_meteor(stage, enemy, display_settings)
			_assert_follow_bullet_does_not_retarget(stage, enemy, display_settings)
			_assert_follow_bullet_expanded_lock_range(stage, display_settings)
	assert(found_meteor)
	if meteor_probe != null:
		_spawn_meteor_hit_probe(stage, meteor_probe, display_settings)
		if _is_visual_run():
			_spawn_follow_meteor_visual_probe(stage, meteor_probe, display_settings)
			_spawn_meteor_explosion_visual_probe(meteor_probe)

	var boss := stage.get("boss") as BossShip
	assert(boss != null)
	assert(is_equal_approx(float(boss.get("max_health")), 2000.0))
	if boss:
		boss.global_position = display_settings.call("to_current", Vector2(960, 330))
		var boss_sprite := boss.get_node_or_null("Sprite2D") as Sprite2D
		assert(boss_sprite != null)
		assert(boss_sprite.texture.resource_path == "res://assets/sprites/Spaceship_Boss 3.png")

	var found_small_boss := false
	var small_boss_laser_probe: Node = null
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyShip and String(enemy.get("ai")) == "small_boss":
			found_small_boss = true
			var small_sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
			assert(small_sprite != null)
			assert(small_sprite.texture.resource_path == "res://assets/sprites/Spaceship_Boss 3.png")
			_assert_small_boss_movement(enemy, display_settings)
			_assert_small_boss_laser_warning(stage, enemy, display_settings)
			if _is_visual_run():
				small_boss_laser_probe = _spawn_small_boss_laser_visual_probe(enemy, display_settings)
	assert(found_small_boss)

	print("stage2_alignment meteor_delay=", stage_config["meteor_delay"], " meteor_prob=", stage_config["meteor_prob"])
	print("stage2_alignment boss_hp=", boss.get("max_health"), " boss_texture=Spaceship_Boss 3.png")

	var visual_wait := 1.25 if _is_visual_run() else 0.35
	if _is_visual_run():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		_save_runtime_screenshot("small_boss_laser_warning_ready.png")
		if small_boss_laser_probe != null:
			small_boss_laser_probe.call("_process", 1.01)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		_save_runtime_screenshot("small_boss_laser_warning_active.png")
	await get_tree().create_timer(visual_wait).timeout
	if _is_visual_run():
		_save_runtime_screenshot("stage2_alignment_verify.png")

	stage.call("_debug_clear_combat", true)
	stage.queue_free()
	await get_tree().process_frame


func _assert_meteor_collision_aligned(meteor: EnemyShip) -> void:
	var meteor_sprite := meteor.get_node_or_null("Sprite2D") as Sprite2D
	var polygon := meteor.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	assert(meteor_sprite != null)
	assert(meteor_sprite.texture != null)
	assert(polygon != null)
	assert(polygon.polygon.size() >= 3)

	var sprite_half_size := meteor_sprite.texture.get_size() * meteor_sprite.scale * 0.5
	var sprite_rect := Rect2(meteor_sprite.position - sprite_half_size, sprite_half_size * 2.0)
	var collision_rect := _polygon_rect(polygon.polygon)
	assert(collision_rect.position.y >= sprite_rect.position.y - 2.0)
	assert(collision_rect.end.y <= sprite_rect.end.y + 2.0)


func _assert_meteor_hit_point(meteor: EnemyShip, display_settings: Node) -> void:
	var meteor_sprite := meteor.get_node_or_null("Sprite2D") as Sprite2D
	var polygon := meteor.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	assert(meteor_sprite != null)
	assert(meteor_sprite.texture != null)
	assert(polygon != null)

	var incoming_position: Vector2 = meteor.global_position + display_settings.call("to_current", Vector2(0, 130))
	var hit_position := meteor.closest_collision_point(incoming_position)
	var local_hit := meteor.to_local(hit_position)
	var sprite_half_size := meteor_sprite.texture.get_size() * meteor_sprite.scale * 0.5
	var sprite_rect := Rect2(meteor_sprite.position - sprite_half_size, sprite_half_size * 2.0)
	assert(sprite_rect.has_point(local_hit))


func _assert_meteor_tracking_point(meteor: EnemyShip, display_settings: Node) -> void:
	var tracking_position := meteor.tracking_position()
	var local_tracking := meteor.to_local(tracking_position)
	var polygon := meteor.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	assert(polygon != null)

	var collision_rect := _polygon_rect(polygon.polygon)
	assert(collision_rect.has_point(local_tracking))
	assert(tracking_position.y < meteor.global_position.y - display_settings.call("scale_value", 16.0))


func _assert_meteor_explosion_position(meteor: EnemyShip, display_settings: Node) -> void:
	var explosion_parent := meteor.call("_spawn_parent") as Node
	assert(explosion_parent != null)
	meteor.call("_spawn_burst")

	var explosion := _last_child_named(explosion_parent, "ShipExplosion") as Node2D
	assert(explosion != null)
	var expected_position := meteor.tracking_position()
	assert(explosion.global_position.distance_squared_to(expected_position) < 1.0)
	var minimum_offset: float = display_settings.call("scale_value", 16.0)
	assert(explosion.global_position.y < meteor.global_position.y - minimum_offset)
	explosion.queue_free()


func _assert_follow_bullet_tracks_meteor(
	stage: Node,
	meteor: EnemyShip,
	display_settings: Node
) -> void:
	var bullet := SpaceBullet.create("FollowBullet")
	stage.add_child(bullet)
	var bullet_offset: Vector2 = display_settings.call("to_current", Vector2(0, 300))
	var bullet_origin := meteor.global_position + bullet_offset
	bullet.setup("FollowBullet", "player", bullet_origin, Vector2.UP)
	bullet.set("homing_delay_timer", 0.0)
	bullet.call("_physics_process", 0.0)

	var expected_direction := (meteor.tracking_position() - bullet.global_position).normalized()
	var root_direction := (meteor.global_position - bullet.global_position).normalized()
	var actual_direction: Vector2 = (bullet.get("velocity") as Vector2).normalized()
	assert(actual_direction.dot(expected_direction) > 0.99)
	assert(actual_direction.dot(expected_direction) > actual_direction.dot(root_direction))
	bullet.queue_free()


func _assert_follow_bullet_does_not_retarget(
	stage: Node,
	meteor: EnemyShip,
	display_settings: Node
) -> void:
	var bullet := SpaceBullet.create("FollowBullet")
	stage.add_child(bullet)
	var bullet_offset: Vector2 = display_settings.call("to_current", Vector2(-90, 300))
	var bullet_origin := meteor.global_position + bullet_offset
	bullet.setup("FollowBullet", "player", bullet_origin, Vector2.UP)
	assert(bullet.call("_locked_homing_target") == meteor)

	var fallback_offset: Vector2 = display_settings.call("to_current", Vector2(180, 0))
	var fallback_position := meteor.tracking_position() + fallback_offset
	stage.call("_spawn_enemy_at", "ship", fallback_position)
	bullet.set("homing_delay_timer", 0.0)
	var locked_velocity := Vector2(0.28, -1.0).normalized() * float(bullet.get("base_speed"))
	bullet.set("velocity", locked_velocity)

	var was_dead := meteor.dead
	meteor.set("dead", true)
	bullet.call("_physics_process", 0.0)
	meteor.set("dead", was_dead)

	var actual_velocity: Vector2 = bullet.get("velocity")
	assert(actual_velocity.distance_squared_to(locked_velocity) < 0.001)
	bullet.queue_free()


func _assert_follow_bullet_expanded_lock_range(stage: Node, display_settings: Node) -> void:
	var target_scene := load("res://scenes/entities/enemy_single_shot.tscn") as PackedScene
	var target := target_scene.instantiate() as EnemyShip
	stage.add_child(target)
	target.configure("ship", display_settings.call("to_current", Vector2(1600, 360)), stage.get("player"))
	target.set("velocity", Vector2.ZERO)
	target.set("can_shoot", false)

	var bullet := SpaceBullet.create("FollowBullet")
	stage.add_child(bullet)
	var bullet_offset: Vector2 = display_settings.call("to_current", Vector2(0, 620))
	var bullet_origin := target.tracking_position() + bullet_offset
	bullet.setup("FollowBullet", "player", bullet_origin, Vector2.UP)

	var old_range: float = display_settings.call("scale_value", 576.0)
	var target_distance := bullet.global_position.distance_to(target.tracking_position())
	assert(target_distance > old_range)
	assert(target_distance <= float(bullet.get("homing_range")))
	assert(bullet.call("_locked_homing_target") == target)

	bullet.queue_free()
	target.queue_free()


func _assert_small_boss_movement(small_boss: EnemyShip, display_settings: Node) -> void:
	var original_position := small_boss.global_position
	var original_can_shoot: bool = small_boss.get("can_shoot")
	small_boss.global_position = display_settings.call("to_current", Vector2(960, -90))
	small_boss.set("velocity", Vector2.ZERO)
	small_boss.set("can_shoot", false)
	small_boss.set("small_boss_find_next_target", true)
	small_boss.set("small_boss_in_move", false)
	small_boss.set("small_laser_paused", false)
	small_boss.set("small_laser_count", 0)
	small_boss.set("small_laser_timer", 1.0)

	small_boss.call("_process", 0.0)
	var target_position: Vector2 = small_boss.get("small_boss_target")
	var viewport_size: Vector2 = display_settings.call("logical_size")
	assert(target_position.x >= 0.0 and target_position.x <= viewport_size.x)
	assert(target_position.y >= 0.0 and target_position.y <= viewport_size.y)

	var before_move := small_boss.global_position
	var move_delta := 0.25
	small_boss.call("_process", move_delta)
	var move_speed: float = display_settings.call("scale_value", 108.0 * 5.0)
	var expected_position := before_move.move_toward(target_position, move_speed * move_delta)
	assert(small_boss.global_position.distance_squared_to(expected_position) < 1.0)

	small_boss.set("small_boss_find_next_target", false)
	small_boss.set("small_boss_in_move", false)
	small_boss.set("small_laser_paused", true)
	small_boss.set("small_laser_pause_timer", 0.01)
	small_boss.call("_process_small_boss_fire", 0.02)
	assert(small_boss.get("small_boss_find_next_target"))

	small_boss.set("can_shoot", original_can_shoot)
	small_boss.global_position = original_position


func _assert_small_boss_laser_warning(
	stage: Node,
	small_boss: EnemyShip,
	display_settings: Node
) -> void:
	var original_position := small_boss.global_position
	var original_player_position := (stage.get("player") as Node2D).global_position
	small_boss.global_position = display_settings.call("to_current", Vector2(960, 260))
	(stage.get("player") as Node2D).global_position = display_settings.call("to_current", Vector2(960, 890))

	var parent := small_boss.call("_spawn_parent") as Node
	var laser_count_before := _count_bullet_lasers(parent)
	small_boss.call("_shoot_small_boss_laser")

	var warning := _last_child_named(parent, "BossLaserWarning")
	assert(warning != null)
	var aim_direction := ((stage.get("player") as Node2D).global_position - small_boss.global_position).normalized()
	var required_length := _screen_exit_distance(small_boss.global_position, aim_direction, display_settings)
	assert(warning.global_position.distance_to(small_boss.global_position) >= display_settings.call("scale_value", 20.0))
	var position_before_move := small_boss.global_position
	small_boss.call("_process_small_boss_movement", 0.25)
	assert(small_boss.global_position.distance_to(position_before_move) < 0.01)
	var warning_line := warning.get_node_or_null("WarningCoreLine") as Line2D
	var warning_muzzle := warning.get_node_or_null("MuzzleParticles") as GPUParticles2D
	assert(warning_line != null)
	assert(_line_end_distance(warning_line) >= required_length)
	assert(warning_line.width <= display_settings.call("scale_value", 5.0))
	assert(warning_line.points[0].x >= display_settings.call("scale_value", 1.0))
	assert(warning_muzzle != null)
	assert(warning_muzzle.process_material is ParticleProcessMaterial)
	assert(warning_muzzle.texture != null)
	assert(_count_bullet_lasers(parent) == laser_count_before)
	assert(not bool(warning.call("has_active_laser")))

	warning.call("_process", 0.99)
	assert(_count_bullet_lasers(parent) == laser_count_before)
	assert(not bool(warning.call("has_active_laser")))

	warning.call("_process", 0.02)
	assert(bool(warning.call("has_active_laser")))
	assert(_count_bullet_lasers(parent) == laser_count_before + 1)
	var laser := warning.call("active_laser") as SpaceBullet
	assert(laser != null)
	laser.call("_physics_process", 0.22)
	var laser_line := laser.get_node_or_null("CoreLine") as Line2D
	var laser_particles := laser.get_node_or_null("BeamParticles") as GPUParticles2D
	var laser_muzzle := laser.get_node_or_null("MuzzleParticles") as GPUParticles2D
	var laser_impact := laser.get_node_or_null("ImpactParticles") as GPUParticles2D
	var laser_collision := laser.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert(laser_line != null)
	assert(laser_line.material == null)
	assert(_line_end_distance(laser_line) < required_length)
	assert(laser_line.points[0].x >= display_settings.call("scale_value", 1.0))
	assert(laser_line.default_color.r > 0.9)
	assert(laser_line.default_color.g > 0.7)
	assert(laser_line.default_color.b > 0.6)
	assert(laser_particles != null)
	assert(laser_particles.process_material is ParticleProcessMaterial)
	assert(laser_particles.texture != null)
	assert(laser_muzzle != null)
	assert(laser_muzzle.process_material is ParticleProcessMaterial)
	assert(laser_impact != null)
	assert(laser_impact.process_material is ParticleProcessMaterial)
	assert(laser_collision != null)
	assert(laser_collision.shape is RectangleShape2D)
	var player_hit_point := (stage.get("player") as CombatBody).closest_collision_point(laser.global_position)
	var expected_end_distance := aim_direction.dot(player_hit_point - laser.global_position)
	assert(absf(laser_line.points[1].x - expected_end_distance) <= display_settings.call("scale_value", 24.0))
	assert(
		laser_collision.position.x + (laser_collision.shape as RectangleShape2D).size.x * 0.5
		<= expected_end_distance + display_settings.call("scale_value", 12.0)
	)
	assert(is_equal_approx(float(laser.get("damage")), 1.0))
	assert(float(laser.get("life_time")) <= 2.01)

	laser.queue_free()
	warning.queue_free()
	small_boss.global_position = original_position
	(stage.get("player") as Node2D).global_position = original_player_position


func _spawn_meteor_hit_probe(stage: Node, meteor: EnemyShip, display_settings: Node) -> void:
	var bullet := SpaceBullet.create("BulletArrow")
	stage.add_child(bullet)
	var incoming_position: Vector2 = meteor.global_position + display_settings.call("to_current", Vector2(0, 130))
	var hit_position := meteor.closest_collision_point(incoming_position)
	var origin: Vector2 = hit_position + display_settings.call("to_current", Vector2(0, 42))
	bullet.setup("BulletArrow", "player", origin, Vector2.UP)


func _spawn_follow_meteor_visual_probe(stage: Node, meteor: EnemyShip, display_settings: Node) -> void:
	var bullet := SpaceBullet.create("FollowBullet")
	stage.add_child(bullet)
	var origin: Vector2 = meteor.tracking_position() + display_settings.call("to_current", Vector2(-260, 260))
	bullet.setup("FollowBullet", "player", origin, Vector2.UP)
	bullet.set("homing_delay_timer", 0.0)


func _spawn_meteor_explosion_visual_probe(meteor: EnemyShip) -> void:
	meteor.call("_spawn_burst")


func _spawn_small_boss_laser_visual_probe(
	small_boss: EnemyShip,
	display_settings: Node
) -> Node:
	small_boss.global_position = display_settings.call("to_current", Vector2(1300, 230))
	small_boss.set("velocity", Vector2.ZERO)
	small_boss.set("can_shoot", false)
	var parent := small_boss.call("_spawn_parent") as Node
	for child in parent.get_children():
		if String(child.name).begins_with("BossLaserWarning"):
			child.free()
		elif child is SpaceBullet and String(child.get("bullet_type")) == "BulletLaser":
			child.free()
	small_boss.call("_shoot_small_boss_laser")
	return _last_child_named(parent, "BossLaserWarning")


func _save_runtime_screenshot(file_name: String) -> void:
	var output_dir := ProjectSettings.globalize_path("res://tests/output/stage2_alignment")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := get_tree().root.get_texture().get_image()
	if image:
		var error := image.save_png(output_dir.path_join(file_name))
		assert(error == OK)


func _is_visual_run() -> bool:
	return DisplayServer.get_name() != "headless"


func _polygon_rect(points: PackedVector2Array) -> Rect2:
	var min_point := points[0]
	var max_point := points[0]
	for point in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)


func _last_child_named(parent: Node, child_name: String) -> Node:
	for i in range(parent.get_child_count() - 1, -1, -1):
		var child := parent.get_child(i)
		if String(child.name).begins_with(child_name):
			return child
	return null


func _count_bullet_lasers(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is SpaceBullet and String(child.get("bullet_type")) == "BulletLaser":
			count += 1
	return count




func _line_length(line: Line2D) -> float:
	if line.points.size() < 2:
		return 0.0
	return line.points[0].distance_to(line.points[1])


func _line_end_distance(line: Line2D) -> float:
	if line.points.size() < 2:
		return 0.0
	return maxf(line.points[0].x, line.points[1].x)


func _screen_exit_distance(origin: Vector2, direction: Vector2, display_settings: Node) -> float:
	var viewport_size: Vector2 = display_settings.call("logical_size")
	var safe_bottom := viewport_size.y - float(display_settings.call("scale_value", 150.0))
	var candidates: Array[float] = []
	if absf(direction.x) > 0.0001:
		candidates.append((0.0 - origin.x) / direction.x)
		candidates.append((viewport_size.x - origin.x) / direction.x)
	if absf(direction.y) > 0.0001:
		candidates.append((0.0 - origin.y) / direction.y)
		candidates.append((safe_bottom - origin.y) / direction.y)
	var best := INF
	for candidate in candidates:
		if candidate > 0.0:
			best = minf(best, candidate)
	return viewport_size.length() if is_inf(best) else best

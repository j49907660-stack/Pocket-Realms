extends Control
var world: Node3D

func _map(p: Vector2) -> Vector2:
	return Vector2(100 + p.x * 0.96, 100 + p.y * 0.96)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(200, 200)), Color("173e4c", 0.92), true)
	for ix in range(-20, 21):
		for iz in range(-20, 21):
			var x := float(ix) * 4.0
			var z := float(iz) * 4.0
			if world._inside_island(x, z):
				draw_rect(Rect2(_map(Vector2(x, z)) - Vector2(2.1, 2.1), Vector2(4.3, 4.3)), Color("7dbd79"), true)
	for i in range(world.road_points.size() - 1):
		draw_line(_map(world.road_points[i]), _map(world.road_points[i + 1]), Color("f0d89e"), 3.5)
	draw_line(_map(world.TOWN), _map(world.PORT), Color("f0d89e"), 2.5)
	draw_circle(_map(world.TOWN), 6.5, Color("f6e1a2"))
	draw_circle(_map(world.PORT), 4.5, Color("79d3ee"))
	draw_circle(_map(world.DUNGEON), 5.5, Color("ad6ad0"))
	for mob in world.mobs:
		if is_instance_valid(mob):
			var point := _map(Vector2(mob.position.x, mob.position.z))
			draw_circle(point, 1.6, Color("d96d5c"))
	if is_instance_valid(world.player):
		var here := _map(Vector2(world.player.position.x, world.player.position.z))
		draw_circle(here, 5.0, Color("233b65"))
		draw_circle(here, 3.2, Color("ffffff"))
	draw_rect(Rect2(Vector2.ZERO, Vector2(200, 200)), Color("e2e8d6"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(10, 17), "DAWNSHORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("ffffff"))

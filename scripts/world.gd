extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const CreatureScript = preload("res://scripts/creature.gd")
const MAP_RADIUS := 88.0
const TOWN := Vector2(-9, 49)
const PORT := Vector2(-34, 67)
const DUNGEON := Vector2(27, -66)

var camera: Camera3D
var player: CharacterBody3D
var hp_label: Label
var level_label: Label
var zone_label: Label
var attack_button: Button
var minimap: Control
var joystick := Vector2.ZERO
var touch_origin := Vector2.ZERO
var joystick_touch := -1
var monsters_killed := 0
var attack_cooldown := 0.0
var experience := 0
var level := 1
var mobs: Array[CharacterBody3D] = []
var respawns: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var road_points := [Vector2(-9, 49), Vector2(-3, 26), Vector2(-14, 6), Vector2(7, -14), Vector2(17, -36), Vector2(27, -66)]
var areas := [
	{"name":"Meadow", "center":Vector2(-13, 36), "level":1, "types":["Fox", "Slime", "Young Wolf"], "count":12},
	{"name":"Greenwood", "center":Vector2(-45, 15), "level":4, "types":["Wolf", "Boar", "Spider"], "count":14},
	{"name":"Northwood", "center":Vector2(38, 34), "level":7, "types":["Dire Wolf", "Werewolf", "Wolf"], "count":14},
	{"name":"Stone Hills", "center":Vector2(-43, -22), "level":10, "types":["Golem", "Orc", "Spider"], "count":14},
	{"name":"Old Ruins", "center":Vector2(41, -17), "level":13, "types":["Skeleton", "Wraith", "Cultist"], "count":14},
	{"name":"Cursed Vale", "center":Vector2(-15, -52), "level":17, "types":["Werewolf", "Golem", "Wraith"], "count":15},
	{"name":"Forgotten Crypt", "center":DUNGEON, "level":19, "types":["Guardian", "Skeleton", "Cultist"], "count":10}
]

func _ready() -> void:
	rng.seed = 20261013
	_build_world()
	_build_ui()

func _process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if is_instance_valid(player):
		hp_label.text = "HP %d/%d  •  Lv.%d" % [player.hp, player.max_hp, level]
		level_label.text = "XP %d/%d   •   Defeated %d" % [experience, _xp_needed(), monsters_killed]
		zone_label.text = _current_zone()
	if attack_button: attack_button.disabled = attack_cooldown > 0.0
	for i in range(respawns.size() - 1, -1, -1):
		respawns[i]["timer"] -= delta
		if respawns[i]["timer"] <= 0:
			_spawn_monster(respawns[i]["kind"], respawns[i]["lvl"], respawns[i]["pos"], respawns[i]["boss"])
			respawns.remove_at(i)
	_update_camera()
	if minimap: minimap.queue_redraw()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(player): player.joystick = joystick

func _update_camera() -> void:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
	var focus := player.global_position + Vector3(0, 1.0, 0)
	camera.global_position = focus + Vector3(0, 24, 26)
	camera.look_at(focus, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE: _attack()
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.45:
			joystick_touch = event.index
			touch_origin = event.position
		elif not event.pressed and event.index == joystick_touch:
			joystick_touch = -1
			joystick = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == joystick_touch:
		joystick = (event.position - touch_origin).limit_length(75.0) / 75.0

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = _mat(color)
	parent.add_child(node)
	return node

func _ball(parent: Node3D, radius: float, pos: Vector3, color: Color, stretch := Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	node.mesh = mesh
	node.position = pos
	node.scale = stretch
	node.material_override = _mat(color)
	parent.add_child(node)
	return node

func _path(points: Array, width: float, color: Color) -> void:
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var length := a.distance_to(b)
		var center := (a + b) / 2.0
		var segment := _box(self, Vector3(width, 0.07, length + width * 0.3), Vector3(center.x, 0.055, center.y), color)
		segment.rotation.y = -atan2(b.x - a.x, b.y - a.y)

func _tree(x: float, z: float, size: float) -> void:
	# Layered canopies make trees readable from the elevated camera.
	var trunk := Color("75553d")
	var foliage := Color("3e8963") if rng.randf() > 0.5 else Color("5b9b65")
	_box(self, Vector3(0.54 * size, 2.6 * size, 0.54 * size), Vector3(x, 1.3 * size, z), trunk)
	_ball(self, 1.20 * size, Vector3(x, 2.8 * size, z), foliage, Vector3(1.0, 0.85, 1.0))
	_ball(self, 1.05 * size, Vector3(x - 0.48 * size, 3.4 * size, z + 0.3 * size), foliage.lightened(0.13))
	_ball(self, 0.87 * size, Vector3(x + 0.62 * size, 3.6 * size, z - 0.3 * size), foliage.lightened(0.07))

func _roof(x: float, z: float, tint: Color) -> void:
	# Two pitched roof slopes instead of a flat colored box.
	for side in [-1.0, 1.0]:
		var slope := _box(self, Vector3(3.55, 0.30, 5.3), Vector3(x + side * 1.32, 3.82, z), tint)
		slope.rotation.z = side * 0.48
	_box(self, Vector3(0.28, 0.28, 5.5), Vector3(x, 4.43, z), tint.darkened(0.17))

func _house(x: float, z: float, color: Color) -> void:
	_box(self, Vector3(5.0, 3.0, 4.6), Vector3(x, 1.5, z), Color("e3c99d"))
	_box(self, Vector3(5.1, 0.35, 4.8), Vector3(x, 0.2, z), Color("9d9783"))
	_roof(x, z, color)
	_box(self, Vector3(1.1, 2.0, 0.13), Vector3(x, 1.0, z + 2.36), Color("79513c"))
	_box(self, Vector3(1.4, 0.15, 0.26), Vector3(x, 2.08, z + 2.42), Color("a7794c"))
	_box(self, Vector3(1.02, 1.02, 0.15), Vector3(x - 1.48, 2.0, z + 2.36), Color("9ed3dc"))
	_box(self, Vector3(0.13, 1.13, 0.21), Vector3(x - 1.48, 2.0, z + 2.47), Color("eee2c2"))
	_box(self, Vector3(1.13, 0.13, 0.21), Vector3(x - 1.48, 2.0, z + 2.47), Color("eee2c2"))
	# Chimney.
	_box(self, Vector3(0.72, 1.35, 0.72), Vector3(x + 1.4, 4.24, z - 1.2), Color("a87967"))

func _rock(x: float, z: float, size: float) -> void:
	var rock := _ball(self, size, Vector3(x, 0.23 * size, z), Color("91958b"), Vector3(1.25, 0.48, 0.85))
	rock.rotation.y = rng.randf_range(-1.5, 1.5)

func _bush(x: float, z: float, size: float) -> void:
	_ball(self, size, Vector3(x, size * 0.55, z), Color("3e8c59"), Vector3(1.25, 0.65, 1.0))
	_ball(self, size * 0.7, Vector3(x + size * 0.6, size * 0.7, z), Color("69a75b"))

func _inside_island(x: float, z: float) -> bool:
	var u := x / 85.0
	var v := z / 85.0
	var irregular := 1.0 + 0.10 * sin(atan2(v, u) * 5.0) + 0.08 * cos(atan2(v, u) * 8.0)
	return u * u + v * v < irregular * irregular

func _build_world() -> void:
	# A procedurally assembled island made from square ground cells, with an irregular coastline.
	_box(self, Vector3(200, 0.25, 200), Vector3(0, -0.6, 0), Color("69b6cf"))
	# Draw all grass cells in a single MultiMesh draw call instead of ~1500 separate materials/meshes.
	var cells: Array[Vector3] = []
	for ix in range(-22, 23):
		for iz in range(-22, 23):
			var x := float(ix) * 4.0
			var z := float(iz) * 4.0
			if _inside_island(x, z):
				cells.append(Vector3(x, -0.18, z))
	var grass_mesh := BoxMesh.new()
	grass_mesh.size = Vector3(4.06, 0.3, 4.06)
	var grass_instances := MultiMesh.new()
	grass_instances.transform_format = MultiMesh.TRANSFORM_3D
	grass_instances.mesh = grass_mesh
	grass_instances.instance_count = cells.size()
	for i in range(cells.size()):
		grass_instances.set_instance_transform(i, Transform3D(Basis.IDENTITY, cells[i]))
	var grass_node := MultiMeshInstance3D.new()
	grass_node.multimesh = grass_instances
	grass_node.material_override = _mat(Color("81b878"))
	add_child(grass_node)
	# Routes connect the town to the far end of the island.
	_path(road_points, 4.6, Color("d7bf91"))
	_path([TOWN, Vector2(-23, 59), PORT], 4.0, Color("d7bf91"))
	_path([Vector2(-14, 6), Vector2(-42, -22)], 3.1, Color("c9b184"))
	_path([Vector2(-3, 26), Vector2(36, 34)], 3.1, Color("c9b184"))
	_path([Vector2(7, -14), Vector2(41, -17)], 3.1, Color("c9b184"))
	# One town and one port.
	_box(self, Vector3(25, 0.09, 21), Vector3(TOWN.x, 0.07, TOWN.y), Color("d8c6a2"))
	for house in [Vector2(-20, 43), Vector2(-7, 42), Vector2(2, 44), Vector2(-20, 55), Vector2(-8, 58), Vector2(3, 55)]:
		_house(house.x, house.y, Color("c96858") if rng.randf() > 0.5 else Color("8b83bd"))
	_box(self, Vector3(12, 0.4, 7), Vector3(PORT.x, 0.0, PORT.y), Color("8c6645"))
	for j in range(5):
		_box(self, Vector3(0.5, 1.8, 0.5), Vector3(PORT.x - 5 + j * 2.4, -0.5, PORT.y + 2), Color("76513d"))
	_box(self, Vector3(9, 1.1, 3), Vector3(PORT.x - 1, 0.35, PORT.y + 7), Color("ad7150"))
	# Dungeon entrance and a small ruin complex.
	for offset in [Vector2(-5, -5), Vector2(5, -5), Vector2(-5, 5), Vector2(5, 5)]:
		_box(self, Vector3(2.4, 4.5, 2.4), Vector3(DUNGEON.x + offset.x, 2.25, DUNGEON.y + offset.y), Color("858b92"))
	_box(self, Vector3(8, 0.4, 8), Vector3(DUNGEON.x, 0.15, DUNGEON.y), Color("656d77"))
	for i in range(95):
		var x := rng.randf_range(-80, 80)
		var z := rng.randf_range(-80, 80)
		if not _inside_island(x, z): continue
		if Vector2(x, z).distance_to(TOWN) < 21.0 or Vector2(x, z).distance_to(DUNGEON) < 13.0: continue
		var near_road := false
		for point in road_points:
			if Vector2(x, z).distance_to(point) < 7.0: near_road = true
		if near_road: continue
		_tree(x, z, rng.randf_range(0.7, 1.4))
	# Small environmental details, away from the main town and the road.
	for i in range(100):
		var x := rng.randf_range(-77.0, 77.0)
		var z := rng.randf_range(-77.0, 77.0)
		if not _inside_island(x, z): continue
		if Vector2(x, z).distance_to(TOWN) < 18.0: continue
		if rng.randf() < 0.42:
			_rock(x, z, rng.randf_range(0.4, 1.2))
		else:
			_bush(x, z, rng.randf_range(0.4, 0.95))
	# Town square and a recognizable central landmark.
	_box(self, Vector3(4.0, 0.25, 4.0), Vector3(TOWN.x, 0.16, TOWN.y), Color("a7a69a"))
	_box(self, Vector3(0.85, 2.6, 0.85), Vector3(TOWN.x, 1.5, TOWN.y), Color("b6b4a2"))
	_ball(self, 0.72, Vector3(TOWN.x, 3.05, TOWN.y), Color("d8b36d"))
	# A few stone fragments around the dungeon entrance.
	for j in range(12):
		var theta := float(j) * TAU / 12.0
		var px := DUNGEON.x + cos(theta) * 10.5
		var pz := DUNGEON.y + sin(theta) * 10.5
		if _inside_island(px, pz): _rock(px, pz, rng.randf_range(0.7, 1.5))
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(TOWN.x, 0.1, TOWN.y - 14)
	add_child(player)
	player.died.connect(_on_player_died)
	for area in areas:
		for j in range(area["count"]):
			var pos := _mob_position(area["center"])
			var kinds: Array = area["types"]
			_spawn_monster(kinds[j % kinds.size()], area["level"] + j % 3, pos)
	_spawn_monster("Ash Guardian", 20, Vector3(DUNGEON.x, 0.1, DUNGEON.y), true)
	# Camera is a child of the WORLD, not the animated player.
	# Point it at the player's global position every frame.
	camera = Camera3D.new()
	add_child(camera)
	camera.fov = 53.0
	camera.near = 0.1
	camera.far = 500.0
	_update_camera()
	camera.make_current()
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 1.2
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("a8d6e5")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 0.8
	env.environment = e
	add_child(env)

func _mob_position(center: Vector2) -> Vector3:
	for attempt in range(35):
		var p := center + Vector2(rng.randf_range(-18, 18), rng.randf_range(-18, 18))
		if _inside_island(p.x, p.y) and p.distance_to(TOWN) > 18 and p.distance_to(DUNGEON) > 6:
			return Vector3(p.x, 0.1, p.y)
	return Vector3(center.x, 0.1, center.y)

func _spawn_monster(kind: String, lvl: int, pos: Vector3, boss := false) -> void:
	var mob := CharacterBody3D.new()
	mob.set_script(CreatureScript)
	mob.configure(kind, lvl, pos, boss)
	mob.position = pos
	mob.target = player
	mob.killed.connect(_on_monster_killed)
	add_child(mob)
	mobs.append(mob)

func _on_monster_killed(mob: CharacterBody3D, xp: int) -> void:
	monsters_killed += 1
	experience += xp
	while experience >= _xp_needed() and level < 20:
		experience -= _xp_needed()
		level += 1
		player.max_hp += 12
		player.hp = player.max_hp
	respawns.append({"kind":mob.mob_name, "lvl":mob.level, "pos":mob.spawn_point, "boss":mob.is_boss, "timer":55.0 if mob.is_boss else 16.0})
	mobs.erase(mob)

func _xp_needed() -> int:
	return 60 + level * level * 22

func _on_player_died() -> void:
	player.position = Vector3(TOWN.x, 0.1, TOWN.y - 14)
	player.hp = player.max_hp
	experience = maxi(0, experience - int(_xp_needed() * 0.05))

func _attack() -> void:
	if attack_cooldown > 0.0 or not is_instance_valid(player): return
	attack_cooldown = 0.45
	player.swing()
	for mob in mobs.duplicate():
		if not is_instance_valid(mob): continue
		var offset: Vector3 = mob.global_position - player.global_position
		offset.y = 0
		if offset.length() < 3.1 and offset.length() > 0.01 and player.facing.dot(offset.normalized()) > -0.05:
			mob.take_damage(25 + level * 5)

func _current_zone() -> String:
	var p := Vector2(player.position.x, player.position.z)
	if p.distance_to(TOWN) < 17: return "DAWNSHORE • SAFE TOWN"
	if p.distance_to(PORT) < 12: return "DAWNSHORE • PORT"
	var nearest := "Wilderness"
	var distance := INF
	for area in areas:
		var d: float = p.distance_to(area["center"])
		if d < distance:
			distance = d
			nearest = area["name"]
	return "DAWNSHORE • %s" % nearest

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)
	hp_label = Label.new()
	hp_label.position = Vector2(22, 16)
	hp_label.add_theme_font_size_override("font_size", 23)
	overlay.add_child(hp_label)
	level_label = Label.new()
	level_label.position = Vector2(22, 46)
	overlay.add_child(level_label)
	zone_label = Label.new()
	zone_label.position = Vector2(22, 73)
	zone_label.add_theme_font_size_override("font_size", 18)
	overlay.add_child(zone_label)
	var hint := Label.new()
	hint.text = "WASD / arrows: move   •   SPACE: attack   •   Touch: left side move"
	hint.position = Vector2(22, 104)
	overlay.add_child(hint)
	attack_button = Button.new()
	attack_button.text = "ATTACK"
	attack_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	attack_button.offset_left = -175
	attack_button.offset_top = -108
	attack_button.offset_right = -22
	attack_button.offset_bottom = -24
	attack_button.mouse_filter = Control.MOUSE_FILTER_STOP
	attack_button.pressed.connect(_attack)
	overlay.add_child(attack_button)
	minimap = Control.new()
	minimap.set_script(preload("res://scripts/minimap.gd"))
	minimap.world = self
	minimap.custom_minimum_size = Vector2(196, 196)
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -220
	minimap.offset_top = 20
	minimap.offset_right = -20
	minimap.offset_bottom = 220
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(minimap)



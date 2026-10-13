extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const WolfScript = preload("res://scripts/wolf.gd")
var player: CharacterBody3D
var hp_label: Label
var score_label: Label
var attack_button: Button
var joystick := Vector2.ZERO
var touch_origin := Vector2.ZERO
var joystick_touch := -1
var wolves_killed := 0
var attack_cooldown := 0.0

func _ready() -> void:
	_build_world()
	_build_ui()

func _process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if is_instance_valid(player):
		hp_label.text = "HP: %d / 100" % player.hp
		score_label.text = "Wolves defeated: %d" % wolves_killed
	if attack_button:
		attack_button.disabled = attack_cooldown > 0.0

func _physics_process(_delta: float) -> void:
	if is_instance_valid(player):
		player.joystick = joystick

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_attack()
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.45:
			joystick_touch = event.index
			touch_origin = event.position
		elif not event.pressed and event.index == joystick_touch:
			joystick_touch = -1
			joystick = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == joystick_touch:
		joystick = (event.position - touch_origin).limit_length(75.0) / 75.0

func _make_box(parent: Node3D, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.position = position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh

func _make_ball(parent: Node3D, radius: float, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	mesh.position = position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh

func _build_world() -> void:
	_make_box(self, Vector3(48, 0.4, 48), Vector3(0, -0.25, 0), Color("7fbd69"))
	_make_box(self, Vector3(5, 0.04, 34), Vector3(0, 0.01, 0), Color("e5c992"))
	_make_box(self, Vector3(25, 0.04, 4), Vector3(-4, 0.015, -8), Color("e5c992"))
	for i in range(18):
		var x := -20.0 + float((i * 13) % 39)
		var z := -20.0 + float((i * 19) % 39)
		if absf(x) < 4.0 or absf(z + 8.0) < 4.0:
			continue
		_make_box(self, Vector3(0.6, 2.1, 0.6), Vector3(x, 1.0, z), Color("875b38"))
		_make_ball(self, 1.5, Vector3(x, 2.7, z), Color("32985c"))
	for i in range(4):
		var x := -14.0 + i * 8.0
		_make_box(self, Vector3(3.7, 2.3, 3.7), Vector3(x, 1.15, -14), Color("f5dbad"))
		_make_box(self, Vector3(4.3, 0.7, 4.3), Vector3(x, 2.65, -14), Color("c66d53"))
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(0, 0.1, 2)
	add_child(player)
	player.died.connect(_on_player_died)
	for i in range(3):
		_spawn_wolf(Vector3(5.0 + i * 3.0, 0.1, 6.0 + (i % 2) * 4.0))
	var camera := Camera3D.new()
	camera.position = Vector3(0, 19, 22)
	camera.rotation_degrees = Vector3(-42, 0, 0)
	camera.current = true
	camera.fov = 48.0
	player.add_child(camera)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 1.3
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("a4d8f1")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("ffffff")
	e.ambient_light_energy = 0.75
	env.environment = e
	add_child(env)

func _spawn_wolf(at: Vector3) -> void:
	var wolf := CharacterBody3D.new()
	wolf.set_script(WolfScript)
	wolf.position = at
	wolf.target = player
	wolf.killed.connect(_on_wolf_killed)
	add_child(wolf)

func _on_wolf_killed() -> void:
	wolves_killed += 1

func _on_player_died() -> void:
	player.position = Vector3(0, 0.1, 2)
	player.hp = 100

func _attack() -> void:
	if attack_cooldown > 0.0 or not is_instance_valid(player):
		return
	attack_cooldown = 0.5
	for node in get_children():
		if node is CharacterBody3D and node != player and node.has_method("take_damage"):
			var offset: Vector3 = node.global_position - player.global_position
			offset.y = 0
			if offset.length() < 3.0 and player.facing.dot(offset.normalized()) > 0.1:
				node.take_damage(35)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)
	hp_label = Label.new()
	hp_label.position = Vector2(24, 20)
	hp_label.add_theme_font_size_override("font_size", 25)
	overlay.add_child(hp_label)
	score_label = Label.new()
	score_label.position = Vector2(24, 54)
	score_label.add_theme_font_size_override("font_size", 21)
	overlay.add_child(score_label)
	var hint := Label.new()
	hint.text = "WASD / arrows: move   •   SPACE: attack   •   Touch: left side move, right button attack"
	hint.position = Vector2(24, 88)
	overlay.add_child(hint)
	attack_button = Button.new()
	attack_button.text = "⚔ ATTACK"
	attack_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	attack_button.offset_left = -190
	attack_button.offset_top = -115
	attack_button.offset_right = -30
	attack_button.offset_bottom = -30
	attack_button.mouse_filter = Control.MOUSE_FILTER_STOP
	attack_button.pressed.connect(_attack)
	overlay.add_child(attack_button)

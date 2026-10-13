extends CharacterBody3D
signal died
var hp := 100
var max_hp := 100
var speed := 8.0
var joystick := Vector2.ZERO
var facing := Vector3(0, 0, -1)
var body_root: Node3D
var arm: Node3D
var walking := 0.0
var attack_anim := 0.0
var world_radius := 88.0

func _part(parent: Node3D, shape: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	if shape == "box":
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh_instance.mesh = mesh
	else:
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh_instance.mesh = mesh
		mesh_instance.scale = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat
	mesh_instance.position = pos
	parent.add_child(mesh_instance)
	return mesh_instance

func _ready() -> void:
	body_root = Node3D.new()
	add_child(body_root)
	_part(body_root, "box", Vector3(0.85, 1.05, 0.5), Vector3(0, 1.12, 0), Color("3679b9"))
	_part(body_root, "sphere", Vector3(0.82, 0.85, 0.82), Vector3(0, 2.0, 0), Color("ffd2a6"))
	_part(body_root, "sphere", Vector3(0.86, 0.35, 0.85), Vector3(0, 2.37, 0.06), Color("5a3a2b"))
	for side in [-1.0, 1.0]:
		_part(body_root, "box", Vector3(0.29, 0.75, 0.32), Vector3(side * 0.24, 0.38, 0), Color("303c65"))
		_part(body_root, "box", Vector3(0.3, 0.75, 0.32), Vector3(side * 0.61, 1.12, 0), Color("ffd2a6"))
	arm = Node3D.new()
	arm.position = Vector3(0.72, 1.35, -0.15)
	body_root.add_child(arm)
	_part(arm, "box", Vector3(0.12, 1.2, 0.19), Vector3(0, 0.3, -0.35), Color("c6dce9"))
	_part(arm, "box", Vector3(0.65, 0.13, 0.16), Vector3(0, -0.18, -0.3), Color("9b713f"))

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if joystick.length() > 0.1: direction = joystick
	var move := Vector3(direction.x, 0, direction.y)
	velocity = move * speed
	if move.length() > 0.1:
		facing = move.normalized()
		body_root.rotation.y = atan2(-facing.x, -facing.z)
		walking += delta * 12.0
		body_root.position.y = absf(sin(walking)) * 0.11
	else:
		body_root.position.y = lerpf(body_root.position.y, 0.0, delta * 10.0)
	move_and_slide()
	position.x = clampf(position.x, -world_radius, world_radius)
	position.z = clampf(position.z, -world_radius, world_radius)
	attack_anim = maxf(0.0, attack_anim - delta)
	arm.rotation.x = -sin((1.0 - attack_anim / 0.32) * PI) * 1.4 if attack_anim > 0.0 else 0.0

func swing() -> void:
	attack_anim = 0.32

func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	if hp == 0: died.emit()

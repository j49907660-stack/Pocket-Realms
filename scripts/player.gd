extends CharacterBody3D
signal died
var hp := 100
var speed := 7.0
var joystick := Vector2.ZERO
var facing := Vector3(0, 0, -1)

func _ready() -> void:
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.48
	mesh.height = 1.8
	body.mesh = mesh
	body.position.y = 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("4976d2")
	body.material_override = mat
	add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.48
	sphere.height = 0.96
	head.mesh = sphere
	head.position.y = 1.85
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("f9c49a")
	head.material_override = skin
	add_child(head)

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if joystick.length() > 0.1:
		direction = joystick
	var move := Vector3(direction.x, 0, direction.y)
	velocity = move * speed
	if move.length() > 0.1:
		facing = move.normalized()
	move_and_slide()
	position.x = clampf(position.x, -22, 22)
	position.z = clampf(position.z, -22, 22)

func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	if hp == 0:
		died.emit()

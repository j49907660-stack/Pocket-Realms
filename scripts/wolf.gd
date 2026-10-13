extends CharacterBody3D
signal killed
var target: CharacterBody3D
var hp := 70
var attack_timer := 0.0

func _ready() -> void:
	var body := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.7
	mesh.height = 1.1
	body.mesh = mesh
	body.position.y = 0.65
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("9b6b53")
	body.material_override = mat
	add_child(body)

func _physics_process(delta: float) -> void:
	attack_timer = maxf(0.0, attack_timer - delta)
	if not is_instance_valid(target):
		return
	var to_player: Vector3 = target.global_position - global_position
	to_player.y = 0
	if to_player.length() < 8.0 and to_player.length() > 1.2:
		velocity = to_player.normalized() * 2.8
	else:
		velocity = Vector3.ZERO
	move_and_slide()
	if to_player.length() < 1.6 and attack_timer == 0.0:
		attack_timer = 1.2
		target.take_damage(8)

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		killed.emit()
		queue_free()

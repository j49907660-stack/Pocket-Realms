extends CharacterBody3D
signal killed(mob: CharacterBody3D, xp_reward: int)

var target: CharacterBody3D
var mob_name := "Wolf"
var level := 1
var max_hp := 50
var hp := 50
var damage := 5
var speed := 2.5
var aggro_radius := 6.0
var spawn_point := Vector3.ZERO
var attack_timer := 0.0
var dead := false
var visual: Node3D
var health_bar: ProgressBar
var anim_time := 0.0
var is_boss := false

func configure(kind: String, lvl: int, home: Vector3, boss := false) -> void:
	mob_name = kind
	level = lvl
	spawn_point = home
	is_boss = boss
	max_hp = 32 + level * 15 + (400 if boss else 0)
	hp = max_hp
	damage = 3 + int(level * 0.9) + (9 if boss else 0)
	speed = 1.7 + minf(level * 0.065, 1.1)
	aggro_radius = 5.5 + (2.0 if boss else 0.0)

func _part(parent: Node3D, shape: String, size: Vector3, pos: Vector3, tint: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	if shape == "box":
		var mesh := BoxMesh.new()
		mesh.size = size
		item.mesh = mesh
	else:
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		item.mesh = mesh
		item.scale = size
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	item.material_override = material
	item.position = pos
	parent.add_child(item)
	return item

func _ready() -> void:
	visual = Node3D.new()
	add_child(visual)
	var base := Color("ab7655")
	if "Fox" in mob_name: base = Color("dc8844")
	elif "Spider" in mob_name: base = Color("6e506d")
	elif "Golem" in mob_name: base = Color("818f95")
	elif "Orc" in mob_name: base = Color("70984f")
	elif "Skeleton" in mob_name: base = Color("ded6b4")
	elif "Wraith" in mob_name: base = Color("8d8bd1")
	elif "Slime" in mob_name: base = Color("63c6a2")
	elif "Boar" in mob_name: base = Color("77523d")
	elif "Cultist" in mob_name: base = Color("783c77")
	elif "Guardian" in mob_name: base = Color("4d6a79")
	var scale_factor := 1.65 if is_boss else 1.0
	visual.scale = Vector3.ONE * scale_factor
	if "Spider" in mob_name:
		_part(visual, "sphere", Vector3(1.25, 0.65, 1.4), Vector3(0, 0.6, 0), base)
		for side in [-1.0, 1.0]:
			for j in range(3):
				_part(visual, "box", Vector3(0.9, 0.11, 0.12), Vector3(side * 0.78, 0.4, float(j - 1) * 0.4), base)
	elif "Golem" in mob_name or "Guardian" in mob_name:
		_part(visual, "box", Vector3(1.0, 1.3, 0.8), Vector3(0, 1.0, 0), base)
		_part(visual, "box", Vector3(0.7, 0.7, 0.7), Vector3(0, 2.0, 0), base.lightened(0.12))
		for side in [-1.0, 1.0]:
			_part(visual, "box", Vector3(0.38, 1.1, 0.38), Vector3(side * 0.77, 1.0, 0), base.darkened(0.1))
	elif "Wolf" in mob_name or "Fox" in mob_name or "Boar" in mob_name:
		_part(visual, "sphere", Vector3(1.6, 0.85, 0.9), Vector3(0, 0.72, 0), base)
		_part(visual, "sphere", Vector3(0.85, 0.8, 0.85), Vector3(0, 1.0, -0.72), base.lightened(0.08))
		for side in [-1.0, 1.0]:
			_part(visual, "box", Vector3(0.24, 0.65, 0.24), Vector3(side * 0.43, 0.3, -0.42), base.darkened(0.14))
			_part(visual, "box", Vector3(0.24, 0.65, 0.24), Vector3(side * 0.43, 0.3, 0.48), base.darkened(0.14))
			_part(visual, "sphere", Vector3(0.28, 0.48, 0.28), Vector3(side * 0.28, 1.55, -0.85), base)
		_part(visual, "sphere", Vector3(0.28, 0.22, 0.28), Vector3(0, 0.9, -1.12), Color("2f3036"))
	else:
		_part(visual, "sphere", Vector3(1.1, 1.25, 0.85), Vector3(0, 0.75, 0), base)
		_part(visual, "sphere", Vector3(0.65, 0.65, 0.65), Vector3(0, 1.65, 0), base.lightened(0.15))
	var label := Label3D.new()
	label.text = "%s  Lv.%d" % [mob_name, level]
	label.position = Vector3(0, 2.5 * scale_factor, 0)
	label.font_size = 34
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("fff5e6")
	add_child(label)
	var background := Sprite3D.new()
	# Health bars are rendered as a simple 3D indicator above each monster.
	var bar_back := _part(self, "box", Vector3(1.25, 0.12, 0.04), Vector3(0, 2.23 * scale_factor, 0), Color("392c38"))
	var bar_fill := _part(self, "box", Vector3(1.2, 0.09, 0.06), Vector3(0, 2.23 * scale_factor, -0.03), Color("ef685e"))
	bar_fill.name = "HealthFill"
	bar_back.name = "HealthBack"

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target): return
	attack_timer = maxf(0.0, attack_timer - delta)
	anim_time += delta
	visual.position.y = sin(anim_time * 7.0) * 0.045 if velocity.length() > 0.2 else 0.0
	var to_target := target.global_position - global_position
	to_target.y = 0
	var distance := to_target.length()
	var home_distance := global_position.distance_to(spawn_point)
	if distance < aggro_radius and distance > 1.4 and home_distance < 13.0:
		velocity = to_target.normalized() * speed
		visual.rotation.y = atan2(-velocity.x, -velocity.z)
	else:
		velocity = Vector3.ZERO
	move_and_slide()
	if distance < 1.8 and attack_timer <= 0.0:
		attack_timer = 1.3
		target.take_damage(damage)

func take_damage(amount: int) -> void:
	if dead: return
	hp = maxi(0, hp - amount)
	var fill := get_node_or_null("HealthFill") as MeshInstance3D
	if fill:
		fill.scale.x = maxf(0.001, float(hp) / float(max_hp))
	if hp <= 0:
		dead = true
		killed.emit(self, level * 9 + (120 if is_boss else 0))
		queue_free()

extends Node3D

# Pocket Realms temporary visual diagnostic.
# Replace scripts/world.gd temporarily with this file's contents.
func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.13, 0.19, 0.88)
	panel.position = Vector2(18, 18)
	panel.size = Vector2(690, 142)
	layer.add_child(panel)
	var status := Label.new()
	status.position = Vector2(32, 30)
	status.add_theme_font_size_override("font_size", 20)
	status.text = "POCKET REALMS - DIAGNOSTIC\nSCRIPT STARTED: YES\nExpected: GREEN FLOOR + RED CUBE + BLUE SKY"
	layer.add_child(status)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.72, 0.94)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 1.0
	environment.environment = env
	add_child(environment)

	var floor_mesh := MeshInstance3D.new()
	var floor_shape := BoxMesh.new()
	floor_shape.size = Vector3(40, 0.3, 40)
	floor_mesh.mesh = floor_shape
	floor_mesh.position = Vector3(0, -0.15, 0)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.22, 0.76, 0.32)
	floor_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_mesh.material_override = floor_material
	add_child(floor_mesh)

	var cube := MeshInstance3D.new()
	var cube_shape := BoxMesh.new()
	cube_shape.size = Vector3(4, 4, 4)
	cube.mesh = cube_shape
	cube.position = Vector3(0, 2, 0)
	var cube_material := StandardMaterial3D.new()
	cube_material.albedo_color = Color(1, 0.12, 0.12)
	cube_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cube.material_override = cube_material
	add_child(cube)

	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 15, 20)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true
	camera.far = 200.0
	status.text += "\nCAMERA ACTIVE: %s" % str(get_viewport().get_camera_3d() == camera)


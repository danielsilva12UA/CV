extends Node

var player_camera: Camera3D
var portal_screen: MeshInstance3D
var portal_entry: Node3D
var portal_exit: Node3D
var portal_subviewport: SubViewport
var portal_camera: Camera3D
var dummy_camera_entry: Node3D
var dummy_body_entry: Node3D
var dummy_camera_exit: Node3D
var dummy_body_exit: Node3D
var screen_material: ShaderMaterial
var screen_shader: Shader
var viewport_texture: ViewportTexture


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	portal_exit = $Exit
	var portal_placeholder = $Screen
	portal_screen = MeshInstance3D.new()
	add_child(portal_screen)
	portal_screen.global_position = portal_placeholder.global_position
	portal_screen.global_rotation = portal_placeholder.global_rotation
	portal_subviewport = SubViewport.new()
	add_child(portal_subviewport)
	portal_camera = Camera3D.new()
	portal_subviewport.add_child(portal_camera)
	dummy_camera_entry = Node3D.new()
	portal_screen.add_child(dummy_camera_entry)
	dummy_camera_exit = Node3D.new()
	portal_exit.add_child(dummy_camera_exit)
	dummy_body_entry = Node3D.new()
	portal_screen.add_child(dummy_body_entry)
	dummy_body_exit = Node3D.new()
	portal_exit.add_child(dummy_body_exit)
	
	# Setting up stuff
	player_camera = get_viewport().get_camera_3d()
	portal_camera.set_fov(player_camera.get_fov())
	portal_camera.use_oblique_frustum = true
	portal_camera.set_oblique_normal(-portal_exit.global_transform.basis.z)
	portal_camera.set_oblique_position(portal_exit.global_position)
	# Setup viewport and PlaneMesh
	portal_subviewport.mesh_lod_threshold = 0
	screen_shader = load("res://shaders/portal.gdshader")
	screen_material = ShaderMaterial.new()
	screen_material.shader = screen_shader
	screen_material.set_shader_parameter("tex", portal_subviewport.get_texture())
	portal_screen.set_mesh(PlaneMesh.new())
	var mesh = portal_screen.get_mesh() as PlaneMesh
	mesh.orientation = PlaneMesh.FACE_Z
	mesh.flip_faces = true
	mesh.size = Vector2(2*portal_placeholder.scale.x, 2*portal_placeholder.scale.y)
	portal_screen.get_mesh().surface_set_material(0, screen_material)
	# Set viewport size to screen size
	portal_subviewport.size = get_viewport().size
	get_tree().get_root().size_changed.connect(resize)
	# Set up hitbox
	var hitboxArea = Area3D.new()
	portal_screen.add_child(hitboxArea)
	hitboxArea.global_transform = portal_screen.global_transform
	var hitboxCollision = CollisionShape3D.new()
	hitboxArea.add_child(hitboxCollision)
	hitboxCollision.shape = BoxShape3D.new()
	hitboxCollision.shape.size = Vector3(mesh.size.x, mesh.size.y, 2)
	hitboxArea.body_entered.connect(_on_entry_body_entered)
	# Delete placeholder
	portal_placeholder.queue_free()
	var world_3d = player_camera.get_world_3d()
	if world_3d:
		portal_camera.environment = world_3d.environment.duplicate()
		portal_camera.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	dummy_camera_entry.set_global_transform(player_camera.get_global_transform())
	dummy_camera_exit.set_transform(dummy_camera_entry.get_transform())
	portal_camera.set_global_transform(dummy_camera_exit.get_global_transform())


func _on_entry_body_entered(body: Node3D) -> void:
	if body is not CharacterBody3D:
		return
	
	dummy_body_entry.set_global_transform(body.get_global_transform())
	dummy_body_exit.set_transform(dummy_body_entry.get_transform())
	body.set_global_position(dummy_body_exit.get_global_position())
	body.set_global_rotation(dummy_body_exit.get_global_rotation())
	
	#var body_dir = body.velocity.normalized()
	#var right = portal_entry.global_transform.basis.x.normalized()
	#var angle_sign = 1.0
	#if 0 < body_dir.dot(right):
		#angle_sign = -1.0
	#var backward = -portal_entry.global_transform.basis.z.normalized()
	#var velocity_angle = angle_sign * acos(body_dir.dot(backward))
	#var exit_forward = portal_exit.global_transform.basis.z.normalized()
	#var exit_up = portal_exit.global_transform.basis.y.normalized()
	#body.set_velocity(exit_forward.rotated(exit_up, velocity_angle) * body.get_velocity().length())

func resize():
	portal_subviewport.size = get_viewport().size

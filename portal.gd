extends Node

var player_camera: Camera3D
var portal_entry: MeshInstance3D
var portal_exit: MeshInstance3D
var portal_subviewport: SubViewport
var portal_camera: Camera3D
var dummy_camera_entry: Node3D
var dummy_body_entry: Node3D
var dummy_camera_exit: Node3D
var dummy_body_exit: Node3D
var portal_travellers: Dictionary


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get existing nodes
	portal_entry = $Entry
	portal_exit = $Exit
	
	# Setup viewport
	portal_subviewport = SubViewport.new()
	add_child(portal_subviewport)
	portal_subviewport.mesh_lod_threshold = 0
	portal_subviewport.size = get_viewport().size
	get_tree().get_root().size_changed.connect(resize)
	
	# Setup camera
	player_camera = get_viewport().get_camera_3d()
	portal_camera = Camera3D.new()
	portal_subviewport.add_child(portal_camera)
	portal_camera.set_fov(player_camera.get_fov())
	portal_camera.use_oblique_frustum = true
	portal_camera.set_oblique_normal(-portal_exit.global_transform.basis.z)
	portal_camera.set_oblique_position(portal_exit.global_position)
	var world_3d: World3D = player_camera.get_world_3d()
	if world_3d:
		portal_camera.environment = world_3d.environment.duplicate()
		portal_camera.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	
	# Setup dummies
	dummy_camera_entry = Node3D.new()
	portal_entry.add_child(dummy_camera_entry)
	dummy_camera_exit = Node3D.new()
	portal_exit.add_child(dummy_camera_exit)
	dummy_body_entry = Node3D.new()
	portal_entry.add_child(dummy_body_entry)
	dummy_body_exit = Node3D.new()
	portal_exit.add_child(dummy_body_exit)
	
	# Setup shader and material
	var shader: Shader = load("res://shaders/portal.gdshader")
	var portal_material: ShaderMaterial = ShaderMaterial.new()
	portal_material.shader = shader
	portal_material.set_shader_parameter("tex", portal_subviewport.get_texture())
	portal_entry.get_mesh().surface_set_material(0, portal_material)
	portal_exit.set_mesh(null)
	
	# Set up hitbox
	var hitboxArea: Area3D = Area3D.new()
	portal_entry.add_child(hitboxArea)
	hitboxArea.global_transform = portal_entry.global_transform
	var hitboxCollision: CollisionShape3D = CollisionShape3D.new()
	hitboxCollision.shape = BoxShape3D.new()
	hitboxCollision.shape.size = Vector3(portal_entry.get_mesh().size.x, portal_entry.get_mesh().size.y, 0.1)
	hitboxArea.add_child(hitboxCollision)
	hitboxArea.body_entered.connect(_on_entry_body_entered)
	hitboxArea.body_exited.connect(_on_entry_body_exited)
	portal_travellers = {}


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_camera()
	for body in portal_travellers.keys():
		print(side_of_portal(body))
		if portal_travellers[body] > side_of_portal(body):
			teleport(body)
			portal_travellers.erase(body)


func move_camera() -> void:
	dummy_camera_entry.set_global_transform(player_camera.get_global_transform())
	dummy_camera_exit.set_transform(dummy_camera_entry.get_transform())
	portal_camera.set_global_transform(dummy_camera_exit.get_global_transform())


func teleport(body: Node3D) -> void:
	dummy_body_entry.set_global_transform(body.get_global_transform())
	dummy_body_exit.set_transform(dummy_body_entry.get_transform())
	body.set_global_position(dummy_body_exit.get_global_position())
	body.set_global_rotation(dummy_body_exit.get_global_rotation())


func side_of_portal(body: Node3D) -> float:
	var distance = body.global_position - portal_entry.global_position
	return -portal_entry.basis.z.dot(distance)


func resize() -> void:
	portal_subviewport.size = get_viewport().size


func _on_entry_body_entered(body: Node3D) -> void:
	if body is not CharacterBody3D:
		return
	portal_travellers[body] = side_of_portal(body)


func _on_entry_body_exited(body: Node3D) -> void:
	if body is not CharacterBody3D:
		return
	portal_travellers.erase(body)

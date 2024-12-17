extends MeshInstance3D

@export var other_portal: MeshInstance3D

const thickness = 5

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
var hitboxArea: Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get existing nodes
	portal_entry = self as MeshInstance3D
	portal_exit = other_portal
	
	# Setup viewport
	portal_subviewport = SubViewport.new()
	add_child(portal_subviewport)
	portal_subviewport.mesh_lod_threshold = 0
	portal_subviewport.size = get_viewport().size
	portal_subviewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	get_tree().get_root().size_changed.connect(resize)
	
	# Setup camera
	player_camera = get_viewport().get_camera_3d()
	portal_camera = Camera3D.new()
	portal_subviewport.add_child(portal_camera)
	portal_camera.set_fov(player_camera.get_fov())
	portal_camera.set_near(0.01)
	portal_camera.set_cull_mask_value(10, false)
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
	portal_entry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Setup extra meshes
	var size_x = portal_entry.get_mesh().size.x
	var size_y = portal_entry.get_mesh().size.y
	var extra_meshes: Array[MeshInstance3D]
	for i in range(10):
		extra_meshes.append(MeshInstance3D.new())
		extra_meshes[i].set_mesh(portal_entry.get_mesh().duplicate())
		extra_meshes[i].cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		extra_meshes[i].set_layer_mask_value(1, false)
		extra_meshes[i].set_layer_mask_value(10, true)
		add_child(extra_meshes[i])
		extra_meshes[i].global_position += portal_entry.global_basis.z.normalized()*thickness/2
		if i>=5:
			extra_meshes[i].get_mesh().flip_faces = false
			extra_meshes[i].get_mesh().surface_set_material(0, StandardMaterial3D.new())
			extra_meshes[i].get_mesh().surface_get_material(0).albedo_color = Color("black")
			extra_meshes[i].set_layer_mask_value(10, false)
			extra_meshes[i].set_layer_mask_value(1, true)
	
	# Back face
	extra_meshes[0].global_position += portal_entry.basis.z.normalized()*thickness/2
	extra_meshes[5].global_position += portal_entry.basis.z.normalized()*thickness/2
	# Right
	extra_meshes[1].global_position -= portal_entry.basis.x.normalized()*size_x/2 - portal_entry.basis.x.normalized()*0.01
	extra_meshes[1].rotate(extra_meshes[1].basis.y, deg_to_rad(-90))
	extra_meshes[1].get_mesh().size.x = thickness
	extra_meshes[6].global_position -= portal_entry.basis.x.normalized()*size_x/2 - portal_entry.basis.x.normalized()*0.01
	extra_meshes[6].rotate(extra_meshes[6].basis.y, deg_to_rad(-90))
	extra_meshes[6].get_mesh().size.x = thickness
	# Left
	extra_meshes[2].global_position += portal_entry.basis.x.normalized()*size_x/2 - portal_entry.basis.x.normalized()*0.01
	extra_meshes[2].rotate(extra_meshes[2].basis.y, deg_to_rad(90))
	extra_meshes[2].get_mesh().size.x = thickness
	extra_meshes[7].global_position += portal_entry.basis.x.normalized()*size_x/2 - portal_entry.basis.x.normalized()*0.01
	extra_meshes[7].rotate(extra_meshes[7].basis.y, deg_to_rad(90))
	extra_meshes[7].get_mesh().size.x = thickness
	# Top face
	extra_meshes[3].global_position += portal_entry.basis.y.normalized()*size_y/2 - portal_entry.basis.y.normalized()*0.01
	extra_meshes[3].rotate(extra_meshes[3].basis.x, deg_to_rad(-90))
	extra_meshes[3].get_mesh().size.y = thickness
	extra_meshes[8].global_position += portal_entry.basis.y.normalized()*size_y/2 - portal_entry.basis.y.normalized()*0.01
	extra_meshes[8].rotate(extra_meshes[8].basis.x, deg_to_rad(-90))
	extra_meshes[8].get_mesh().size.y = thickness
	# Bottom face
	extra_meshes[4].global_position -= portal_entry.basis.y.normalized()*size_y/2 - portal_entry.basis.y.normalized()*0.01
	extra_meshes[4].rotate(extra_meshes[4].basis.x, deg_to_rad(90))
	extra_meshes[4].get_mesh().size.y = thickness
	extra_meshes[9].global_position -= portal_entry.basis.y.normalized()*size_y/2 - portal_entry.basis.y.normalized()*0.01
	extra_meshes[9].rotate(extra_meshes[9].basis.x, deg_to_rad(90))
	extra_meshes[9].get_mesh().size.y = thickness
	
	# Set up hitbox
	hitboxArea = Area3D.new()
	portal_entry.add_child(hitboxArea)
	hitboxArea.global_transform = portal_entry.global_transform
	hitboxArea.global_position += portal_entry.basis.z*thickness/2
	var hitboxCollision: CollisionShape3D = CollisionShape3D.new()
	hitboxCollision.shape = BoxShape3D.new()
	hitboxCollision.shape.size = Vector3(portal_entry.get_mesh().size.x, portal_entry.get_mesh().size.y, 2)
	hitboxArea.add_child(hitboxCollision)
	hitboxArea.body_entered.connect(_on_entry_body_entered)
	hitboxArea.body_exited.connect(_on_entry_body_exited)
	portal_travellers = {}


var h_flag = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for body in portal_travellers.keys():
		if portal_travellers[body]>0 and side_of_portal(body)<=0:
			teleport(body)
			portal_travellers.erase(body)
			call_deferred("heads_up")
	call_deferred("adjust_camera")
	if h_flag:
		portal_subviewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE


func heads_up():
	other_portal.portal_subviewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	other_portal.h_flag = true


func adjust_camera() -> void:
	portal_entry.scale.z *= -1
	portal_entry.scale.x *= -1
	dummy_camera_entry.set_global_transform(player_camera.global_transform)
	portal_entry.scale.x *= -1
	portal_entry.scale.z *= -1
	dummy_camera_exit.set_transform(dummy_camera_entry.get_transform())
	portal_camera.set_global_transform(dummy_camera_exit.get_global_transform())
	var distance = player_camera.global_position - (portal_entry.global_position)
	if (-portal_entry.basis.z.dot(distance)) <= 0.05:
		portal_camera.use_oblique_frustum = false
	else:
		portal_camera.use_oblique_frustum = true


func teleport(body: Node3D) -> void:
	portal_entry.scale.z *= -1
	portal_entry.scale.x *= -1
	dummy_body_entry.set_global_transform(body.get_global_transform())
	portal_entry.scale.x *= -1
	portal_entry.scale.z *= -1
	dummy_body_exit.set_transform(dummy_body_entry.get_transform())
	body.set_global_transform(dummy_body_exit.get_global_transform())


func side_of_portal(body: Node3D) -> float:
	var distance = body.global_position - hitboxArea.global_position
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

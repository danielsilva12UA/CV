extends MeshInstance3D

const thickness = 5

var player_camera: Camera3D
var mirror_subviewport: SubViewport
var mirror_camera: Camera3D
var dummy_camera: Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Setup viewport
	mirror_subviewport = SubViewport.new()
	add_child(mirror_subviewport)
	mirror_subviewport.mesh_lod_threshold = 0
	mirror_subviewport.size = get_viewport().size
	get_tree().get_root().size_changed.connect(resize)
	
	# Setup camera
	player_camera = get_viewport().get_camera_3d()
	mirror_camera = Camera3D.new()
	mirror_subviewport.add_child(mirror_camera)
	mirror_camera.set_fov(player_camera.get_fov())
	mirror_camera.set_cull_mask_value(5, false)
	mirror_camera.use_oblique_frustum = true
	mirror_camera.set_oblique_normal(-global_transform.basis.z)
	mirror_camera.set_oblique_position(global_position)
	var world_3d: World3D = player_camera.get_world_3d()
	if world_3d:
		mirror_camera.environment = world_3d.environment.duplicate()
		mirror_camera.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	
	# Setup dummy
	dummy_camera = Node3D.new()
	add_child(dummy_camera)
	
	# Setup shader and material
	var shader: Shader = load("res://shaders/portal.gdshader")
	var mirror_material: ShaderMaterial = ShaderMaterial.new()
	mirror_material.shader = shader
	mirror_material.set_shader_parameter("tex", mirror_subviewport.get_texture())
	get_mesh().surface_set_material(0, mirror_material)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	call_deferred("adjust_camera")


func adjust_camera() -> void:
	scale.z *= -1
	dummy_camera.set_global_transform(player_camera.global_transform)
	scale.z *= -1
	mirror_camera.set_global_transform(dummy_camera.global_transform)

func resize() -> void:
	mirror_subviewport.size = get_viewport().size

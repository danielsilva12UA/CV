extends Node

var player_camera: Camera3D
var portal_camera: Camera3D
var dummy_camera_entry: Node3D
var dummy_camera_exit: Node3D
var dummy_body_entry: Node3D
var dummy_body_exit: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_camera = get_viewport().get_camera_3d()
	portal_camera = $SubViewport/Camera3D
	dummy_camera_entry = $Entry/DummyCamera
	dummy_camera_exit = $Exit/DummyCamera
	dummy_body_entry = $Entry/DummyBody
	dummy_body_exit = $Exit/DummyBody


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	dummy_camera_entry.set_global_transform(player_camera.get_global_transform())
	dummy_camera_exit.set_transform(dummy_camera_entry.get_transform())
	portal_camera.set_global_transform(dummy_camera_exit.get_global_transform())
	portal_camera.set_oblique_normal(-$Exit.global_transform.basis.z)
	portal_camera.set_oblique_position($Exit.global_position)


func _on_area_3d_body_entered(body: Node3D) -> void:
	dummy_body_entry.set_global_transform(body.get_global_transform())
	dummy_body_exit.set_transform(dummy_body_entry.get_transform())
	body.set_global_position(dummy_body_exit.get_global_position())
	body.set_global_rotation(dummy_body_exit.get_global_rotation())
	
	var body_dir = body.velocity.normalized()
	var right = $Entry.global_transform.basis.x.normalized()
	var angle_sign = 1.0
	if 0 < body_dir.dot(right):
		angle_sign = -1.0
	var backward = -$Entry.global_transform.basis.z.normalized()
	var velocity_angle = angle_sign * acos(body_dir.dot(backward))
	var exit_forward = $Exit.global_transform.basis.z.normalized()
	var exit_up = $Exit.global_transform.basis.y.normalized()
	body.set_velocity(exit_forward.rotated(exit_up, velocity_angle) * body.get_velocity().length())

extends Sprite3D

@onready var PlayerCamera = get_viewport().get_camera_3d()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position.x = PlayerCamera.global_position.x
	global_position.z = PlayerCamera.global_position.z

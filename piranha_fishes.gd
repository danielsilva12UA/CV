extends PathFollow3D

@onready var Fish : MeshInstance3D = $MeshInstance3D

func _process(delta: float) -> void:
	# Update progress along the path
	progress += 25.0 * delta

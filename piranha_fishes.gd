extends PathFollow3D

@onready var Fish : MeshInstance3D = $MeshInstance3D

# Amplitude and frequency for sine wave offsets
var vertical_amplitude = 0.01
var horizontal_amplitude = 0.2
var vertical_frequency = 0.125
var horizontal_frequency = 0.5

func _process(delta: float) -> void:
	# Update progress along the path
	progress += 12.5 * delta

	# Calculate vertical and horizontal offsets using sine functions
	v_offset = vertical_amplitude * sin(progress / 10)
	h_offset = horizontal_amplitude * sin(progress / 10)

	## Rotate the fish to mimic swimming
	#var rotation_amount = sin(vertical_frequency * progress) * 0.2 # Adjust factor for rotation effect
	#Fish.rotation.z = rotation_amount

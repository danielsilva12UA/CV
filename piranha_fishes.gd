extends PathFollow3D

@onready var Fish : MeshInstance3D = $MeshInstance3D

# Variables for controlling the sway
var sway_strength: float = 0.5  # How much the fish sways
var sway_speed: float = 1.5    # Speed of the sway
var previous_position: Vector3

func _ready() -> void:
	previous_position = global_transform.origin

func _process(delta: float) -> void:
	# Update progress along the path
	progress += 25.0 * delta
	
	# Get the current position
	var current_position = global_transform.origin
	
	# Calculate the direction of movement
	var direction = (current_position - previous_position).normalized()
	
	# Calculate the perpendicular direction to the path (side-to-side direction)
	var side_direction = direction.cross(Vector3.UP).normalized()
	
	# Calculate the sway offset (sinusoidal movement for smooth side-to-side effect)
	var sway_offset = side_direction * sway_strength * sin(sway_speed)
	
	# Apply the sway offset to the current position
	var final_position = current_position + sway_offset
	global_transform.origin = final_position
	
	# Update the fish's rotation to face the direction of movement
	if direction.length() > 0.01:
		Fish.look_at(current_position + direction, Vector3.UP)
	
	# Update the previous position for the next frame
	previous_position = current_position

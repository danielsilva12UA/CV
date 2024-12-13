extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 700

var mouse_captured = true
var input_mouse

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * SPEED
	if direction:
		velocity.x = direction.x
		velocity.z = direction.z
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _input(event):
	var rotation_angle = Vector3(0, 0, 0)
	if event is InputEventMouseMotion and mouse_captured:
		input_mouse = event.relative / MOUSE_SENSITIVITY
		rotation_angle.y -= event.relative.x / MOUSE_SENSITIVITY
		rotation_angle.x -= event.relative.y / MOUSE_SENSITIVITY
		# Handle rotations.
		global_rotation.y += rotation_angle.y
		if $Head.global_rotation.x + rotation_angle.x >= 90:
			$Head.global_rotation.x = 90
		elif $Head.global_rotation.x + rotation_angle.x <= -90:
			$Head.global_rotation.x = -90
		else:
			$Head.global_rotation.x += rotation_angle.x

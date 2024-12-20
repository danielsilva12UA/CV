extends CharacterBody3D


const SPEED = 15.0
const JUMP_VELOCITY = 15.0
const MOUSE_SENSITIVITY = 700

var mouse_captured = true
var input_mouse

var underwater = false

var animation

func _ready():
	animation = $Body/"character-male-d2"/AnimationPlayer
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Head/Camera3D/WaterVision.visible = false
	resize()
	get_tree().get_root().size_changed.connect(resize)
	get_world_3d().environment.volumetric_fog_density = 0.02

func _physics_process(delta: float) -> void:
	global_rotation.x = 0
	global_rotation.z = 0
	
	# Restart world.
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	
	# Capture mouse.
	if Input.is_action_just_pressed("mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true

	# Stop capturing mouse.
	if Input.is_action_just_pressed("mouse_capture_exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
	
	# Add the gravity.
	if not is_on_floor():
		if not underwater:
			velocity += get_gravity() * delta
		else:
			velocity += get_gravity() * delta/2
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_pressed("jump") and underwater:
		velocity.y = JUMP_VELOCITY/2

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
	
	if velocity.y > 0:
		animation.play("jump")
	elif velocity.y < 0:
		animation.play("fall")
	elif velocity.x!=0 or velocity.z!=0:
		animation.play("sprint")
	else:
		animation.stop()
	

func _input(event):
	var rotation_angle = Vector3(0, 0, 0)
	if event is InputEventMouseMotion and mouse_captured:
		input_mouse = event.relative / MOUSE_SENSITIVITY
		rotation_angle.y -= event.relative.x / MOUSE_SENSITIVITY
		rotation_angle.x -= event.relative.y / MOUSE_SENSITIVITY
		# Handle rotations.
		global_rotation.y += rotation_angle.y
		if $Head.global_rotation.x + rotation_angle.x >= deg_to_rad(90):
			$Head.global_rotation.x = deg_to_rad(90)
		elif $Head.global_rotation.x + rotation_angle.x <= deg_to_rad(-90):
			$Head.global_rotation.x = deg_to_rad(-90)
		else:
			$Head.global_rotation.x += rotation_angle.x
		$Head.global_rotation.z = 0
		$Head.global_rotation.y = global_rotation.y


func resize() -> void:
	$Head/Camera3D/WaterVision.scale.x = get_viewport().size.x / 1025.0
	$Head/Camera3D/WaterVision.scale.y = get_viewport().size.y / 1025.0


func _on_water_hitbox_body_entered(body: Node3D) -> void:
	if body != self:
		return
	underwater = true
	print("ENTERED WATER")
	$Head/Camera3D/WaterVision.visible = true
	get_world_3d().environment.volumetric_fog_enabled = 1


func _on_water_hitbox_body_exited(body: Node3D) -> void:
	if body != self:
		return
	underwater = false
	print("EXITED WATER")
	get_world_3d().environment.volumetric_fog_enabled = 0
	$Head/Camera3D/WaterVision.visible = false

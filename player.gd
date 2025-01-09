extends CharacterBody3D


const SPEED = 15.0
const JUMP_VELOCITY = 15.0
const MOUSE_SENSITIVITY = 700

static var currentCamera = 0
static var playerPhysics = true

var mouse_captured = true
var input_mouse

var underwater = false

var animation

@onready var PlayerCameraArm = $Head/CameraArm
@onready var PlayerCamera = $Head/CameraArm/Camera
@onready var PlayerCamera3D = $Head/CameraArm/Camera/Camera3D
@onready var audio_player = $Head/AudioStreamPlayer

func _ready():
	animation = $Body/"character-male-d2"/AnimationPlayer
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Head/CameraArm/Camera/Camera3D/WaterVision.visible = false
	resize()
	get_tree().get_root().size_changed.connect(resize)
	get_world_3d().environment.volumetric_fog_density = 0.02

func _process(delta: float) -> void:
	# Display instructions.
	if Input.is_action_just_pressed("help"):
		$Head/CameraArm/Camera/Camera3D/Help.visible = !$Head/CameraArm/Camera/Camera3D/Help.visible
		$Head/CameraArm/Camera/Camera3D/fps.visible = false
	
	# Display FPS.
	if Input.is_action_just_pressed("fps"):
		$Head/CameraArm/Camera/Camera3D/fps.visible = !$Head/CameraArm/Camera/Camera3D/fps.visible
		$Head/CameraArm/Camera/Camera3D/Help.visible = false
	
	$Head/CameraArm/Camera/Camera3D/fps.text = "FPS: " + str(1/delta)

func _physics_process(delta: float) -> void:
	if playerPhysics:
		global_rotation.x = 0
		global_rotation.z = 0
		
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
		var direction = ($Head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y))
		direction = Vector3(direction.x, 0, direction.z).normalized() * SPEED
		if direction:
			velocity.x = direction.x
			velocity.z = direction.z
			if currentCamera==1:
				var temp = $Head.global_rotation
				look_at(global_position + direction)
				$Head.global_rotation = temp
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
	if playerPhysics:
		var rotation_angle = Vector3(0, 0, 0)
		if event is InputEventMouseMotion and mouse_captured:
			input_mouse = event.relative / MOUSE_SENSITIVITY
			rotation_angle.y -= event.relative.x / MOUSE_SENSITIVITY
			rotation_angle.x -= event.relative.y / MOUSE_SENSITIVITY
			# Handle rotations.
			if currentCamera == 0:
				global_rotation.y += rotation_angle.y
				$Head.global_rotation.y = global_rotation.y
			else:
				$Head.global_rotation.y += rotation_angle.y
			$Head.global_rotation.x += rotation_angle.x
			if $Head.global_rotation.x >= deg_to_rad(80):
				$Head.global_rotation.x = deg_to_rad(80)
			elif $Head.global_rotation.x <= deg_to_rad(-60):
				$Head.global_rotation.x = deg_to_rad(-60)
			global_rotation.z = 0
			$Head.global_rotation.z = 0
			
		
		if event.is_action_pressed("change_view"):
			if playerPhysics:
				if currentCamera == 0:
					PlayerCameraArm.spring_length = 10
					PlayerCamera3D.set_cull_mask_value(2, true)
					PlayerCamera3D.set_fov(90)
					get_tree().call_group("portals", "set_fov", 90)
					currentCamera = 1
				elif currentCamera == 1:
					$Head.global_rotation.y = global_rotation.y
					PlayerCameraArm.spring_length = 0
					PlayerCamera3D.set_cull_mask_value(2, false)
					PlayerCamera3D.set_fov(75)
					get_tree().call_group("portals", "set_fov", 75)
					currentCamera = 0
			
	
func resize() -> void:
	$Head/CameraArm/Camera/Camera3D/WaterVision.scale.x = get_viewport().size.x / 1025.0
	$Head/CameraArm/Camera/Camera3D/WaterVision.scale.y = get_viewport().size.y / 1025.0


func _on_water_hitbox_body_entered(body: Node3D) -> void:
	if body == self:
		audio_player.stop()
		audio_player.play()
		underwater = true
		print("ENTERED WATER")

func _on_water_hitbox_body_exited(body: Node3D) -> void:
	if body == self:
		audio_player.stop()
		audio_player.seek(0.6)
		audio_player.play()
		underwater = false
		print("EXITED WATER")


func _on_water_hitbox_area_entered(area: Area3D) -> void:
	if area == $Head/CameraArm/Camera:
		$Head/CameraArm/Camera/Camera3D/WaterVision.visible = true
		get_world_3d().environment.volumetric_fog_enabled = true


func _on_water_hitbox_area_exited(area: Area3D) -> void:
	if area == $Head/CameraArm/Camera:
		$Head/CameraArm/Camera/Camera3D/WaterVision.visible = false
		get_world_3d().environment.volumetric_fog_enabled = false

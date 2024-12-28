extends StaticBody3D

@export var highlight_material: StandardMaterial3D

@onready var boat_meshinstance: MeshInstance3D = $Boat
@onready var boat_material: StandardMaterial3D = boat_meshinstance.mesh.surface_get_material(0)
@onready var Player = $"../Player"
@onready var BoatSeat: Node3D = $Boat/PlayerPosition
@onready var BoatExit: Node3D = $Boat/PlayerExit
@onready var PlayerCamera = $"../Player/Head/Camera3D"
@onready var BoatCamera: Camera3D = $Boat/BoatCamera
@onready var PlayerHead = $"../Player/Head"
@onready var Sail = $Boat/Sail

static var onBoat = false
var mouse_captured = true
var input_mouse

const MOUSE_SENSITIVITY = 2500
const MAX_SAIL_ANGLE = deg_to_rad(45)
const MAX_ANGULAR_VELOCITY = deg_to_rad(45)
const SPEED = 35.0
const TURN_SPEED = 3.5
const LINEAR_DRAG = 0.98
const MIN_SPEED = 5.0
const TURN_DECELERATION = 0.1
const STEERING_DRAG_MULTIPLIER = 1.5  # How much drag we apply when steering sharply
const WATER_RESISTANCE_FACTOR = 0.98  # Gradual reduction of speed when not steering harshly

var target_angular_velocity: float = 0.0
var velocity: Vector3 = Vector3.ZERO
var angular_velocity: float = 0.0
var last_steering_angle: float = 0.0  # Keep track of the previous steering angle to detect direction switch

var target_sail_angle: float = 0.0  # The target sail angle for smooth transition
var sail_angle_damping: float = 5.0  # The speed at which the sail angle smoothly transitions to the boat's rotation

func add_highlight() -> void:
	boat_meshinstance.set_surface_override_material(0, boat_material.duplicate())
	boat_meshinstance.get_surface_override_material(0).next_pass = highlight_material

func remove_highlight() -> void:
	boat_meshinstance.set_surface_override_material(0, null)

func move_player_into_boat() -> void:
	Player.global_transform.origin = BoatSeat.global_transform.origin
	Player.global_rotation = BoatSeat.global_rotation

func move_player_out_of_boat() -> void:
	Player.global_transform.origin = BoatExit.global_transform.origin

func adjust_camera_to_boat() -> void:
	BoatCamera.current = true

func adjust_camera_to_player() -> void:
	PlayerCamera.current = true

func _on_interactable_focused() -> void:
	add_highlight()

func _on_interactable_interacted() -> void:
	print("Interacted with the boat")
	if (onBoat):
		move_player_out_of_boat()
		adjust_camera_to_player()
		onBoat = false
		Player.playerPhysics = true
	else:
		move_player_into_boat()
		adjust_camera_to_boat()
		onBoat = true
		Player.playerPhysics = false

func _on_interactable_unfocused() -> void:
	remove_highlight()

func _input(event):
	if onBoat:
		# Handle mouse input for steering
		if event is InputEventMouseMotion and mouse_captured:
			var rotation_angle = 0
			var input_mouse = event.relative / MOUSE_SENSITIVITY
			rotation_angle -= event.relative.x / MOUSE_SENSITIVITY
			var new_sail_rotation = Sail.rotation.z + rotation_angle
			var boat_rotation_z = global_rotation.z
			var angle_difference = new_sail_rotation - boat_rotation_z
			var new_rotation_z = boat_rotation_z + angle_difference
			# Clamping the sail's rotation angle
			if new_rotation_z < deg_to_rad(-45):
				new_rotation_z = deg_to_rad(-45)
			elif new_rotation_z > deg_to_rad(45):
				new_rotation_z = deg_to_rad(45)
			# Apply the new rotation
			Sail.rotation.z = new_rotation_z
			# Update the target sail angle to the current rotation
			target_sail_angle = new_rotation_z

func _physics_process(delta: float) -> void:
	if onBoat:
		# Restart world
		if Input.is_action_just_pressed("restart"):
			onBoat = false
			Player.playerPhysics = true
			get_tree().reload_current_scene()

		# Capture mouse
		if Input.is_action_just_pressed("mouse_capture"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_captured = true

		# Stop capturing mouse
		if Input.is_action_just_pressed("mouse_capture_exit"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			mouse_captured = false

		# Get forward/backward input
		var forward_input: float = Input.get_action_strength("move_backwards") - Input.get_action_strength("move_forwards")

		# Calculate sail's influence on direction
		var sail_angle: float = -Sail.rotation.z
		var sail_direction = Vector3(sin(sail_angle), 0, cos(sail_angle)).normalized()

		# Correct boat's forward direction (negative Z is the back of the boat)
		var boat_forward = -global_transform.basis.z.normalized()

		# Align the sail direction to the boat's forward direction
		var alignment_factor = max(0.0, cos(sail_angle))  # This makes the boat slow down if the sail is misaligned
		var movement_direction = boat_forward.lerp(sail_direction, abs(sail_angle) / MAX_SAIL_ANGLE)

		# Calculate speed reduction when the sail is misaligned
		var speed_factor = alignment_factor

		# Apply forward input to the boat's velocity
		if forward_input != 0.0:
			var acceleration = movement_direction * SPEED * forward_input * speed_factor * delta
			velocity += acceleration

		# Apply linear drag to velocity to gradually slow the boat
		if velocity.length() > MIN_SPEED:
			velocity *= LINEAR_DRAG
		else:
			velocity = velocity.normalized() * MIN_SPEED  # Prevent the boat from decelerating too much

		# Steering drag: Increase drag when turning sharply
		var steering_angle = abs(Sail.rotation.z)
		var steering_drag = steering_angle / MAX_SAIL_ANGLE * STEERING_DRAG_MULTIPLIER
		velocity *= (1 - steering_drag * delta)

		# Apply water resistance factor over time to reduce the impact of sharp turns
		if steering_angle < deg_to_rad(10):
			velocity *= WATER_RESISTANCE_FACTOR

		# When the boat is moving, apply a symmetric change to the sail's rotation to align with the boat
		if forward_input != 0.0:
			var boat_rotation_z = global_rotation.z
			var rotation_difference = boat_rotation_z - Sail.rotation.z
			# Apply gradual correction to the sail angle, slower to avoid fast correction
			Sail.rotation.z = lerp(Sail.rotation.z, boat_rotation_z+Sail.rotation.z/2, sail_angle_damping * delta * 0.5)

		# Update last steering angle
		last_steering_angle = Sail.rotation.z

		# Calculate target angular velocity based on sail influence
		target_angular_velocity = (sail_angle / MAX_SAIL_ANGLE) * TURN_SPEED * forward_input

		# Smoothly interpolate angular velocity towards the target value with a damping effect
		angular_velocity = lerp(angular_velocity, target_angular_velocity, TURN_DECELERATION * delta)

		# Limit the angular velocity to avoid excessive turning speed
		angular_velocity = clamp(angular_velocity, -MAX_ANGULAR_VELOCITY, MAX_ANGULAR_VELOCITY)

		# Apply rotation to the boat
		rotate_y(angular_velocity * delta)

		# Apply velocity to the boat's position, allowing for residual forward motion
		#global_transform.origin += velocity * delta
		move_and_collide(velocity * delta)
		Player.global_position = BoatSeat.global_position
		Player.global_rotation = BoatSeat.global_rotation

		# Smooth transition of the sail angle to match the boat's orientation when not steering
		if forward_input == 0.0:
			# Apply damping to the sail angle to bring it smoothly to match the boat's heading
			Sail.rotation.z = lerp(Sail.rotation.z, global_rotation.z, sail_angle_damping * delta)

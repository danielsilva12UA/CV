extends StaticBody3D

@export var highlight_material: StandardMaterial3D

@onready var boat_meshinstance: MeshInstance3D = $Boat
@onready var boat_material: StandardMaterial3D = boat_meshinstance.mesh.surface_get_material(0)
@onready var Player = $"../Player"
@onready var BoatSeat: Node3D = $Boat/PlayerPosition  # The reference point on the boat
@onready var BoatExit: Node3D = $Boat/PlayerExit # The reference point out of the boat
@onready var PlayerCamera = $"../Player/Head/Camera3D"
@onready var BoatCamera: Camera3D = $Boat/BoatCamera
@onready var PlayerHead = $"../Player/Head"

static var onBoat = false
var mouse_captured = true
var input_mouse

const MAX_SAIL_ANGLE = deg_to_rad(45)  # Maximum sail angle in radians

const SPEED = 15.0
const JUMP_VELOCITY = 15.0
const MOUSE_SENSITIVITY = 1000

func add_highlight() -> void:
	boat_meshinstance.set_surface_override_material(0, boat_material.duplicate())
	boat_meshinstance.get_surface_override_material(0).next_pass = highlight_material

func remove_highlight() -> void:
	boat_meshinstance.set_surface_override_material(0, null)

func move_player_into_boat() -> void:
	# Requires to change animation for the player so it doesn't look weird
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
		var rotation_angle = 0
		if event is InputEventMouseMotion and mouse_captured:
			var input_mouse = event.relative / MOUSE_SENSITIVITY
			rotation_angle -= event.relative.x / MOUSE_SENSITIVITY
			# Compute new potential sail rotation
			var new_sail_rotation = $Sail.rotation.y + rotation_angle
			# Get the boat's current Y-axis global rotation
			var boat_rotation_y = global_rotation.y
			# Calculate the angle difference between the sail and the boat
			var angle_difference = new_sail_rotation - boat_rotation_y
			# Clamp the angle difference to [-45, 45]
			var new_rotation_y = boat_rotation_y + angle_difference
			if new_rotation_y < deg_to_rad(-45):
				new_rotation_y = deg_to_rad(-45)
			elif new_rotation_y > deg_to_rad(45):
				new_rotation_y = deg_to_rad(45)
			# Set the sail's rotation relative to the boat within the clamped range
			$Sail.rotation.y = new_rotation_y
			print(rad_to_deg(new_rotation_y))

func _physics_process(delta: float) -> void:
	if onBoat:
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
		# Get forward/backward input.
		var forward_input = Input.get_action_strength("move_forwards") - Input.get_action_strength("move_backwards")
		if forward_input != 0:
			# Calculate sail's influence on direction.
			var sail_angle = $Sail.rotation.y
			var sail_direction = Vector3(sin(sail_angle), 0, cos(sail_angle)).normalized()

			# Align sail direction with the boat's forward direction.
			var boat_forward = -global_transform.basis.z.normalized()
			var movement_direction = boat_forward.lerp(sail_direction, abs(sail_angle) / MAX_SAIL_ANGLE)

			# Move the boat.
			global_transform.origin += movement_direction * SPEED * forward_input * delta
			

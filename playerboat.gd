extends Node3D

@export var highlight_material: StandardMaterial3D

@onready var boat_meshinstance: MeshInstance3D = $Boat
@onready var boat_material: StandardMaterial3D = boat_meshinstance.mesh.surface_get_material(0)
@onready var Player = $"../Player"
@onready var BoatSeat: Node3D = $PlayerPosition  # The reference point on the boat
@onready var BoatExit: Node3D = $PlayerExit # The reference point out of the boat
@onready var PlayerCamera = $"../Player/Head/Camera3D"
@onready var BoatCamera: Camera3D = $BoatCamera
@onready var PlayerHead = $"../Player/Head"

static var onBoat = false

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

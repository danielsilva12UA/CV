extends Node3D

@export var highlight_material: StandardMaterial3D

@onready var boat_meshinstance: MeshInstance3D = $Boat
@onready var boat_material: StandardMaterial3D = boat_meshinstance.mesh.surface_get_material(0)

func add_highlight() -> void:
	boat_meshinstance.set_surface_override_material(0, boat_material.duplicate())
	boat_meshinstance.get_surface_override_material(0).next_pass = highlight_material

func remove_highlight() -> void:
	boat_meshinstance.set_surface_override_material(0, null)

func move_player_into_boat() -> void:
	pass

func adjust_camera_view() -> void:
	pass

func _on_interactable_focused() -> void:
	add_highlight()


func _on_interactable_interacted() -> void:
	print("Interacted with the boat")
	move_player_into_boat()
	adjust_camera_view()


func _on_interactable_unfocused() -> void:
	remove_highlight()

extends Node3D

@onready var animationplayer: AnimationPlayer = $AnimationPlayer
@onready var button_mesh: MeshInstance3D = $"button-floor-round-small/button-floor-round-small/button"
@onready var button_material : StandardMaterial3D = button_mesh.mesh.surface_get_material(0)
@onready var oldtimers_animator : AnimationPlayer = $"../Path3D/PathFollow3D/OldTimer/AnimationPlayer"
@onready var oldtimers : Node3D = $"../Path3D/PathFollow3D"

func add_highlight() -> void:
	button_mesh.set_surface_override_material(0, button_material.duplicate())

func remove_highlight() -> void:
	button_mesh.set_surface_override_material(0, null)

func _on_interactable_focused(interactor: Interactor) -> void:
	add_highlight()

func _on_interactable_interacted(interactor: Interactor) -> void:
	animationplayer.play("toggle-on")
	oldtimers.alive = false
	oldtimers_animator.play("die")
	

func _on_interactable_unfocused(interactor: Interactor) -> void:
	remove_highlight()

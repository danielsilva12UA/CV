extends Node3D

@onready var animationplayer: AnimationPlayer = $"button-floor-round-small/AnimationPlayer"
@onready var button_mesh: MeshInstance3D = $"button-floor-round-small/button-floor-round-small/button"
@onready var button_material : StandardMaterial3D = button_mesh.mesh.surface_get_material(0)
@onready var oldtimers_animator : AnimationPlayer = $"../Path3D/PathFollow3D/OldTimer/AnimationPlayer"
@onready var oldtimers : Node3D = $"../Path3D/PathFollow3D"
@onready var button_position : Vector3 = button_mesh.global_transform.origin
@onready var oldtimers_parent : Path3D = $"../Path3D"
@onready var moon: Sprite3D = $"../../Moon"

var pressed = false

func add_highlight() -> void:
	button_mesh.set_surface_override_material(0, button_material.duplicate())

func remove_highlight() -> void:
	button_mesh.set_surface_override_material(0, null)

func _on_interactable_focused() -> void:
	add_highlight()

func _on_interactable_interacted() -> void:
	if not pressed:
		animationplayer.play("toggle-on")
		pressed = true
	
		for oldtimer in oldtimers_parent.get_children():
			if oldtimer is Node3D:  # Ensure we are handling Node3D instances
				oldtimer.alive = false
				oldtimer.get_node("OldTimer/AnimationPlayer").speed_scale = 0.5
				oldtimer.get_node("OldTimer/AnimationPlayer").play("die")
				
				# Rotate oldtimer towards the button while preserving scale
				var direction_to_button = (button_position - oldtimer.global_transform.origin).normalized()
				var transform = oldtimer.transform
				var scale = transform.basis.get_scale()  # Get the original scale
				transform.basis = Basis().looking_at(direction_to_button, Vector3.UP).scaled(scale)  # Reapply the scale
				oldtimer.transform = transform
		
		get_world_3d().environment.sky = null
		moon.visible = true

func _on_interactable_unfocused() -> void:
	remove_highlight()

extends Node3D

@onready var animationplayer: AnimationPlayer = $"button-floor-round-small/AnimationPlayer"
@onready var button_mesh: MeshInstance3D = $"button-floor-round-small/button-floor-round-small/button"
@onready var button_material: StandardMaterial3D = button_mesh.mesh.surface_get_material(0)
@onready var oldtimers_parent: Path3D = $"../Path3D"
@onready var moon: Sprite3D = $"../../Moon"
@onready var light: DirectionalLight3D = $"../../DirectionalLight3D"
@onready var main_audio: AudioStreamPlayer = $"../../AudioStreamPlayer"

var pressed = false
var button_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	button_position = button_mesh.global_transform.origin

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
		main_audio.blood_moon = true
		trigger_blood_moon_event()

func trigger_blood_moon_event() -> void:
	# Create a SceneTreeTween
	var tween = create_tween()

	# Handle OldTimers
	for oldtimer in oldtimers_parent.get_children():
		if oldtimer is Node3D:
			oldtimer.alive = false
			if oldtimer.has_node("OldTimer/AnimationPlayer"):
				var animator = oldtimer.get_node("OldTimer/AnimationPlayer")
				animator.speed_scale = 0.5
				animator.play("die")
			
			# Rotate oldtimer towards the button gradually
			var direction_to_button = (button_position - oldtimer.global_transform.origin).normalized()
			var oldtimer_transform = oldtimer.transform
			var scale = oldtimer_transform.basis.get_scale()
			var target_basis = Basis().looking_at(direction_to_button, Vector3.UP).scaled(scale)
			tween.tween_property(oldtimer, "transform:basis", target_basis, 2.0)

	# Update the environment after the tween finishes
	tween.finished.connect(self.on_blood_moon_complete)

func on_blood_moon_complete() -> void:
	var tween = create_tween()
	
	# Gradually change the light to red (for the blood moon effect)
	tween.tween_property(light, "light_color", Color("red"), 5.0)
	
	tween.set_parallel()
	# Gradually make the moon visible and fade in alpha
	tween.tween_property(moon, "modulate:a", 1.0, 25.0)
	
	# Set sky to null after fading
	get_world_3d().environment.sky = null
	get_tree().call_group("portals", "update_environment")


func _on_interactable_unfocused() -> void:
	remove_highlight()

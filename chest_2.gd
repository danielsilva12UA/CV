extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer



var is_open: bool = false

# Called when the node enters the scene tree for the first time.
func open() -> void:
	is_open = true
	animation_player.play("OpenChest")

func close() -> void:
	is_open = false
	animation_player.play("CloseChest")

func _on_interactable_focused() -> void:
	pass # Replace with function body.


func _on_interactable_interacted() -> void:
	print("Interated with chest")
	if not is_open:
		print("Opening")
		$Interactable.queue_free()
		open()
	elif is_open:
		print("Closed")
		$Interactable.queue_free()
		close()

func _on_interactable_unfocused() -> void:
	pass # Replace with function body.

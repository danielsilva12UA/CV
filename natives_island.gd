extends Area3D

@onready var main_audio_player = $".."  # This will reference the parent node (AudioStreamPlayer)

# Flag to track if the song is already playing to prevent multiple triggers
var is_playing = false

# This function is triggered when a body enters the area
func _on_body_entered(body: Node3D) -> void:
	if body is not CharacterBody3D:
		return
	if not is_playing:  # Only change song if it's not already playing
		is_playing = true
		main_audio_player.bgm_player("natives_song")  # Play the "natives_song" when entered

# This function is triggered when a body exits the area
func _on_body_exited(body: Node3D) -> void:
	if body is not CharacterBody3D:
		return
	if is_playing:  # Only switch to default song if it was playing
		is_playing = false
		main_audio_player.bgm_player("default_song")  # Switch to "default_song" when exited

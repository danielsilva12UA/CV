extends AudioStreamPlayer

@export var natives_song: AudioStream
@export var default_song: AudioStream
@export var inhouse_song: AudioStream

@export var natives_song2: AudioStream
@export var default_song2: AudioStream
@export var inhouse_song2: AudioStream

var fade_duration: float = 1.0  # Duration of the fade effect in seconds
var blood_moon = false

# Function to handle the music transition with fade in/out
func bgm_player(song: String):
	if song == "natives_song" and stream != natives_song:
		fade_music_out()  # Fade out current song
		stream = natives_song2 if blood_moon else natives_song
		fade_music_in()   # Fade in the new song
	elif song == "inhouse_song" and stream != inhouse_song:
		fade_music_out()
		stream = inhouse_song2 if blood_moon else inhouse_song
		fade_music_in()
	elif song != "natives_song" and song != "inhouse_song" and stream != default_song:
		fade_music_out()
		stream = default_song2 if blood_moon else inhouse_song
		fade_music_in()

# Function to fade out the current music gradually
func fade_music_out():
	var fade_timer = Timer.new()  # Create a timer
	add_child(fade_timer)  # Add timer to the node tree
	fade_timer.wait_time = fade_duration / 2  # Set fade-out duration
	fade_timer.one_shot = true
	fade_timer.start()  # Start the fade-out timer
	
	fade_timer.connect("timeout", Callable(self, "_on_fade_out_timer_timeout"))

# Function to fade in the new music gradually
func fade_music_in():
	volume_db = -40  # Start at very low volume
	var fade_in_timer = Timer.new()  # Create a fade-in timer
	add_child(fade_in_timer)  # Add the timer to the node tree
	fade_in_timer.wait_time = fade_duration / 2  # Set fade-in duration
	fade_in_timer.one_shot = true
	fade_in_timer.start()  # Start the fade-in timer
	
	fade_in_timer.connect("timeout", Callable(self, "_on_fade_in_timer_timeout"))

# Callback when the fade-out timer finishes
func _on_fade_out_timer_timeout():
	stop()  # Stop the current song after fading out

# Callback when the fade-in timer finishes
func _on_fade_in_timer_timeout():
	play()  # Start playing the new song
	var fade_volume_timer = Timer.new()  # Timer to gradually increase the volume
	add_child(fade_volume_timer)
	fade_volume_timer.wait_time = fade_duration / 2  # Set fade-in volume duration
	fade_volume_timer.one_shot = true
	fade_volume_timer.start()
	fade_volume_timer.connect("timeout", Callable(self, "_on_fade_volume_timer_timeout"))

# Gradually increase the volume using await
func _on_fade_volume_timer_timeout():
	var target_volume_db = -25.0  # Full volume (in dB)
	
	# Gradually increase the volume to full
	while volume_db < target_volume_db:
		volume_db += 1  # Gradually increase the volume
		await get_tree().create_timer(0.1).timeout

# Callback to gradually decrease the volume during the fade-out phase
func _on_fade_out_volume_timer_timeout():
	var target_volume_db = -40.0  # Minimum volume (in dB)
	
	# Gradually decrease the volume to low during the fade-out
	while volume_db > target_volume_db:
		volume_db -= 1  # Gradually decrease the volume
		await get_tree().create_timer(0.1).timeout

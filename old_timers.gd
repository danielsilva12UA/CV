extends Path3D

var num_dwarves = 5 # Number of fish

func _ready():
	for i in range(num_dwarves):
		var old_timer = preload("res://old_timers_running.tscn").instantiate()
		add_child(old_timer)
		
		# Randomize initial progress for each fish
		old_timer.progress_ratio = float(i) / num_dwarves 

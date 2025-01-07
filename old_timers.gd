extends Path3D

var num_dwarves = 5

func _ready():
	for i in range(1, num_dwarves):
		var old_timer = preload("res://old_timers_running.tscn").instantiate()
		add_child(old_timer)
		
		old_timer.progress_ratio = float(i) / num_dwarves 

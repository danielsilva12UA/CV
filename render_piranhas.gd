extends Path3D

var num_fish = 25 # Number of fish

func _ready():
	for i in range(num_fish):
		var fish_instance = preload("res://piranha_on_path.tscn").instantiate()
		add_child(fish_instance)
		
		# Randomize initial progress for each fish
		fish_instance.progress_ratio = float(i) / num_fish 

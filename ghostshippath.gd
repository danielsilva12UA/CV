extends PathFollow3D

var moving = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if moving:
		progress += 7.5 * delta

func start_moving():
	moving = true

func make_visible():
	self.visible = true

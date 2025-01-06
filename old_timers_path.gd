extends PathFollow3D

@onready var OldTimerAnimator = $OldTimer/AnimationPlayer

static var iterations_without_pickup : int = 0
var is_picking_up = false
var pick_up_duration : float = 0.3333  # Duration for pick-up animation
var pick_up_timer : float = 0.0  # Timer to track the duration of the pick-up

var alive = true

func _process(delta: float) -> void:
	if alive:
		# If not picking up, update progress along the path
		if not is_picking_up:
			OldTimerAnimator.play("walk")
			progress += 3 * delta
			iterations_without_pickup += 1
			# Trigger pick-up after 5 iterations
			if iterations_without_pickup >= 500:
				is_picking_up = true
				pick_up_timer = 0.0  # Reset pick-up timer
				OldTimerAnimator.play("pick-up")
		else:
			# Handle the pick-up animation duration
			pick_up_timer += delta
			if pick_up_timer >= pick_up_duration:
				# Reset the pick-up flag and continue walking after the animation
				is_picking_up = false
				iterations_without_pickup = 0  # Reset the pick-up counter after the pick-up action
				OldTimerAnimator.play("walk")

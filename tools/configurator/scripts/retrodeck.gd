extends Sprite2D

@export var rotation_speed: float = 45.0
@export var speed = 400
const SCALE_MIN = 0.01
const SCALE_MAX = 0.35
const SCALE_SPEED = 0.5
var scale_direction = 1.0

func _process(delta) -> void:
	# Rotate the sprite
	rotation_degrees += rotation_speed * delta
	var new_scale = scale + Vector2(scale_direction, scale_direction) * SCALE_SPEED * delta
	if new_scale.x < SCALE_MIN or new_scale.x > SCALE_MAX:
		scale_direction *= -1  # Reverse direction if scale limit is reached
	else:
		scale = new_scale

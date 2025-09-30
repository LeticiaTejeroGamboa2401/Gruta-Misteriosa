extends CharacterBody2D

# Propiedades expuestas para que otros scripts (por ejemplo pelea_final.gd)
# puedan asignarles valores sin error.
@export var speed: float = 200.0
var target_position_x: float = 0.0

func _physics_process(_delta: float) -> void:
	# Si no hay objetivo, detenerse
	if target_position_x == 0:
		velocity.x = 0
		move_and_slide()
		return

	var diff: float = target_position_x - global_position.x
	if abs(diff) > 1.0:
		var dir: float = sign(diff)
		velocity.x = dir * speed
	else:
		velocity.x = 0

	move_and_slide()

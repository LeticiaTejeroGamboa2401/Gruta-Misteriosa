extends CharacterBody2D

@export var speed: float = 100.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
		sprite.play("Derecha")
	elif Input.is_action_pressed("ui_left"):
		direction.x -= 1
		sprite.play("Izquierda")
	else:
		sprite.stop()  # Detiene la animación cuando no hay movimiento

	if direction != Vector2.ZERO:
		direction = direction.normalized() * speed
		velocity = direction
	else:
		velocity = Vector2.ZERO

	move_and_slide()

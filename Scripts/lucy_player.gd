extends CharacterBody2D

@export var speed: float = 100.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta):
	var direction = Vector2.ZERO
	
	# Movimiento horizontal
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	elif Input.is_action_pressed("ui_left"):
		direction.x -= 1

	# Movimiento vertical
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	elif Input.is_action_pressed("ui_up"):
		direction.y -= 1

	# Animaciones básicas (puedes expandirlas con más direcciones)
	if direction.x > 0:
		sprite.play("Derecha")
	elif direction.x < 0:
		sprite.play("Izquierda")
	elif direction.y > 0:
		sprite.play("Abajo")  # Asegúrate de tener esta animación
	elif direction.y < 0:
		sprite.play("Arriba")  # Asegúrate de tener esta animación
	else:
		sprite.stop()

	# Movimiento
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

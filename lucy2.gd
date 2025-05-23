extends CharacterBody2D

@export var speed: float = 100.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	handle_input()
	move_and_slide()
	update_animation()

func handle_input() -> void:
	velocity = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1

	velocity = velocity.normalized() * speed

func update_animation() -> void:
	if velocity.x > 0:
		sprite.play("derecha")
	elif velocity.x < 0:
		sprite.play("izquierda")
	elif velocity.y < 0:
		sprite.play("arriba")
	elif velocity.y > 0:
		sprite.play("abajo")
	else:
		sprite.stop()  # opcional, para detener la animación si no se mueve

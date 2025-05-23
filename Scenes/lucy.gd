extends CharacterBody2D

@export var speed: float = 230.0
@export var change_scene_x: float = 1050.0  # <-- Cambia este valor según tu nivel
@export var next_scene: String = "res://Scenes/EntradaCueva.tscn"  # <-- Pon la ruta de la siguiente escena

const GRAVITY: float = 980.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var scene_changed := false  # Evita cambiar múltiples veces de escena

func _physics_process(delta: float) -> void:
	handle_input()
	apply_gravity(delta)
	move_and_slide()
	update_animation()

	check_for_scene_change()

func handle_input() -> void:
	velocity.x = 0

	if Input.is_action_pressed("ui_right"):
		velocity.x += speed
	elif Input.is_action_pressed("ui_left"):
		velocity.x -= speed

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

func update_animation() -> void:
	if velocity.x > 0:
		sprite.play("derecha")
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.play("izquierda")
		sprite.flip_h = true

func check_for_scene_change() -> void:
	if not scene_changed and global_position.x >= change_scene_x:
		scene_changed = true
		print("Lucy llegó al borde derecho, cambiando de escena...")
		get_tree().change_scene_to_file(next_scene)

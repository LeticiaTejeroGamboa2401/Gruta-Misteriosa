extends CharacterBody2D

const GRAVITY = 500
var speed = 245
var target_position_x = 900

func _ready():
	print("Nahual listo")  # Verifica que el script se ejecuta

func _physics_process(delta: float) -> void:
	apply_gravity(delta)

	if global_position.x < target_position_x:
		velocity.x = speed
	else:
		velocity.x = 0

	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

func _on_area_2d_body_entered(body: Node) -> void:
	print("Entró un cuerpo:", body.name)
	if body.name == "Lucy_Player" or body.name == "Lele_Player":
		print("¡El nahual atrap{o al jugador}!")
		show_game_over()

func show_game_over() -> void:
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

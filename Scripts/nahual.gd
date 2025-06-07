extends CharacterBody2D

const GRAVITY = 500
var speed = 245
var target_position_x = 900
var was_hit := false  # Para evitar múltiples impactos seguidos

func _ready():
	print("Nahual listo")

func _physics_process(_delta: float) -> void:
	apply_gravity(_delta)

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
	if was_hit:
		return

	if body.name == "Lucy_Player" or body.name == "Lele_Player":
		print("¡El nahual atrapó al jugador!")

		var root = get_tree().get_current_scene()
		if root.has_method("on_player_hit"):
			root.call("on_player_hit")

		was_hit = true
		await get_tree().create_timer(0.5).timeout  # Tiempo de invulnerabilidad del jugador
		was_hit = false

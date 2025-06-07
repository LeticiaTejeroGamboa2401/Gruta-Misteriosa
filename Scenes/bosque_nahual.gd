extends Node2D

const GRAVITY: float = 980.0

@onready var sprite: AnimatedSprite2D = $nahual/AnimatedSprite2D

var scene_changed := false
var recently_hit := false
var player_instance

func _ready() -> void:
	MusicManager.play_music("res://audio/persecución1.ogg")
	update_hearts()

	if Global.selected_character_scene != null:
		player_instance = Global.selected_character_scene.instantiate()
		player_instance.name = Global.selected_character_name
		add_child(player_instance)
		player_instance.position = Vector2(400, 520)
		player_instance.speed = 200  # Velocidad personalizada
	else:
		print("No se ha seleccionado personaje.")

func update_hearts():
	$Panel/Heart1.visible = Global.lives >= 1
	$Panel/Heart2.visible = Global.lives >= 2
	$Panel/Heart3.visible = Global.lives >= 3

func on_player_hit():
	if recently_hit or scene_changed:
		return

	recently_hit = true
	Global.lives -= 1
	print("Vidas restantes: ", Global.lives)
	update_hearts()

	if Global.lives <= 0:
		print("¡Sin vidas! Ir a Game Over")
		scene_changed = true
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
	else:
		print("Reiniciando la escena actual...")
		scene_changed = true
		await get_tree().create_timer(0.5).timeout
		var current_scene = get_tree().current_scene.scene_file_path
		get_tree().change_scene_to_file(current_scene)

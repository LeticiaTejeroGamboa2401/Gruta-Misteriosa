extends Node2D

const GRAVITY: float = 980.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var scene_changed := false
var player_instance

func _ready() -> void:
	MusicManager.play_music("res://audio/historia.ogg")
	
	if Global.selected_character_scene != null:
		player_instance = Global.selected_character_scene.instantiate()
		player_instance.name = Global.selected_character_name
		add_child(player_instance)
		player_instance.position = Vector2(400, 520)

		# 👇 Aquí le aumentas la velocidad solo para esta escena
		player_instance.speed = 200  # Ajusta a la velocidad que desees
	else:
		print("No se ha seleccionado personaje.")

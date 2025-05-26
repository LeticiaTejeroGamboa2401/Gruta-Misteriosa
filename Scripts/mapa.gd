extends Node2D


func _ready() -> void:
	if Global.selected_character_scene != null:
		var player_instance = Global.selected_character_scene.instantiate()
		player_instance.name = Global.selected_character_name
		add_child(player_instance)
		player_instance.position = Vector2(98,250)
		player_instance.scale = Vector2(0.4, 0.4)
	else:
		print("No se ha seleccionado personaje.")

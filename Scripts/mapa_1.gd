extends Control


func _ready() -> void:
	MusicManager.play_music("res://audio/mapa.ogg")

	if Global.selected_character_scene != null:
		var player_instance = Global.selected_character_scene.instantiate()
		player_instance.name = Global.selected_character_name
		add_child(player_instance)
		player_instance.scale = Vector2(0.4, 0.4)

		if get_scene_file_path() == Global.use_respawn_in_scene:
			player_instance.position = Global.respawn_position
		else:
			player_instance.position = Vector2(100, 250)  # posición por defecto
	else:
		print("No se ha seleccionado personaje.")

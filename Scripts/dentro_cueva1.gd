extends Control


func _ready() -> void:
	if Global.selected_character_scene != null:
		var player_instance = Global.selected_character_scene.instantiate()
		player_instance.name = Global.selected_character_name
		add_child(player_instance)
		player_instance.position = Vector2(15,520)
	else:
		print("No se ha seleccionado personaje.")

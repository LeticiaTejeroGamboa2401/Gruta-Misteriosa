extends Control


func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Juegos/Carrera_de_Caballos/Explicacion_Juego.tscn")


func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/mapa.tscn")

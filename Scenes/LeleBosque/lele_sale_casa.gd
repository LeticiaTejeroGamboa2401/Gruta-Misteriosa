extends Control

func _on_omitir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/mapa.tscn")


func _on_siguiente_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Bosque.tscn")

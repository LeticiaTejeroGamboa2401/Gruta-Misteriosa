extends Control

func _on_siguiente_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Juegos/Ruleta/ruleta.tscn")
